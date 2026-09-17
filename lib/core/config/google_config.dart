/// "Sign in with Google" configuration.
///
/// The app requests an ID token whose audience is the **web** OAuth client id, the same value the
/// backend verifies (`GOOGLE_OAUTH_CLIENT_ID`) and the web frontend uses (`VITE_GOOGLE_CLIENT_ID`).
/// Android additionally needs an Android OAuth client (package name + SHA-1) in the same Google
/// project; iOS needs `GIDClientID` and the reversed-client-id URL scheme in Info.plist.
///
/// Build with:
///   flutter build apk --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
class GoogleConfig {
  GoogleConfig._();

  static const String webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static bool get isConfigured => webClientId.isNotEmpty;
}
