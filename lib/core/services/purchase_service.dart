import 'package:dio/dio.dart';

import '../models/page_model.dart';
import '../models/purchase_model.dart';
import '../network/api_client.dart';

/// Purchase orders, financing and the buyer–provider agreements.
class PurchaseService {
  final ApiClient _apiClient;

  PurchaseService(this._apiClient);

  /// [depositCurrency] 'USD' quotes (and renders the deposit terms for) a USD card deposit.
  Future<PurchasePreview> preview(String propertyId, {String? currency, String? depositCurrency}) async {
    final params = <String, dynamic>{
      if (currency != null) 'currency': currency,
      if (depositCurrency != null) 'depositCurrency': depositCurrency,
    };
    final response = await _apiClient.get(
      '/properties/$propertyId/purchase-preview',
      queryParameters: params.isEmpty ? null : params,
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

  /// Starts (or resumes) the reservation-deposit checkout at the payment provider.
  /// A non-null [paymentMethod] replaces the one picked when the order was placed.
  Future<DepositCheckout> startDepositCheckout(String orderId, {String? paymentMethod}) async {
    final response = await _apiClient.post(
      '/purchase-orders/$orderId/deposit/checkout',
      data: paymentMethod == null ? null : {'paymentMethod': paymentMethod},
    );
    return DepositCheckout.fromJson(response.data as Map<String, dynamic>);
  }

  /// Asks the server to confirm the deposit with the provider; idempotent.
  Future<PurchaseDeposit> confirmDeposit(String orderId) async {
    final response = await _apiClient.post('/purchase-orders/$orderId/deposit/confirm');
    return PurchaseDeposit.fromJson(response.data as Map<String, dynamic>);
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

  // ---------------------------------------------------------------- balance and service fee

  Future<PurchaseBalance> getBalance(String orderId) async {
    final response = await _apiClient.get('/purchase-orders/$orderId/balance');
    return PurchaseBalance.fromJson(response.data as Map<String, dynamic>);
  }

  /// [purpose] 'FEES' pays the service fee (markup + VAT); 'BALANCE' the rest of the price.
  Future<DepositCheckout> payBalanceOnline(String orderId, double amount, String? paymentMethod, {String purpose = 'BALANCE'}) async {
    final response = await _apiClient.post('/purchase-orders/$orderId/balance/checkout', data: {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'purpose': purpose,
    });
    return DepositCheckout.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PurchaseBalance> confirmBalance(String orderId) async {
    final response = await _apiClient.post('/purchase-orders/$orderId/balance/confirm');
    return PurchaseBalance.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reports a bank transfer with a photo or PDF of the receipt; the seller or an admin confirms it.
  Future<PurchaseBalance> reportTransfer(
    String orderId, {
    required double amount,
    required String reference,
    String? paidOn,
    required List<int> receipt,
    required String receiptName,
    String purpose = 'BALANCE',
  }) async {
    final form = FormData.fromMap({
      'amount': amount.toString(),
      'reference': reference,
      if (paidOn != null) 'paidOn': paidOn,
      'purpose': purpose,
      'slip': MultipartFile.fromBytes(receipt, filename: receiptName),
    });
    final response = await _apiClient.postForm('/purchase-orders/$orderId/balance/transfers', data: form);
    return PurchaseBalance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<int>> balanceReceipt(String orderId, String paymentId) =>
      _apiClient.getBytes('/purchase-orders/$orderId/balance/payments/$paymentId/slip');

  // ---------------------------------------------------------------- property documents

  Future<List<PropertyDocumentItem>> orderDocuments(String orderId) async {
    final response = await _apiClient.get('/purchase-orders/$orderId/documents');
    return (response.data as List? ?? []).map((e) => PropertyDocumentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<int>> orderDocumentFile(String orderId, String documentId) =>
      _apiClient.getBytes('/purchase-orders/$orderId/documents/$documentId/file');

  Future<List<int>> previewDocumentFile(String propertyId, String documentId) =>
      _apiClient.getBytes('/properties/$propertyId/purchase-preview/documents/$documentId/file');
}
