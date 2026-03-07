import '../network/api_client.dart';

class ExhibitionService {
  final ApiClient _apiClient;

  ExhibitionService(this._apiClient);

  /// POST /exhibition/interest - register exhibition interest (exhibitor or visitor).
  Future<void> registerInterest({
    required String email,
    String? phoneNumber,
    required String organizationType,
    required String interestType,
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
        if (company != null && company.trim().isNotEmpty) 'company': company.trim(),
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      },
    );
  }
}
