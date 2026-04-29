import '../network/api_client.dart';

class ExhibitionService {
  final ApiClient _apiClient;

  ExhibitionService(this._apiClient);

  /// GET /sponsorships/active — active tiers for exhibitor package selection.
  Future<List<Map<String, dynamic>>> getActiveSponsorshipPackages() async {
    final res = await _apiClient.get('/sponsorships/active');
    final data = res.data;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// POST /api/v1/exhibition/interest - register exhibition interest (exhibitor or visitor).
  Future<void> registerInterest({
    required String email,
    String? phoneNumber,
    required String organizationType,
    required String interestType,
    String? sponsorshipId,
    String? company,
    String? message,
  }) async {
    await _apiClient.post(
      '/exhibition/interest',
      data: {
        'email': email,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
        'organizationType': organizationType,
        'interestType': interestType,
        if (interestType == 'exhibitor' &&
            sponsorshipId != null &&
            sponsorshipId.trim().isNotEmpty)
          'sponsorshipId': sponsorshipId.trim(),
        if (company != null && company.trim().isNotEmpty) 'company': company.trim(),
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      },
    );
  }
}
