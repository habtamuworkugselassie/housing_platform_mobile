import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/models/auth_model.dart';
import 'package:housing_platform_mobile/core/models/purchase_model.dart';
import 'package:housing_platform_mobile/core/network/api_client.dart';
import 'package:housing_platform_mobile/core/network/api_exceptions.dart';
import 'package:housing_platform_mobile/core/providers/purchase_provider.dart';
import 'package:housing_platform_mobile/core/services/purchase_service.dart';

import 'financing_math_test.dart' show offer;

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super(ApiClient());

  PurchasePreview previewResult = basePreview;
  Object? previewError;
  int previewCalls = 0;
  CreatePurchaseOrderRequest? lastCreate;
  Object? createError;

  @override
  Future<PurchasePreview> preview(String propertyId, {String? currency}) async {
    previewCalls++;
    if (previewError != null) throw previewError!;
    return previewResult;
  }

  @override
  Future<PurchaseOrder> create(CreatePurchaseOrderRequest request) async {
    lastCreate = request;
    if (createError != null) throw createError!;
    return PurchaseOrder.fromJson({
      'id': 'order-1',
      'orderNumber': 'PPO-2026-TEST',
      'status': 'PENDING_SELLER_REVIEW',
      'purchaseType': request.financingOfferId != null ? 'BANK_FINANCED' : 'CASH',
      'property': {'id': request.propertyId},
      'buyer': {'contactPhone': request.contactPhone},
      'pricing': {'listedPrice': 8500000, 'currency': 'ETB'},
    });
  }
}

const promise = AgreementPreview(templateId: 'tpl-1', type: 'PROMISE_TO_PURCHASE', version: 1, title: 'Promise to Purchase Agreement', content: '# PROMISE\n\n**Dream Team PLC**');

const basePreview = PurchasePreview(
  propertyId: 'prop-1',
  listedPrice: 8500000,
  currency: 'ETB',
  purchaseType: 'BANK_FINANCED',
  financingAvailable: true,
  financingOffers: [offer],
  agreementsToSign: [promise],
);

const cashPreview = PurchasePreview(
  propertyId: 'prop-2',
  listedPrice: 8500000,
  currency: 'ETB',
  purchaseType: 'CASH',
  financingAvailable: false,
  financingOffers: [],
  agreementsToSign: [promise],
);

const buyer = AuthResponse(
  accessToken: 'a', tokenType: 'Bearer', expiresIn: 3600, refreshToken: 'r', userId: 'u1',
  email: 'abebe@example.com', firstName: 'Abebe', lastName: 'Kebede', phoneNumber: '0911223344', roles: ['BUYER'], scopes: [],
);

void fillValid(PurchaseFormNotifier n) {
  n.setPhone('0911223344');
  n.setScrolledToEnd(true);
  n.setAccepted(true);
  n.setSignatoryName('Abebe Kebede');
}

