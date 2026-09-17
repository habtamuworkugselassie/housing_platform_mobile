import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/models/purchase_model.dart';

void main() {
  test('parses the deposit block of an order', () {
    final order = PurchaseOrder.fromJson({
      'id': 'o1',
      'orderNumber': 'PPO-2026-X',
      'status': 'AWAITING_PAYMENT',
      'purchaseType': 'CASH',
      'property': {'id': 'p1', 'title': 'Flat'},
      'buyer': {'contactPhone': '+251911223344'},
      'pricing': {'listedPrice': 8500000, 'currency': 'ETB'},
      'deposit': {
        'amount': 85000,
        'currency': 'ETB',
        'status': 'PENDING',
        'dueAt': '2026-09-20T10:00:00',
        'provider': 'CHAPA',
        'txRef': 'PPO-2026-X-DEP1-ABC',
        'checkoutUrl': 'https://checkout.chapa.co/x',
        'attempts': 1,
        'termsPending': false,
        'checkoutAvailable': true,
      },
    });
    final d = order.deposit!;
    expect(d.amount, 85000);
    expect(d.status, 'PENDING');
    expect(d.isPayable, isTrue);
    expect(d.isSettled, isFalse);
    expect(d.checkoutUrl, 'https://checkout.chapa.co/x');
    expect(d.dueAt, isNotNull);
    expect(PurchaseOrderLabels.depositStatus('REFUND_PENDING'), 'Refund pending');
  });

  test('orders without a deposit parse to null and settled deposits are not payable', () {
    final order = PurchaseOrder.fromJson({
      'id': 'o1', 'orderNumber': 'X', 'status': 'PENDING_SELLER_REVIEW', 'purchaseType': 'CASH',
      'property': {'id': 'p1'}, 'buyer': {'contactPhone': '+2519'}, 'pricing': {'listedPrice': 1, 'currency': 'ETB'},
    });
    expect(order.deposit, isNull);
    final paid = PurchaseDeposit.fromJson({'amount': 1, 'status': 'PAID', 'provider': 'CHAPA', 'attempts': 1});
    expect(paid.isSettled, isTrue);
    expect(paid.isPayable, isFalse);
    final checkout = DepositCheckout.fromJson({'checkoutUrl': 'https://x', 'txRef': 't'});
    expect(checkout.txRef, 't');
  });
}
