import '../models/live_broadcast_model.dart';
import '../network/api_client.dart';

/// Live broadcasting endpoints (mirrors frontend exhibition.api live methods).
/// The base URL already includes /api/v1, so paths are passed without that prefix.
class LiveService {
  final ApiClient _apiClient;

  LiveService(this._apiClient);

  /// POST /api/v1/exhibition/live/request — create a pending go-live request.
  /// role: VISITOR | EXHIBITOR | ORGANIZER (exhibitor needs a signed-in account,
  /// organizer is reserved for admins — the backend enforces this via the bearer token).
  Future<LiveBroadcast> requestGoLive({
    required String name,
    String? email,
    required String role,
    String? company,
    required String title,
  }) async {
    final res = await _apiClient.post(
      '/exhibition/live/request',
      data: {
        'name': name,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'role': role,
        if (company != null && company.trim().isNotEmpty) 'company': company.trim(),
        'title': title,
      },
    );
    return LiveBroadcast.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// GET /api/v1/exhibition/live/{id} — poll a broadcast's public status (for approval).
  Future<LiveBroadcast> getBroadcast(String id) async {
    final res = await _apiClient.get('/exhibition/live/$id');
    return LiveBroadcast.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// GET /api/v1/exhibition/live/{id}/publish-token — broadcaster publish token (once approved).
  Future<LiveToken> getPublishToken(String id) async {
    final res = await _apiClient.get('/exhibition/live/$id/publish-token');
    return LiveToken.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// GET /api/v1/exhibition/live/{id}/viewer-token — subscribe-only token for a live stream.
  Future<LiveToken> getViewerToken(String id) async {
    final res = await _apiClient.get('/exhibition/live/$id/viewer-token');
    return LiveToken.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// GET /api/v1/exhibition/live — public wall of currently-live streams.
  Future<List<LiveBroadcast>> listLive() async {
    final res = await _apiClient.get('/exhibition/live');
    final data = res.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => LiveBroadcast.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
