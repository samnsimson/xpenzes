/// Compile-time configuration, overridable via --dart-define.
///
/// The Supabase URL/anon key are safe to ship in the client (that's what
/// the anon key is for — it identifies the project, not a secret credential;
/// real authorization happens via user JWTs and the backend's own checks).
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kkntkokklngbagbctqyk.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_H6saAmoqdoNlkDU9sISQSA_SqVbGqYS',
  );

  /// Points at a local xpenzes-svc by default; pass
  /// --dart-define=API_BASE_URL=https://... for staging/prod.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Where the in-app browser is sent for Stripe checkout (see
  /// features/subscription). Points at a local xpenzes-web by default,
  /// matching [apiBaseUrl]; pass
  /// --dart-define=WEB_BASE_URL=https://xpenzes.app for staging/prod.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
