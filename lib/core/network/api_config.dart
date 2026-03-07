/// API base URL and origin from compile-time env (--dart-define).
/// Use for release builds so the app talks to your Droplet backend instead of localhost.
///
/// Build with Droplet:
///   flutter build apk --dart-define=API_BASE_URL=http://YOUR_DROPLET_IP:8080/api/v1
///   flutter build appbundle --dart-define=API_BASE_URL=http://YOUR_DROPLET_IP:8080/api/v1
///
/// For HTTPS on Droplet (if you have SSL):
///   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
class ApiConfig {
  ApiConfig._();

  /// Full API base URL (e.g. http://localhost:8080/api/v1 or http://DROPLET_IP:8080/api/v1).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// Origin only (e.g. http://localhost:8080) for building media URLs (property images, etc.).
  static String get baseOrigin {
    const path = '/api/v1';
    final i = baseUrl.indexOf(path);
    return i > 0 ? baseUrl.substring(0, i) : baseUrl;
  }
}
