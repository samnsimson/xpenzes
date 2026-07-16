import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../core/network/api_client.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

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

  /// Sends a one-time login code to [email]. Works for both new and
  /// returning users — Supabase creates the account on first use.
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
      return e.toString();
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
      state = AsyncData(await _fetchProfile());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateProfile({String? name, String? currency}) async {
    final json = await apiClient.patch(
      '/users/me',
      body: {
        if (name != null) 'name': name,
        if (currency != null) 'currency': currency,
      },
    ) as Map<String, dynamic>;
    state = AsyncData(UserModel.fromJson(json));
  }

  Future<void> completeOnboarding() async {
    final json =
        await apiClient.post('/users/me/onboarding/complete') as Map<String, dynamic>;
    state = AsyncData(UserModel.fromJson(json));
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncData(null);
  }
}
