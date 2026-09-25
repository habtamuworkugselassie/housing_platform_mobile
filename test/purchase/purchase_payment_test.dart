import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/models/purchase_model.dart';
import 'package:housing_platform_mobile/core/providers/purchase_provider.dart';
import 'package:housing_platform_mobile/features/purchase/widgets/balance_section.dart';
import 'package:housing_platform_mobile/features/purchase/widgets/purchase_payment_widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'purchase_form_notifier_test.dart' show FakePurchaseService, buyer, promise;

const depositTerms = AgreementPreview(templateId: 'tpl-dep', type: 'RESERVATION_DEPOSIT_TERMS', version: 3, title: 'Reservation Deposit Terms', content: '# DEPOSIT');

const etbDeposit = DepositQuote(amount: 32000, currency: 'ETB', checkoutAvailable: true, usdAmount: 213.33);

const depositPreview = PurchasePreview(
  propertyId: 'prop-1',
  listedPrice: 3200000,
  currency: 'ETB',
  purchaseType: 'CASH',
  financingAvailable: false,
  financingOffers: [],
  agreementsToSign: [promise, depositTerms],
  deposit: etbDeposit,
  fees: FeeQuote(markupPercent: 2, markupAmount: 64000, vatRate: 15, vatAmount: 489600, total: 553600, currency: 'ETB'),
);

class DepositFakeService extends FakePurchaseService {
  final List<String?> depositCurrencies = [];
  double? paidAmount;
  String? paidMethod;
  String? paidPurpose;
  String? transferPurpose;
  PurchaseBalance balance = PurchaseBalance.fromJson(balanceJson());

  @override
  Future<PurchasePreview> preview(String propertyId, {String? currency, String? depositCurrency}) async {
    depositCurrencies.add(depositCurrency);
    if (depositCurrency == 'USD') {
      return const PurchasePreview(
        propertyId: 'prop-1',
        listedPrice: 3200000,
        currency: 'ETB',
        purchaseType: 'CASH',
        financingAvailable: false,
        financingOffers: [],
        agreementsToSign: [promise, depositTerms],
        deposit: DepositQuote(amount: 213.33, currency: 'USD', checkoutAvailable: true, paymentMethods: ['CARD'], baseAmount: 32000, baseCurrency: 'ETB', exchangeRate: 150),
      );
    }
    return depositPreview;
  }

  @override
  Future<PurchaseBalance> getBalance(String orderId) async => balance;

  @override
  Future<DepositCheckout> payBalanceOnline(String orderId, double amount, String? paymentMethod, {String purpose = 'BALANCE'}) async {
    paidAmount = amount;
    paidMethod = paymentMethod;
    paidPurpose = purpose;
    return const DepositCheckout(checkoutUrl: 'https://checkout/x', txRef: 'T');
  }

  @override
  Future<PurchaseBalance> reportTransfer(String orderId,
      {required double amount, required String reference, String? paidOn, required List<int> receipt, required String receiptName, String purpose = 'BALANCE'}) async {
    transferPurpose = purpose;
    return PurchaseBalance.fromJson(balanceJson(inProgress: amount));
  }
}

Map<String, dynamic> balanceJson({double inProgress = 0, bool withFees = true}) => {
      'currency': 'ETB',
      'listedPrice': 3200000,
      'depositCredit': 32000,
      'loanAmount': 0,
      'balanceDue': 3168000,
      'paid': 0,
      'inProgress': inProgress,
      'remaining': 3168000,
      'fullyPaid': false,
      'payable': true,
      'checkoutAvailable': true,
      'paymentMethods': DepositMethods.all,
      'bankAccount': {'bankName': 'Commercial Bank of Ethiopia', 'accountName': 'Dream Teams Trading PLC', 'accountNumber': '1000123456789'},
      'transferReference': 'PPO-2026-1F99D681-BAL',
      'instalments': [
        {'sequence': 1, 'label': 'On signing', 'amount': 1168000, 'covered': 0, 'paid': false, 'overdue': false},
        {'sequence': 2, 'label': 'Handover', 'amount': 2000000, 'covered': 0, 'paid': false, 'overdue': false},
      ],
      'payments': [],
      if (withFees)
        'fees': {'markupPercent': 2, 'markupAmount': 64000, 'vatRate': 15, 'vatAmount': 489600, 'total': 553600, 'paid': 0, 'inProgress': 0, 'remaining': 553600, 'fullyPaid': false},
    };

