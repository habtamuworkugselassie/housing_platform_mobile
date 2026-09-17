import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_model.dart';
import '../models/purchase_model.dart';
import '../network/api_exceptions.dart';
import '../services/purchase_service.dart';
import '../utils/financing_math.dart';
import '../utils/phone_number.dart';
import 'auth_provider.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) => PurchaseService(ref.read(apiClientProvider)));

enum WizardStep { account, contact, financing, agreement, review }

/// Everything the purchase wizard needs, in one immutable value. Derived values are getters so
/// the UI and the tests read the same rules.
class PurchaseFormState {
  final String propertyId;
  final PurchasePreview? preview;
  final bool loadingPreview;
  final String? previewError;

  /// True for visitors: an account step (Google / quick sign-up / WhatsApp code) comes first.
  final bool needsAccount;
  final WizardStep step;

  // contact
  final String phone;
  final String email;
  final String message;

  // financing
  final bool useFinancing;
  final String? selectedOfferId;
  final double? financedAmount;
  final int? tenureMonths;

  // agreement
  final String? templateId;
  final bool scrolledToEnd;
  final bool accepted;
  final String signatoryName;

  // submission
  final bool submitting;
  final String? submitError;
  final Map<String, String> serverFieldErrors;
  final PurchaseOrder? createdOrder;

  const PurchaseFormState({
    required this.propertyId,
    this.preview,
    this.loadingPreview = false,
    this.previewError,
    this.needsAccount = false,
    this.step = WizardStep.contact,
    this.phone = '',
    this.email = '',
    this.message = '',
    this.useFinancing = true,
    this.selectedOfferId,
    this.financedAmount,
    this.tenureMonths,
    this.templateId,
    this.scrolledToEnd = false,
    this.accepted = false,
    this.signatoryName = '',
    this.submitting = false,
    this.submitError,
    this.serverFieldErrors = const {},
    this.createdOrder,
  });

