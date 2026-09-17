import 'dart:math' as math;

import '../models/purchase_model.dart';

/// Client-side financing maths for live previews while the buyer moves the slider. The backend
/// recomputes and stores the authoritative figures; these only have to agree with it.
class FinancingMath {
  FinancingMath._();

  static double round2(double v) => (v * 100).roundToDouble() / 100;

  /// Standard amortised instalment; a zero rate degenerates to principal / months.
  static double monthlyInstallment(double principal, double annualRatePercent, int months) {
    if (principal <= 0 || months <= 0) return 0;
    if (annualRatePercent == 0) return round2(principal / months);
    final i = annualRatePercent / 100 / 12;
    final factor = math.pow(1 + i, months).toDouble();
    return round2(principal * i / (1 - 1 / factor));
  }

  static double clampAmount(FinancingOption option, double wanted) =>
      math.min(option.maxFinanceableAmount, math.max(option.minFinanceableAmount, wanted));

  static FinancingSplit split(FinancingOption option, double listedPrice, double financedAmount, int tenureMonths) {
    final financed = round2(clampAmount(option, financedAmount));
    final tenure = math.min(option.maxTenureMonths, math.max(option.minTenureMonths, tenureMonths));
    return FinancingSplit(
      financedAmount: financed,
      cashPortion: round2(listedPrice - financed),
      coverageRatio: listedPrice > 0 ? (financed / listedPrice * 10000).round() / 10000 : 0,
      tenureMonths: tenure,
      installment: monthlyInstallment(financed, option.interestRate, tenure),
      isMaximum: financed >= option.maxFinanceableAmount,
    );
  }

  /// Validation the server will also apply; null when fine.
  static String? validateAmount(FinancingOption option, double? amount) {
    if (amount == null || amount.isNaN || amount <= 0) return 'Enter the amount you want to finance.';
    if (amount < option.minFinanceableAmount) {
      return 'The financed amount must be at least ${formatMoney(option.minFinanceableAmount)}.';
    }
    if (amount > option.maxFinanceableAmount) {
      return 'The financed amount cannot exceed ${formatMoney(option.maxFinanceableAmount)}.';
    }
    return null;
  }

  static String? validateTenure(FinancingOption option, int? months) {
    if (months == null) return 'Enter the repayment period in months.';
    if (months < option.minTenureMonths || months > option.maxTenureMonths) {
      return 'The repayment period must be between ${option.minTenureMonths} and ${option.maxTenureMonths} months.';
    }
    return null;
  }

  /// 8,500,000.00 — thousands separators, two decimals, no locale dependency.
  static String formatMoney(double value, {String? currency}) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final sign = value < 0 ? '-' : '';
    final amount = '$sign$buffer.${parts[1]}';
    return currency == null ? amount : '$amount $currency';
  }
}

class FinancingSplit {
  final double financedAmount;
  final double cashPortion;
  final double coverageRatio;
  final int tenureMonths;
  final double installment;
  final bool isMaximum;

  const FinancingSplit({
    required this.financedAmount,
    required this.cashPortion,
    required this.coverageRatio,
    required this.tenureMonths,
    required this.installment,
    required this.isMaximum,
  });
}
