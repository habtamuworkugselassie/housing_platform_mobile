import 'api_config.dart';

/// Resolves full URL for media (images, videos) returned by the API.
/// If [pathOrUrl] is null or empty, returns null.
/// If it already looks like an absolute URL (http/https), returns as-is.
/// Otherwise prepends [ApiConfig.baseOrigin] so organization/sponsor media
/// use the same backend as the app (localhost or Droplet when built with --dart-define).
String? mediaUrl(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
  final trimmed = pathOrUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final origin = ApiConfig.baseOrigin;
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$origin$path';
}