  PurchaseFormState copyWith({
    PurchasePreview? preview,
    bool clearPreview = false,
    bool? loadingPreview,
    String? previewError,
    bool clearPreviewError = false,
    bool? needsAccount,
    WizardStep? step,
    String? phone,
    String? email,
    String? message,
    bool? useFinancing,
    String? selectedOfferId,
    double? financedAmount,
    int? tenureMonths,
    String? templateId,
    bool clearTemplateId = false,
    bool? scrolledToEnd,
    bool? accepted,
    String? signatoryName,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    Map<String, String>? serverFieldErrors,
    PurchaseOrder? createdOrder,
  }) {
    return PurchaseFormState(
      propertyId: propertyId,
      preview: clearPreview ? null : (preview ?? this.preview),
      loadingPreview: loadingPreview ?? this.loadingPreview,
      previewError: clearPreviewError ? null : (previewError ?? this.previewError),
      needsAccount: needsAccount ?? this.needsAccount,
      step: step ?? this.step,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      message: message ?? this.message,
      useFinancing: useFinancing ?? this.useFinancing,
      selectedOfferId: selectedOfferId ?? this.selectedOfferId,
      financedAmount: financedAmount ?? this.financedAmount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      scrolledToEnd: scrolledToEnd ?? this.scrolledToEnd,
      accepted: accepted ?? this.accepted,
      signatoryName: signatoryName ?? this.signatoryName,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      serverFieldErrors: serverFieldErrors ?? this.serverFieldErrors,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }

  // ------------------------------------------------------------------ derived

  bool get financingAvailable => preview?.financingAvailable == true;

  /// The financing step disappears entirely when the property has no active financing product.
  List<WizardStep> get steps {
    final rest = financingAvailable
        ? const [WizardStep.contact, WizardStep.financing, WizardStep.agreement, WizardStep.review]
        : const [WizardStep.contact, WizardStep.agreement, WizardStep.review];
    return needsAccount ? [WizardStep.account, ...rest] : rest;
  }

  int get stepIndex => steps.indexOf(step);

  FinancingOption? get selectedOffer {
    final offers = preview?.financingOffers ?? const [];
    for (final o in offers) {
      if (o.financingOfferId == selectedOfferId) return o;
    }
    return null;
  }

  bool get financingApplied => financingAvailable && useFinancing && selectedOffer != null;

  FinancingSplit? get split {
    final offer = selectedOffer;
    if (!financingApplied || preview == null || offer == null) return null;
    return FinancingMath.split(
      offer,
      preview!.listedPrice,
      financedAmount ?? offer.maxFinanceableAmount,
      tenureMonths ?? offer.maxTenureMonths,
    );
  }

  AgreementPreview? get promiseAgreement =>
      (preview?.agreementsToSign.isNotEmpty ?? false) ? preview!.agreementsToSign.first : null;

  Map<String, String> get contactErrors {
    final errors = <String, String>{};
    if (phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required.';
    } else if (!PhoneNumber.isValid(phone)) {
      errors['phone'] = 'Enter a valid phone number, e.g. 0911223344 or +251911223344.';
    }
    if (email.trim().isNotEmpty && !PhoneNumber.isValidEmail(email)) errors['email'] = 'Please enter a valid email.';
    if (message.length > 2000) errors['message'] = 'The message cannot exceed 2000 characters.';
    return errors;
  }

  Map<String, String> get financingErrors {
    final errors = <String, String>{};
    if (!financingAvailable || !useFinancing) return errors;
    final offer = selectedOffer;
    if (offer == null) {
      errors['offer'] = 'Choose a financing offer or turn off bank financing.';
      return errors;
    }
    final amountError = FinancingMath.validateAmount(offer, financedAmount ?? offer.maxFinanceableAmount);
    if (amountError != null) errors['financedAmount'] = amountError;
    final tenureError = FinancingMath.validateTenure(offer, tenureMonths ?? offer.maxTenureMonths);
    if (tenureError != null) errors['tenureMonths'] = tenureError;
    return errors;
  }

  Map<String, String> get agreementErrors {
    final errors = <String, String>{};
    if (promiseAgreement == null) {
      errors['agreement'] = 'The Promise to Purchase agreement is not available right now.';
      return errors;
    }
    if (!scrolledToEnd) errors['scroll'] = 'Please read the whole agreement.';
    if (!accepted) errors['accepted'] = 'You must accept the agreement to continue.';
    if (signatoryName.trim().length < 3) errors['signatoryName'] = 'Enter your full name as your signature.';
    return errors;
  }

  bool isStepValid(WizardStep s) {
    switch (s) {
      case WizardStep.account:
        return !needsAccount;
      case WizardStep.contact:
        return contactErrors.isEmpty;
      case WizardStep.financing:
        return financingErrors.isEmpty;
      case WizardStep.agreement:
        return agreementErrors.isEmpty;
      case WizardStep.review:
        return true;
    }
  }

  bool get canSubmit =>
      !submitting &&
      !needsAccount &&
      isStepValid(WizardStep.contact) &&
      isStepValid(WizardStep.financing) &&
      isStepValid(WizardStep.agreement);

  /// Exactly what will be posted; also shown on the review step.
  CreatePurchaseOrderRequest? get payload {
    final agreement = promiseAgreement;
    if (preview == null || agreement == null) return null;
    final offer = selectedOffer;
    final s = split;
    bool? useFinancingFlag;
    String? offerId;
    double? amount;
    int? tenure;
    if (financingAvailable) {
      if (!useFinancing) {
        useFinancingFlag = false;
      } else if (offer != null && s != null) {
        useFinancingFlag = true;
        offerId = offer.financingOfferId;
        amount = s.financedAmount;
        tenure = s.tenureMonths;
      }
    }
    return CreatePurchaseOrderRequest(
      propertyId: propertyId,
      contactPhone: PhoneNumber.normalize(phone) ?? phone.trim(),
      contactEmail: email.trim().isEmpty ? null : email.trim(),
      currency: preview!.currency,
      buyerMessage: message.trim().isEmpty ? null : message.trim(),
      useFinancing: useFinancingFlag,
      financingOfferId: offerId,
      financedAmount: amount,
      requestedTenureMonths: tenure,
      promiseToPurchase: AgreementSignature(
        templateId: agreement.templateId,
        accepted: accepted,
        signatoryFullName: signatoryName.trim(),
      ),
    );
  }
}

class PurchaseFormNotifier extends StateNotifier<PurchaseFormState> {
  final PurchaseService _service;