void main() {
  late FakePurchaseService service;
  late PurchaseFormNotifier n;

  setUp(() {
    service = FakePurchaseService();
    n = PurchaseFormNotifier(service, 'prop-1');
  });

  group('init', () {
    test('prefills from the profile and picks the recommended offer at its maximum', () async {
      await n.init(user: buyer);
      expect(n.state.phone, '0911223344');
      expect(n.state.email, 'abebe@example.com');
      expect(n.state.signatoryName, 'Abebe Kebede');
      expect(n.state.selectedOfferId, 'offer-1');
      expect(n.state.financedAmount, 6800000);
      expect(n.state.tenureMonths, 240);
      expect(n.state.templateId, 'tpl-1');
      expect(n.state.steps, [WizardStep.contact, WizardStep.financing, WizardStep.agreement, WizardStep.review]);
    });

    test('drops the financing step for a cash-only property', () async {
      service.previewResult = cashPreview;
      await n.init(user: buyer);
      expect(n.state.steps, [WizardStep.contact, WizardStep.agreement, WizardStep.review]);
      expect(n.state.financingApplied, isFalse);
    });

    test('visitors start on the account step and cannot submit', () async {
      await n.init(requireAccount: true);
      expect(n.state.steps.first, WizardStep.account);
      expect(n.state.step, WizardStep.account);
      fillValid(n);
      expect(n.state.canSubmit, isFalse);
      expect(n.state.preview?.agreementsToSign, hasLength(1), reason: 'preview is public');
    });

    test('surfaces a preview failure', () async {
      service.previewError = const ServerException('boom');
      await n.init(user: buyer);
      expect(n.state.previewError, 'boom');
    });
  });

  group('account step', () {
    test('accountReady drops the step, pre-fills and reloads the preview', () async {
      await n.init(requireAccount: true);
      await n.accountReady(fullName: 'Abebe Kebede', phone: '+251911223344', email: 'abebe@example.com');
      expect(n.state.needsAccount, isFalse);
      expect(n.state.step, WizardStep.contact);
      expect(n.state.phone, '+251911223344');
      expect(n.state.signatoryName, 'Abebe Kebede');
      expect(service.previewCalls, 2);
      n.setScrolledToEnd(true);
      n.setAccepted(true);
      expect(n.state.canSubmit, isTrue);
    });

    test('never overwrites a phone the visitor already typed', () async {
      await n.init(requireAccount: true);
      n.setPhone('0700000000');
      await n.accountReady(phone: '+251911223344');
      expect(n.state.phone, '0700000000');
    });
  });

  group('validation gates', () {
    test('contact requires a valid phone and a well-formed optional email', () async {
      await n.init();
      expect(n.state.contactErrors['phone'], 'Phone number is required.');
      n.setPhone('abc');
      expect(n.state.contactErrors['phone'], contains('valid phone'));
      n.setPhone('0911223344');
      n.setEmail('nope');
      expect(n.state.contactErrors['email'], isNotNull);
      n.setEmail('');
      expect(n.state.isStepValid(WizardStep.contact), isTrue);
    });

    test('next refuses to advance from an invalid step', () async {
      await n.init();
      expect(n.next(), isFalse);
      expect(n.state.step, WizardStep.contact);
      n.setPhone('0911223344');
      expect(n.next(), isTrue);
      expect(n.state.step, WizardStep.financing);
    });

    test('financing enforces the offer range and computes the split', () async {
      await n.init(user: buyer);
      n.setFinancedAmount(4250000);
      n.setTenure(180);
      expect(n.state.split!.isMaximum, isFalse);
      expect(n.state.split!.cashPortion, 4250000);
      n.setFinancedAmount(100);
      expect(n.state.financingErrors['financedAmount'], contains('at least'));
      n.setDownPayment(2000000);
      expect(n.state.financedAmount, 6500000);
    });

    test('agreement needs read-to-end, acceptance and a name', () async {
      await n.init(user: buyer);
      n.setSignatoryName('');
      expect(n.state.agreementErrors.keys, containsAll(['scroll', 'accepted', 'signatoryName']));
      n.setScrolledToEnd(true);
      n.setSignatoryName('Abebe Kebede');
      expect(n.state.canSubmit, isFalse);
      n.setAccepted(true);
      expect(n.state.canSubmit, isTrue);
    });

    test('a new template version resets the acceptance', () async {
      await n.init(user: buyer);
      fillValid(n);
      service.previewResult = const PurchasePreview(
        propertyId: 'prop-1', listedPrice: 8500000, currency: 'ETB', purchaseType: 'BANK_FINANCED', financingAvailable: true,
        financingOffers: [offer],
        agreementsToSign: [AgreementPreview(templateId: 'tpl-2', type: 'PROMISE_TO_PURCHASE', version: 2, title: 'Promise to Purchase Agreement', content: 'v2')],
      );
      await n.loadPreview();
      expect(n.state.accepted, isFalse);
      expect(n.state.scrolledToEnd, isFalse);
      expect(n.state.templateId, 'tpl-2');
    });
  });

  group('payload and submit', () {
    test('posts normalised values and the signature', () async {
      await n.init(user: buyer);
      fillValid(n);
      n.setPhone('+251 911 22 33 44');
      n.setEmail('  ');
      n.setMessage('  Saturday?  ');
      n.setFinancedAmount(4250000);
      n.setTenure(180);

      final order = await n.submit();
      expect(order?.id, 'order-1');
      final json = service.lastCreate!.toJson();
      expect(json['contactPhone'], '+251911223344');
      expect(json.containsKey('contactEmail'), isFalse);
      expect(json['buyerMessage'], 'Saturday?');
      expect(json['useFinancing'], isTrue);
      expect(json['financing'], {'financingOfferId': 'offer-1', 'financedAmount': 4250000.0, 'requestedTenureMonths': 180});
      expect(json['promiseToPurchase'], {'templateId': 'tpl-1', 'accepted': true, 'signatoryFullName': 'Abebe Kebede'});
      expect(n.state.createdOrder?.orderNumber, 'PPO-2026-TEST');
    });

    test('opting out of financing sends useFinancing=false and no financing block', () async {
      await n.init(user: buyer);
      fillValid(n);
      n.setUseFinancing(false);
      final json = n.state.payload!.toJson();
      expect(json['useFinancing'], isFalse);
      expect(json.containsKey('financing'), isFalse);
    });

    test('refuses to submit while a gate is open and jumps to that step', () async {
      await n.init(user: buyer);
      fillValid(n);
      n.setAccepted(false);
      n.goTo(WizardStep.review);
      expect(n.state.step, WizardStep.agreement, reason: 'goTo stops at the first invalid step');
      expect(await n.submit(), isNull);
      expect(service.lastCreate, isNull);
    });

    test('maps a duplicate-order error to a friendly message', () async {
      await n.init(user: buyer);
      fillValid(n);
      service.createError = const ValidationException('You already have an open purchase order for this property');
      expect(await n.submit(), isNull);
      expect(n.state.submitError, contains('already have an open purchase order'));
    });

    test('reloads and returns to the agreement when the text changed under the buyer', () async {
      await n.init(user: buyer);
      fillValid(n);
      n.goTo(WizardStep.review);
      service.previewResult = const PurchasePreview(
        propertyId: 'prop-1', listedPrice: 8500000, currency: 'ETB', purchaseType: 'BANK_FINANCED', financingAvailable: true,
        financingOffers: [offer],
        agreementsToSign: [AgreementPreview(templateId: 'tpl-2', type: 'PROMISE_TO_PURCHASE', version: 2, title: 'Promise to Purchase Agreement', content: 'v2')],
      );
      service.createError = const ValidationException('The Promise to Purchase agreement has changed (current version 2)');
      expect(await n.submit(), isNull);
      expect(n.state.step, WizardStep.agreement);
      expect(n.state.accepted, isFalse);
      expect(n.state.templateId, 'tpl-2');
    });

    test('collects server field errors', () async {
      await n.init(user: buyer);
      fillValid(n);
      service.createError = const ValidationException('Validation Failed', errors: {
        'message': 'Validation Failed',
        'fieldErrors': [{'field': 'contactEmail', 'message': 'bad'}],
      });
      await n.submit();
      expect(n.state.submitError, 'Validation Failed');
      expect(n.state.serverFieldErrors, {'contactEmail': 'bad'});
    });
  });
}
