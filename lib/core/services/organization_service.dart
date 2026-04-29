import '../network/api_client.dart';
import '../models/organization_model.dart';

class OrganizationService {
  final ApiClient _apiClient;

  OrganizationService(this._apiClient);

  /// Public catalog of active material supplier subcategories (filters).
  Future<List<SupplierSubcategoryRef>> getSupplierSubcategoriesPublic() async {
    final response = await _apiClient.get('/supplier-subcategories');
    final list = response.data;
    if (list is! List) return [];
    return list
        .map((e) => SupplierSubcategoryRef.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch approved organizations for marketplace by type.
  /// Type values: REAL_ESTATE_COMPANY, BANK, INSURANCE, CONTRACTOR,
  /// CONSULTANT_ARCHITECT, SUPPLIER, FINISHING_CONTRACTOR.
  /// Optional [subcategoryId] filters SUPPLIER organizations only.
  Future<List<OrganizationModel>> getMarketplaceOrganizations(
    String type, {
    String? subcategoryId,
  }) async {
    final query = <String, dynamic>{'type': type};
    if (subcategoryId != null && subcategoryId.isNotEmpty) {
      query['subcategoryId'] = subcategoryId;
    }
    final response = await _apiClient.get(
      '/organizations/marketplace',
      queryParameters: query,
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
