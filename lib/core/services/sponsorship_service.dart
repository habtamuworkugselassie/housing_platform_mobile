import '../network/api_client.dart';
import '../models/sponsored_organization_model.dart';

class SponsorshipService {
  final ApiClient _apiClient;

  SponsorshipService(this._apiClient);

  /// Exclusive sponsors only (for splash and hero). Public endpoint.
  Future<List<SponsoredOrganizationModel>> getExclusiveOrganizations() async {
    final response = await _apiClient.get('/sponsorships/exclusive-organizations');
    final list = response.data;
    if (list is! List) return [];
    return (list as List)
        .map((e) => SponsoredOrganizationModel.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// All sponsored organizations (for partners list). Public endpoint.
  Future<List<SponsoredOrganizationModel>> getSponsoredOrganizations() async {
    final response = await _apiClient.get('/sponsorships/sponsored-organizations');
    final list = response.data;
    if (list is! List) return [];
    return (list as List)
        .map((e) => SponsoredOrganizationModel.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
