import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/models/purchase_model.dart';
import 'package:housing_platform_mobile/core/utils/financing_math.dart';

const offer = FinancingOption(
  financingOfferId: 'offer-1',
  bankId: 'bank-1',
  bankName: 'Awash Bank',
  creditProductId: 'product-1',
  creditProductName: 'Home Purchase Loan',
  offerLevel: 'PROPERTY',
  interestRate: 14.5,
  ltvRatio: 0.8,
  minTenureMonths: 12,
  maxTenureMonths: 240,
  minFinanceableAmount: 500000,
  maxFinanceableAmount: 6800000,
  minimumDownPayment: 1700000,
  partialFinancingAllowed: true,
  recommended: true,
);

void main() {
  test('instalments match the backend figures', () {
    expect(FinancingMath.monthlyInstallment(6800000, 14.5, 240), 87039.85);
    expect(FinancingMath.monthlyInstallment(4250000, 14.5, 180), 58033.79);
    expect(FinancingMath.monthlyInstallment(1200000, 0, 120), 10000);
    expect(FinancingMath.monthlyInstallment(0, 14.5, 120), 0);
  });

  test('split classifies maximum vs partial and clamps', () {
    final max = FinancingMath.split(offer, 8500000, 6800000, 240);
    expect(max.isMaximum, isTrue);
    expect(max.cashPortion, 1700000);
    expect(max.coverageRatio, 0.8);

    final partial = FinancingMath.split(offer, 8500000, 4250000, 180);
    expect(partial.isMaximum, isFalse);
    expect(partial.cashPortion, 4250000);
    expect(partial.coverageRatio, 0.5);
    expect(partial.installment, 58033.79);

    expect(FinancingMath.split(offer, 8500000, 9000000, 240).financedAmount, 6800000);
    expect(FinancingMath.split(offer, 8500000, 100, 240).financedAmount, 500000);
    expect(FinancingMath.split(offer, 8500000, 4000000, 600).tenureMonths, 240);
  });

  test('validation mirrors the server rules', () {
    expect(FinancingMath.validateAmount(offer, 300000), contains('at least'));
    expect(FinancingMath.validateAmount(offer, 7000000), contains('cannot exceed'));
    expect(FinancingMath.validateAmount(offer, 4250000), isNull);
    expect(FinancingMath.validateTenure(offer, 6), contains('between 12 and 240'));
    expect(FinancingMath.validateTenure(offer, 180), isNull);
  });

  test('money formatting', () {
    expect(FinancingMath.formatMoney(8500000), '8,500,000.00');
    expect(FinancingMath.formatMoney(87039.85, currency: 'ETB'), '87,039.85 ETB');
    expect(FinancingMath.formatMoney(999.5), '999.50');
  });
}
