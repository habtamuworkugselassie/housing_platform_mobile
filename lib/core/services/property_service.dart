import '../network/api_client.dart';
import '../models/property_model.dart';
import '../models/page_model.dart';

class PropertyService {
  final ApiClient _apiClient;

  PropertyService(this._apiClient);

  Future<PagedResponse<PropertyModel>> getProperties({
    int page = 0,
    int size = 20,
    String? status,
    String? city,
    String? type,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'size': size,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final response = await _apiClient.get(
      '/properties',
      queryParameters: queryParams,
    );

    return PagedResponse<PropertyModel>.fromJson(
      response.data,
      (json) => PropertyModel.fromJson(json),
    );
  }

  Future<PropertyModel> getPropertyById(String id) async {
    final response = await _apiClient.get('/properties/$id');
    return PropertyModel.fromJson(response.data);
  }

  /// Public: list available properties for an organization (marketplace).
  Future<List<PropertyModel>> getPropertiesByOrganization(String organizationId) async {
    final response = await _apiClient.get('/properties/organization/$organizationId/list');
    final list = response.data;
    if (list is! List) return [];
    return list
        .map((e) => PropertyModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<PropertyModel>> searchProperties({
    String? companyName,
    String? city,
    String? state,
    String? country,
    String? title,
    int limit = 50,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};
    if (companyName != null && companyName.isNotEmpty) queryParams['companyName'] = companyName;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (country != null && country.isNotEmpty) queryParams['country'] = country;
    if (title != null && title.isNotEmpty) queryParams['title'] = title;

    final response = await _apiClient.get(
      '/properties/search',
      queryParameters: queryParams,
    );

    final rawList = response.data as List<dynamic>? ?? [];
    return rawList.map((e) => PropertyModel.fromJson(e)).toList();
  }
}
