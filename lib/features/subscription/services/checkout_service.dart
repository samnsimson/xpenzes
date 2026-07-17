import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../constants/subscription_constants.dart';

enum CheckoutOutcome { success, cancelled }

/// Custom URL scheme the web checkout's success page redirects back to
/// (see xpenzes-web's app/upgrade/success page) once Stripe confirms
/// payment. Must match the `xpenzes` scheme registered in
/// android/app/src/main/AndroidManifest.xml — no iOS registration is
/// needed, since ASWebAuthenticationSession intercepts navigation to it
/// itself without an Info.plist entry.
const _callbackUrlScheme = 'xpenzes';

/// Drives the whole Stripe checkout hand-off: mints a short-lived token
/// from xpenzes-svc (identifies the paying user without putting a JWT in
/// the URL — see `POST /checkout/handoff`), opens the web checkout page
/// in an ephemeral in-app browser, and waits for it to redirect back to
/// [_callbackUrlScheme]. That only happens after a successful payment,
/// at which point the browser dismisses itself automatically. Closing
/// the browser without paying (or Stripe's own cancel link, which lands
/// back on the same web page rather than redirecting) surfaces as
/// [CheckoutOutcome.cancelled] instead of throwing.
class CheckoutService {
  Future<CheckoutOutcome> startCheckout(SubscriptionPlan plan) async {
    final response = await apiClient.post('/checkout/handoff');
    final token = (response as Map<String, dynamic>)['token'] as String;
    final checkoutUrl = Uri.parse(
      '${Env.webBaseUrl}/upgrade',
    ).replace(queryParameters: {'token': token, 'plan': plan.name});

    try {
      await FlutterWebAuth2.authenticate(
        url: checkoutUrl.toString(),
        callbackUrlScheme: _callbackUrlScheme,
      );
      return CheckoutOutcome.success;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        return CheckoutOutcome.cancelled;
      }
      rethrow;
    }
  }
}

final checkoutService = CheckoutService();