  PurchaseFormNotifier(this._service, String propertyId) : super(PurchaseFormState(propertyId: propertyId));

  /// Starts the wizard. Visitors (`requireAccount`) begin on the account step; the preview is
  /// public so financing offers and the agreement load either way.
  Future<void> init({AuthResponse? user, bool requireAccount = false}) async {
    state = PurchaseFormState(
      propertyId: state.propertyId,
      needsAccount: requireAccount,
      step: requireAccount ? WizardStep.account : WizardStep.contact,
      phone: user?.phoneNumber ?? '',
      email: user?.email ?? '',
      signatoryName: user?.fullName ?? '',
    );
    await loadPreview();
  }

  Future<void> loadPreview() async {
    state = state.copyWith(loadingPreview: true, clearPreviewError: true);
    try {
      final preview = await _service.preview(state.propertyId);
      var next = state.copyWith(preview: preview, loadingPreview: false);
      final offers = preview.financingOffers;
      if (offers.isNotEmpty) {
        FinancingOption? keep;
        for (final o in offers) {
          if (o.financingOfferId == state.selectedOfferId) keep = o;
        }
        final chosen = keep ?? offers.firstWhere((o) => o.recommended, orElse: () => offers.first);
        next = _withOffer(next, chosen, keepAmounts: keep != null);
      }
      // A new template version invalidates any previous acceptance.
      final promise = preview.agreementsToSign.isEmpty ? null : preview.agreementsToSign.first;
      if (promise == null || promise.templateId != state.templateId) {
        next = next.copyWith(templateId: promise?.templateId, clearTemplateId: promise == null, scrolledToEnd: false, accepted: false);
      }
      state = next;
    } catch (e) {
      state = state.copyWith(loadingPreview: false, previewError: _message(e, 'Could not load the purchase details for this property.'));
    }
  }

  // ------------------------------------------------------------------ account

  /// The visitor now has an account: drop the account step, pre-fill what we learned (existing
  /// input wins) and re-render the agreement for the signed-in buyer.
  Future<void> accountReady({String? fullName, String? phone, String? email}) async {
    state = state.copyWith(
      needsAccount: false,
      step: WizardStep.contact,
      phone: state.phone.isEmpty && phone != null ? phone : null,
      email: state.email.isEmpty && email != null ? email : null,
      signatoryName: state.signatoryName.isEmpty && fullName != null ? fullName : null,
    );
    await loadPreview();
  }

  // ------------------------------------------------------------------ inputs