void main() {
  group('payment step in the order form', () {
    late DepositFakeService service;
    late PurchaseFormNotifier n;

    setUp(() {
      service = DepositFakeService();
      n = PurchaseFormNotifier(service, 'prop-1');
    });

    test('adds a payment step and needs a method and both agreements', () async {
      await n.init(user: buyer);
      expect(n.state.steps, [WizardStep.contact, WizardStep.payment, WizardStep.agreement, WizardStep.review]);
      n.setPhone('0911223344');
      n.setScrolledToEnd(true);
      n.setAccepted(true);
      expect(n.state.isStepValid(WizardStep.payment), isFalse);
      n.setPaymentMethod('TELEBIRR');
      expect(n.state.isStepValid(WizardStep.agreement), isFalse, reason: 'deposit terms not read yet');
      n.setDepositScrolledToEnd(true);
      n.setDepositAccepted(true);
      expect(n.state.canSubmit, isTrue);
    });

    test('posts the method and signs the deposit terms with the same name', () async {
      await n.init(user: buyer);
      n.setPhone('0911223344');
      n.setScrolledToEnd(true);
      n.setAccepted(true);
      n.setPaymentMethod('CBE_BIRR');
      n.setDepositScrolledToEnd(true);
      n.setDepositAccepted(true);
      await n.submit();
      final body = service.lastCreate!.toJson();
      expect(body['depositPaymentMethod'], 'CBE_BIRR');
      expect(body['depositTerms'], {'templateId': 'tpl-dep', 'accepted': true, 'signatoryFullName': 'Abebe Kebede'});
      expect(body.containsKey('depositCurrency'), isFalse);
    });

    test('switching to USD re-quotes by card and resets the deposit terms', () async {
      await n.init(user: buyer);
      n.setPaymentMethod('TELEBIRR');
      n.setDepositScrolledToEnd(true);
      n.setDepositAccepted(true);
      await n.setDepositCurrency('USD');
      expect(service.depositCurrencies.last, 'USD');
      expect(n.state.depositQuote?.amount, 213.33);
      expect(n.state.paymentMethod, 'CARD');
      expect(n.state.depositAccepted, isFalse);
      expect(n.state.payload?.depositCurrency, 'USD');
      await n.setDepositCurrency('ETB');
      expect(n.state.depositCurrency, isNull);
      expect(n.state.depositQuote?.currency, 'ETB');
    });
  });

  test('models read the balance, fees and documents', () {
    final b = PurchaseBalance.fromJson(balanceJson(inProgress: 100000));
    expect(b.room, 3068000);
    expect(b.fees!.room, 553600);
    expect(b.instalments.first.label, 'On signing');
    final doc = PropertyDocumentItem.fromJson({'id': 'd1', 'documentType': 'TITLE_DEED', 'fileName': 'deed.pdf', 'documentNumber': 'AA/1'});
    expect(PropertyDocumentItem.typeLabel(doc.documentType), contains('Title deed'));
    final deposit = PurchaseDeposit.fromJson({'amount': 213.33, 'currency': 'USD', 'status': 'PAID', 'baseAmount': 32000, 'baseCurrency': 'ETB', 'exchangeRate': 150, 'preferredMethod': 'CARD'});
    expect(deposit.baseAmount, 32000);
    expect(deposit.preferredMethod, 'CARD');
  });

  Future<void> pumpWidget(WidgetTester tester, Widget child, DepositFakeService service) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [purchaseServiceProvider.overrideWithValue(service)],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('payment step shows the deposit, the methods and the fee', (tester) async {
    final service = DepositFakeService();
    final n = PurchaseFormNotifier(service, 'prop-1');
    await n.init(user: buyer);
    await pumpWidget(tester, PurchasePaymentStep(form: n.state, notifier: n, attempted: true), service);
    expect(find.byKey(const Key('deposit-quote')), findsOneWidget);
    expect(find.text('telebirr'), findsOneWidget);
    expect(find.text('Card or other method'), findsOneWidget);
    expect(find.text('Choose how you will pay the deposit.'), findsOneWidget);
    expect(find.byKey(const Key('fee-summary')), findsOneWidget);
    expect(find.textContaining('Cash'), findsNothing);
  });

  testWidgets('balance section pays the fee first, then the balance', (tester) async {
    final service = DepositFakeService();
    final opened = <Uri>[];
    await pumpWidget(tester, BalanceSection(orderId: 'o1', openUrl: (u) async {
      opened.add(u);
      return true;
    }), service);
    expect(find.byKey(const Key('fee-summary')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('balance-amount'))).controller!.text, '553600');
    await tester.tap(find.byKey(const Key('method-TELEBIRR')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('balance-pay-online')));
    await tester.pumpAndSettle();
    expect(service.paidPurpose, 'FEES');
    expect(service.paidAmount, 553600);
    expect(service.paidMethod, 'TELEBIRR');
    expect(opened.single.toString(), 'https://checkout/x');

    await tester.tap(find.byKey(const Key('purpose-BALANCE')));
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const Key('balance-amount'))).controller!.text, '1168000');
  });

  testWidgets('balance section reports a bank transfer with a receipt photo', (tester) async {
    final service = DepositFakeService()..balance = PurchaseBalance.fromJson(balanceJson(withFees: false));
    await pumpWidget(
      tester,
      BalanceSection(orderId: 'o1', pickReceipt: () async => XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'receipt.jpg')),
      service,
    );
    await tester.tap(find.byKey(const Key('tab-transfer')));
    await tester.pump();
    expect(find.text('1000123456789'), findsOneWidget);
    expect(find.textContaining('PPO-2026-1F99D681-BAL'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('transfer-reference')), 'FT26092512');
    await tester.tap(find.byKey(const Key('transfer-receipt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-submit')));
    await tester.pumpAndSettle();
    expect(service.transferPurpose, 'BALANCE');
    expect(find.text('Awaiting confirmation'), findsOneWidget);
  });
}
