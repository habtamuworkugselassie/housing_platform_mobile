import 'api_client.dart';

/// Resolves full URL for media (images, videos) returned by the API.
/// If [pathOrUrl] is null or empty, returns null.
/// If it already looks like an absolute URL (http/https), returns as-is.
/// Otherwise prepends [ApiClient.baseOrigin].
String? mediaUrl(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
  final trimmed = pathOrUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final origin = ApiClient.baseOrigin;
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$origin$path';
}