  void setPhone(String v) => state = state.copyWith(phone: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setMessage(String v) => state = state.copyWith(message: v);

  void setUseFinancing(bool v) => state = state.copyWith(useFinancing: v);

  void selectOffer(String offerId) {
    final offers = state.preview?.financingOffers ?? const [];
    for (final o in offers) {
      if (o.financingOfferId == offerId) {
        state = _withOffer(state, o, keepAmounts: false);
        return;
      }
    }
  }

  void setFinancedAmount(double amount) => state = state.copyWith(financedAmount: amount);

  /// Setting the cash portion is the same choice seen from the other side.
  void setDownPayment(double cash) {
    final price = state.preview?.listedPrice;
    if (price == null) return;
    state = state.copyWith(financedAmount: FinancingMath.round2(price - cash));
  }

  void setTenure(int months) => state = state.copyWith(tenureMonths: months);

  void setScrolledToEnd(bool v) => state = state.copyWith(scrolledToEnd: v);
  void setAccepted(bool v) => state = state.copyWith(accepted: v);
  void setSignatoryName(String v) => state = state.copyWith(signatoryName: v);

  // ------------------------------------------------------------------ navigation

  /// Never jumps past a step that is still invalid.
  void goTo(WizardStep target) {
    final steps = state.steps;
    final targetIndex = steps.indexOf(target);
    for (var i = 0; i < targetIndex; i++) {
      if (!state.isStepValid(steps[i])) {
        state = state.copyWith(step: steps[i]);
        return;
      }
    }
    state = state.copyWith(step: target);
  }

  bool next() {
    if (!state.isStepValid(state.step)) return false;
    final i = state.stepIndex;
    if (i < state.steps.length - 1) goTo(state.steps[i + 1]);
    return true;
  }

  void back() {
    final i = state.stepIndex;
    if (i > 0 && state.steps[i - 1] != WizardStep.account) state = state.copyWith(step: state.steps[i - 1]);
  }

  // ------------------------------------------------------------------ submit

  Future<PurchaseOrder?> submit() async {
    final payload = state.payload;
    if (!state.canSubmit || payload == null) {
      goTo(state.steps.firstWhere((s) => !state.isStepValid(s), orElse: () => WizardStep.review));
      return null;
    }
    state = state.copyWith(submitting: true, clearSubmitError: true, serverFieldErrors: const {});
    try {
      final order = await _service.create(payload);
      state = state.copyWith(submitting: false, createdOrder: order);
      return order;
    } catch (e) {
      final fieldErrors = <String, String>{};
      if (e is ValidationException && e.errors?['fieldErrors'] is List) {
        for (final fe in e.errors!['fieldErrors'] as List) {
          if (fe is Map) fieldErrors[fe['field'].toString()] = fe['message'].toString();
        }
      }
      final message = e.toString();
      if (message.contains('already have an open purchase order')) {
        state = state.copyWith(submitting: false, submitError: 'You already have an open purchase order for this property.');
      } else if (message.contains('Promise to Purchase agreement has changed')) {
        // The text changed under the buyer: reload it and make them read it again.
        state = state.copyWith(
          submitting: false,
          submitError: 'The agreement text was updated while you were reading. Please review and accept the new version.',
        );
        await loadPreview();
        goTo(WizardStep.agreement);
      } else {
        state = state.copyWith(
          submitting: false,
          submitError: _message(e, 'The purchase order could not be submitted. Please try again.'),
          serverFieldErrors: fieldErrors,
        );
      }
      return null;
    }
  }

  // ------------------------------------------------------------------ helpers

  static PurchaseFormState _withOffer(PurchaseFormState s, FinancingOption offer, {required bool keepAmounts}) {
    double amount = offer.maxFinanceableAmount;
    int tenure = offer.maxTenureMonths;
    if (keepAmounts && s.financedAmount != null) amount = FinancingMath.clampAmount(offer, s.financedAmount!);
    if (keepAmounts && s.tenureMonths != null) {
      tenure = s.tenureMonths!.clamp(offer.minTenureMonths, offer.maxTenureMonths);
    }
    return s.copyWith(selectedOfferId: offer.financingOfferId, financedAmount: amount, tenureMonths: tenure);
  }

  static String _message(Object e, String fallback) {
    if (e is ApiException) return e.message.isNotEmpty ? e.message : fallback;
    return fallback;
  }
}

/// One wizard per property visit.
final purchaseFormProvider = StateNotifierProvider.autoDispose.family<PurchaseFormNotifier, PurchaseFormState, String>(
  (ref, propertyId) => PurchaseFormNotifier(ref.read(purchaseServiceProvider), propertyId),
);
