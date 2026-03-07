import '../network/api_client.dart';
import '../models/organization_model.dart';

class OrganizationService {
  final ApiClient _apiClient;

  OrganizationService(this._apiClient);

  /// Fetch approved organizations for marketplace by type.
  /// Type values: REAL_ESTATE_COMPANY, BANK, INSURANCE, CONTRACTOR,
  /// CONSULTANT_ARCHITECT, SUPPLIER, FINISHING_CONTRACTOR.
  Future<List<OrganizationModel>> getMarketplaceOrganizations(String type) async {
    final response = await _apiClient.get(
      '/organizations/marketplace',
      queryParameters: {'type': type},
    );
    final list = response.data;
    if (list is! List) return [];
    return list
        .map((e) => OrganizationModel.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch organization by ID (for detail page). Public.
  Future<OrganizationModel> getOrganizationById(String id) async {
    final response = await _apiClient.get('/organizations/$id');
    return OrganizationModel.fromJson(
      response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : Map<String, dynamic>.from(response.data as Map),
    );
  }
}
