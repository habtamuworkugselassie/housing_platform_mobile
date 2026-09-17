import '../models/page_model.dart';
import '../models/purchase_model.dart';
import '../network/api_client.dart';

/// Purchase orders, financing and the buyer–provider agreements.
class PurchaseService {
  final ApiClient _apiClient;

  PurchaseService(this._apiClient);

  Future<PurchasePreview> preview(String propertyId, {String? currency}) async {
    final response = await _apiClient.get(
      '/properties/$propertyId/purchase-preview',
      queryParameters: currency == null ? null : {'currency': currency},
    );
    return PurchasePreview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> create(CreatePurchaseOrderRequest request) async {
    final response = await _apiClient.post('/purchase-orders', data: request.toJson());
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> getById(String id) async {
    final response = await _apiClient.get('/purchase-orders/$id');
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PagedResponse<PurchaseOrder>> mine({int page = 0, int size = 50, String? status}) async {
    final response = await _apiClient.get('/purchase-orders/me', queryParameters: {
      'page': page,
      'size': size,
      if (status != null) 'status': status,
    });
    return PagedResponse.fromJson(response.data as Map<String, dynamic>, (j) => PurchaseOrder.fromJson(j));
  }

  Future<PurchaseAgreement> getAgreement(String orderId, String agreementId) async {
    final response = await _apiClient.get('/purchase-orders/$orderId/agreements/$agreementId');
    return PurchaseAgreement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseAgreement> signAgreement(String orderId, String agreementId, AgreementSignature signature) async {
    final response = await _apiClient.post('/purchase-orders/$orderId/agreements/$agreementId/sign', data: signature.toJson());
    return PurchaseAgreement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> cancel(String id, {String? notes}) async {
    final response = await _apiClient.post('/purchase-orders/$id/cancel', data: {if (notes != null) 'notes': notes});
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> acceptPartialApproval(String id) async {
    final response = await _apiClient.post('/purchase-orders/$id/accept-partial-approval');
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> convertToCash(String id) async {
    final response = await _apiClient.post('/purchase-orders/$id/convert-to-cash');
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseOrder> updateFinancing(String id, {double? financedAmount, int? requestedTenureMonths}) async {
    final response = await _apiClient.put('/purchase-orders/$id/financing', data: {
      if (financedAmount != null) 'financedAmount': financedAmount,
      if (requestedTenureMonths != null) 'requestedTenureMonths': requestedTenureMonths,
    });
    return PurchaseOrder.fromJson(response.data as Map<String, dynamic>);
  }
}
