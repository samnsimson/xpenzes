import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

/// The current user's currency symbol (e.g. `$`, `€`), falling back to
/// USD before sign-in or if the stored currency code is unrecognized.
final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(authProvider).value?.currency ?? 'USD';
  return AppConstants.currencies[currency] ?? '\$';
});

enum _OtpProbeOutcome { existingUser, newUser, error }

/// Result of [AuthNotifier.probeEmail].
class OtpProbeResult {
  final _OtpProbeOutcome _outcome;
  final String? errorMessage;

  const OtpProbeResult.existingUser()
    : _outcome = _OtpProbeOutcome.existingUser,
      errorMessage = null;
  const OtpProbeResult.newUser()
    : _outcome = _OtpProbeOutcome.newUser,
      errorMessage = null;
  const OtpProbeResult.error(this.errorMessage)
    : _outcome = _OtpProbeOutcome.error;

  bool get isExistingUser => _outcome == _OtpProbeOutcome.existingUser;
  bool get isNewUser => _outcome == _OtpProbeOutcome.newUser;
  bool get isError => _outcome == _OtpProbeOutcome.error;
}

/// Turns a raw Supabase auth error into copy a user should see.
///
/// [AuthRetryableFetchException] (thrown for any 5xx from Supabase) is
/// the awkward case: its `message` is the *unparsed* response body —
/// e.g. `{"code":"unexpected_failure","message":"Error sending
/// confirmation email"}` — because gotrue only parses 4xx bodies into a
/// proper `code`/`message` pair. That happens when Supabase's own mail
/// service fails to dispatch (commonly: the default built-in email
/// service's rate limit, meant for testing only — see
/// xpenzes-svc/docs/PROJECT.md's OTP verification gap), so we special-case
/// it rather than showing the raw JSON.
String _friendlyAuthError(Object error) {
  if (error is AuthRetryableFetchException) {
    if (error.message.toLowerCase().contains('email')) {
      return "We couldn't send you a code right now. Please try again in a few minutes.";
    }
    return 'Something went wrong on our end. Please try again in a moment.';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return "You've requested a few too many codes. Please wait a bit before trying again.";
      case 'otp_expired':
        return 'That code has expired. Request a new one and try again.';
    }
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    if (Supabase.instance.client.auth.currentSession == null) return null;
    return _fetchProfile();
  }

  Future<UserModel> _fetchProfile() async {
    final json = await apiClient.get('/users/me') as Map<String, dynamic>;
    return UserModel.fromJson(json);
  }

  /// First step of sign-in: checks whether [email] already has an
  /// account, without asking for a name up front.
  ///
  /// Sends the OTP with `shouldCreateUser: false`. Supabase's response
  /// tells us which branch we're on:
  /// - Succeeds -> the account exists, the code is already on its way,
  ///   so the caller can skip straight to the code step.
  /// - Fails with the `otp_disabled` error code -> no account with this
  ///   email; the caller should collect a name and call [sendOtp] to
  ///   actually send the code (which also creates the account).
  /// - Any other failure is a real error (bad email, rate limit, etc).
  Future<OtpProbeResult> probeEmail(String email) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return const OtpProbeResult.existingUser();
    } on AuthException catch (e) {
      if (e.code == 'otp_disabled') {
        return const OtpProbeResult.newUser();
      }
      return OtpProbeResult.error(_friendlyAuthError(e));
    } catch (e) {
      return OtpProbeResult.error(_friendlyAuthError(e));
    }
  }

  /// Sends a one-time login code to [email], creating the account with
  /// [name] if it doesn't exist yet. Used for the code step directly
  /// after [probeEmail] finds an existing account (no [name]), and for
  /// new accounts once the user has entered their name.
  ///
  /// Deliberately does not touch `state`: no session exists yet, and
  /// `state` drives top-level app routing (splash vs. auth vs. app) —
  /// flipping it to loading here would unmount AuthScreen mid-flow and
  /// lose which step the user is on. Returns an error message, or null
  /// on success.
  Future<String?> sendOtp(String email, {String? name}) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        data: name != null && name.isNotEmpty ? {'name': name} : null,
      );
      return null;
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  /// Verifies the code. Like [sendOtp], avoids touching `state` on
  /// failure (a wrong code shouldn't unmount AuthScreen and bounce the
  /// user back to the email step) — only a real success updates it,
  /// which is also the only case where leaving AuthScreen is correct.
  Future<String?> verifyOtp(String email, String code) async {
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: code,
      );
    } catch (e) {
      return _friendlyAuthError(e);
    }
    // The code was accepted and a Supabase session now exists — from
    // here any failure is xpenzes-svc being unreachable, not the OTP,
    // so it gets a distinct message rather than the generic auth-error
    // fallback (which would wrongly suggest the code itself was bad).
    try {
      state = AsyncData(await _fetchProfile());
      return null;
    } catch (_) {
      return "Signed in, but couldn't reach the server to load your profile. Check your connection and try again.";
    }
  }

  /// Refreshes the profile after a successful checkout, retrying for a
  /// bit if the plan hasn't flipped to `pro` yet.
  ///
  /// The Stripe webhook that actually updates `subscription_plan` (see
  /// xpenzes-svc's BillingService) runs async, off Stripe's own event
  /// delivery — it can lag a second or two behind the app regaining
  /// control from the checkout browser. Polling here bridges that gap so
  /// the app reliably shows Pro immediately instead of racing it.
  Future<void> refreshUntilPro({
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(seconds: 1),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final profile = await _fetchProfile();
      state = AsyncData(profile);
      if (profile.isPro || DateTime.now().isAfter(deadline)) {
        return;
      }
      await Future.delayed(interval);
    }
  }

  Future<void> updateProfile({String? name, String? currency}) async {
    final json =
        await apiClient.patch(
              '/users/me',
              body: {'name': ?name, 'currency': ?currency},
            )
            as Map<String, dynamic>;
    state = AsyncData(UserModel.fromJson(json));
  }

  Future<void> completeOnboarding() async {
    final json =
        await apiClient.post('/users/me/onboarding/complete')
            as Map<String, dynamic>;
    state = AsyncData(UserModel.fromJson(json));
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncData(null);
  }
}
