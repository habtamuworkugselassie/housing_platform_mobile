/// Mirrors of the backend `purchase` module DTOs.

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
double? _dn(dynamic v) => v == null ? null : (v as num).toDouble();
int _i(dynamic v) => v == null ? 0 : (v as num).toInt();
int? _in(dynamic v) => v == null ? null : (v as num).toInt();
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

class FinancingOption {
  final String financingOfferId;
  final String bankId;
  final String? bankName;
  final String creditProductId;
  final String? creditProductName;
  final String offerLevel;
  final double interestRate;
  final double ltvRatio;
  final int minTenureMonths;
  final int maxTenureMonths;
  final double minFinanceableAmount;
  final double maxFinanceableAmount;
  final double minimumDownPayment;
  final bool partialFinancingAllowed;
  final bool recommended;

  const FinancingOption({
    required this.financingOfferId,
    required this.bankId,
    this.bankName,
    required this.creditProductId,
    this.creditProductName,
    required this.offerLevel,
    required this.interestRate,
    required this.ltvRatio,
    required this.minTenureMonths,
    required this.maxTenureMonths,
    required this.minFinanceableAmount,
    required this.maxFinanceableAmount,
    required this.minimumDownPayment,
    required this.partialFinancingAllowed,
    required this.recommended,
  });

  factory FinancingOption.fromJson(Map<String, dynamic> j) => FinancingOption(
        financingOfferId: j['financingOfferId'].toString(),
        bankId: j['bankId'].toString(),
        bankName: j['bankName'] as String?,
        creditProductId: j['creditProductId'].toString(),
        creditProductName: j['creditProductName'] as String?,
        offerLevel: j['offerLevel'] as String? ?? 'PROPERTY',
        interestRate: _d(j['interestRate']),
        ltvRatio: _d(j['ltvRatio']),
        minTenureMonths: _i(j['minTenureMonths']),
        maxTenureMonths: _i(j['maxTenureMonths']),
        minFinanceableAmount: _d(j['minFinanceableAmount']),
        maxFinanceableAmount: _d(j['maxFinanceableAmount']),
        minimumDownPayment: _d(j['minimumDownPayment']),
        partialFinancingAllowed: j['partialFinancingAllowed'] == true,
        recommended: j['recommended'] == true,
      );
}

class AgreementPreview {
  final String templateId;
  final String type;
  final int version;
  final String title;
  final String content;

  const AgreementPreview({required this.templateId, required this.type, required this.version, required this.title, required this.content});

  factory AgreementPreview.fromJson(Map<String, dynamic> j) => AgreementPreview(
        templateId: j['templateId'].toString(),
        type: j['type'] as String? ?? 'OTHER',
        version: _i(j['version']),
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
      );
}

class PurchasePreview {
  final String propertyId;
  final double listedPrice;
  final String currency;
  final String purchaseType;
  final bool financingAvailable;
  final List<FinancingOption> financingOffers;
  final List<AgreementPreview> agreementsToSign;

  /// The reservation deposit paid when placing the order; null when deposits are disabled.
  final DepositQuote? deposit;

  /// The provider's service fee (markup + VAT), due once the seller accepts; null when none.
  final FeeQuote? fees;

  /// Verified official documents (Annex A of the Promise to Purchase); signed-in users only.
  final List<PropertyDocumentItem> documents;

  const PurchasePreview({
    required this.propertyId,
    required this.listedPrice,
    required this.currency,
    required this.purchaseType,
    required this.financingAvailable,
    required this.financingOffers,
    required this.agreementsToSign,
    this.deposit,
    this.fees,
    this.documents = const [],
  });

  factory PurchasePreview.fromJson(Map<String, dynamic> j) => PurchasePreview(
        propertyId: j['propertyId'].toString(),
        listedPrice: _d(j['listedPrice']),
        currency: j['currency'] as String? ?? 'ETB',
        purchaseType: j['purchaseType'] as String? ?? 'CASH',
        financingAvailable: j['financingAvailable'] == true,
        financingOffers: (j['financingOffers'] as List? ?? []).map((e) => FinancingOption.fromJson(e as Map<String, dynamic>)).toList(),
        agreementsToSign: (j['agreementsToSign'] as List? ?? []).map((e) => AgreementPreview.fromJson(e as Map<String, dynamic>)).toList(),
        deposit: j['deposit'] == null ? null : DepositQuote.fromJson(j['deposit'] as Map<String, dynamic>),
        fees: j['fees'] == null ? null : FeeQuote.fromJson(j['fees'] as Map<String, dynamic>),
        documents: (j['documents'] as List? ?? []).map((e) => PropertyDocumentItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// How the buyer pays; each value steers Chapa's hosted checkout (card = every method).
class DepositMethods {
  DepositMethods._();
  static const all = ['TELEBIRR', 'CBE_BIRR', 'MPESA', 'AWASH_BIRR', 'CARD'];

  static String label(String m) => const {
        'TELEBIRR': 'telebirr',
        'CBE_BIRR': 'CBE Birr',
        'MPESA': 'M-Pesa',
        'AWASH_BIRR': 'Awash Birr',
        'CARD': 'Card or other method',
      }[m] ?? m;

  static String help(String m) => const {
        'TELEBIRR': 'Pay from your telebirr wallet',
        'CBE_BIRR': 'Pay from your CBE Birr wallet',
        'MPESA': 'Pay from your M-Pesa wallet',
        'AWASH_BIRR': 'Pay from your Awash Birr wallet',
        'CARD': 'Visa, Mastercard and every other method Chapa offers',
      }[m] ?? '';
}

class DepositQuote {
  final double amount;
  final String currency;
  final bool checkoutAvailable;
  final List<String> paymentMethods;

  /// When an ETB deposit is quoted in USD: the ETB amount and the rate (birr per USD).
  final double? baseAmount;
  final String? baseCurrency;
  final double? exchangeRate;

  /// The deposit in USD by international card, when that option is on.
  final double? usdAmount;

  const DepositQuote({
    required this.amount,
    required this.currency,
    required this.checkoutAvailable,
    this.paymentMethods = DepositMethods.all,
    this.baseAmount,
    this.baseCurrency,
    this.exchangeRate,
    this.usdAmount,
  });

  bool get converted => baseAmount != null && exchangeRate != null;

  factory DepositQuote.fromJson(Map<String, dynamic> j) => DepositQuote(
        amount: _d(j['amount']),
        currency: j['currency'] as String? ?? 'ETB',
        checkoutAvailable: j['checkoutAvailable'] == true,
        paymentMethods: List<String>.from(j['paymentMethods'] as List? ?? DepositMethods.all),
        baseAmount: _dn(j['baseAmount']),
        baseCurrency: j['baseCurrency'] as String?,
        exchangeRate: _dn(j['exchangeRate']),
        usdAmount: _dn(j['usdAmount']),
      );
}

class FeeQuote {
  final double markupPercent;
  final double markupAmount;
  final double vatRate;
  final double vatAmount;
  final double total;
  final String currency;

  const FeeQuote({
    required this.markupPercent,
    required this.markupAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    required this.currency,
  });

  factory FeeQuote.fromJson(Map<String, dynamic> j) => FeeQuote(
        markupPercent: _d(j['markupPercent']),
        markupAmount: _d(j['markupAmount']),
        vatRate: _d(j['vatRate']),
        vatAmount: _d(j['vatAmount']),
        total: _d(j['total']),
        currency: j['currency'] as String? ?? 'ETB',
      );
}

/// A verified official document of the property (title deed, lease contract, permit).
class PropertyDocumentItem {
  final String id;
  final String documentType;
  final String? documentNumber;
  final String? issuingAuthority;
  final String? issuedOn;
  final String fileName;
  final String? contentType;
  final String? sha256;

  const PropertyDocumentItem({
    required this.id,
    required this.documentType,
    this.documentNumber,
    this.issuingAuthority,
    this.issuedOn,
    required this.fileName,
    this.contentType,
    this.sha256,
  });

  bool get isImage => (contentType ?? '').startsWith('image/');

  static String typeLabel(String t) => const {
        'TITLE_DEED': 'Title deed / ownership certificate',
        'LEASE_AGREEMENT': 'Land lease contract',
        'BUILDING_PERMIT': 'Building permit',
        'OCCUPANCY_PERMIT': 'Occupancy permit',
      }[t] ?? 'Other document';

  factory PropertyDocumentItem.fromJson(Map<String, dynamic> j) => PropertyDocumentItem(
        id: j['id'].toString(),
        documentType: j['documentType'] as String? ?? 'OTHER',
        documentNumber: j['documentNumber'] as String?,
        issuingAuthority: j['issuingAuthority'] as String?,
        issuedOn: j['issuedOn']?.toString(),
        fileName: j['fileName'] as String? ?? 'document',
        contentType: j['contentType'] as String?,
        sha256: j['sha256'] as String?,
      );
}

class AgreementSignature {
  final String templateId;
  final bool accepted;
  final String signatoryFullName;
  const AgreementSignature({required this.templateId, required this.accepted, required this.signatoryFullName});
  Map<String, dynamic> toJson() => {'templateId': templateId, 'accepted': accepted, 'signatoryFullName': signatoryFullName};
}

class CreatePurchaseOrderRequest {
  final String propertyId;
  final String contactPhone;
  final String? contactEmail;
  final String? currency;
  final String? buyerMessage;
  /// null = automatic, false = cash even if financing exists, true = financing required.
  final bool? useFinancing;
  final String? financingOfferId;
  final double? financedAmount;
  final int? requestedTenureMonths;
  final AgreementSignature promiseToPurchase;

  /// Signs the Reservation Deposit Terms with the order so the deposit can be paid right away.
  final AgreementSignature? depositTerms;
  final String? depositPaymentMethod;

  /// 'USD' pays an ETB deposit by international card at the platform's rate.
  final String? depositCurrency;

  const CreatePurchaseOrderRequest({
    required this.propertyId,
    required this.contactPhone,
    this.contactEmail,
    this.currency,
    this.buyerMessage,
    this.useFinancing,
    this.financingOfferId,
    this.financedAmount,
    this.requestedTenureMonths,
    required this.promiseToPurchase,
    this.depositTerms,
    this.depositPaymentMethod,
    this.depositCurrency,
  });

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'contactPhone': contactPhone,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (currency != null) 'currency': currency,
        if (buyerMessage != null) 'buyerMessage': buyerMessage,
        if (useFinancing != null) 'useFinancing': useFinancing,
        if (financingOfferId != null)
          'financing': {
            'financingOfferId': financingOfferId,
            if (financedAmount != null) 'financedAmount': financedAmount,
            if (requestedTenureMonths != null) 'requestedTenureMonths': requestedTenureMonths,
          },
        'promiseToPurchase': promiseToPurchase.toJson(),
        if (depositTerms != null) 'depositTerms': depositTerms!.toJson(),
        if (depositPaymentMethod != null) 'depositPaymentMethod': depositPaymentMethod,
        if (depositCurrency != null) 'depositCurrency': depositCurrency,
      };
}

class PurchaseAgreement {
  final String id;
  final String templateId;
  final String type;
  final int templateVersion;
  final int sequence;
  final String title;
  final String? content;
  final String contentHash;
  final String status;
  final bool blocksCompletion;
  final DateTime? issuedAt;
  final String? buyerSignatoryName;
  final DateTime? buyerSignedAt;
  final String providerName;
  final String? providerSignatoryName;
  final String? providerSignatoryTitle;
  final DateTime? providerSignedAt;
  final String? voidReason;

  const PurchaseAgreement({
    required this.id,
    required this.templateId,
    required this.type,
    required this.templateVersion,
    required this.sequence,
    required this.title,
    this.content,
    required this.contentHash,
    required this.status,
    required this.blocksCompletion,
    this.issuedAt,
    this.buyerSignatoryName,
    this.buyerSignedAt,
    required this.providerName,
    this.providerSignatoryName,
    this.providerSignatoryTitle,
    this.providerSignedAt,
    this.voidReason,
  });

  bool get awaitingBuyer => status == 'PENDING_BUYER_SIGNATURE';
  bool get fullySigned => status == 'FULLY_SIGNED';

  factory PurchaseAgreement.fromJson(Map<String, dynamic> j) => PurchaseAgreement(
        id: j['id'].toString(),
        templateId: j['templateId'].toString(),
        type: j['type'] as String? ?? 'OTHER',
        templateVersion: _i(j['templateVersion']),
        sequence: _i(j['sequence']),
        title: j['title'] as String? ?? '',
        content: j['content'] as String?,
        contentHash: j['contentHash'] as String? ?? '',
        status: j['status'] as String? ?? '',
        blocksCompletion: j['blocksCompletion'] == true,
        issuedAt: _dt(j['issuedAt']),
        buyerSignatoryName: j['buyerSignatoryName'] as String?,
        buyerSignedAt: _dt(j['buyerSignedAt']),
        providerName: j['providerName'] as String? ?? '',
        providerSignatoryName: j['providerSignatoryName'] as String?,
        providerSignatoryTitle: j['providerSignatoryTitle'] as String?,
        providerSignedAt: _dt(j['providerSignedAt']),
        voidReason: j['voidReason'] as String?,
      );
}

class FinancingDetails {
  final String financingStatus;
  final String? bankName;
  final String? creditProductName;
  final double appliedInterestRate;
  final double appliedLtvRatio;
  final double minFinanceableAmount;
  final double maxFinanceableAmount;
  final String financingMode;
  final double financedAmount;
  final double cashPortionAmount;
  final double financingCoverageRatio;
  final int tenureMonths;
  final double? estimatedMonthlyInstallment;
  final double? approvedAmount;
  final double? proposedCashPortionAmount;
  final List<String> nextSteps;

  const FinancingDetails({
    required this.financingStatus,
    this.bankName,
    this.creditProductName,
    required this.appliedInterestRate,
    required this.appliedLtvRatio,
    required this.minFinanceableAmount,
    required this.maxFinanceableAmount,
    required this.financingMode,
    required this.financedAmount,
    required this.cashPortionAmount,
    required this.financingCoverageRatio,
    required this.tenureMonths,
    this.estimatedMonthlyInstallment,
    this.approvedAmount,
    this.proposedCashPortionAmount,
    required this.nextSteps,
  });

  factory FinancingDetails.fromJson(Map<String, dynamic> j) => FinancingDetails(
        financingStatus: j['financingStatus'] as String? ?? '',
        bankName: j['bankName'] as String?,
        creditProductName: j['creditProductName'] as String?,
        appliedInterestRate: _d(j['appliedInterestRate']),
        appliedLtvRatio: _d(j['appliedLtvRatio']),
        minFinanceableAmount: _d(j['minFinanceableAmount']),
        maxFinanceableAmount: _d(j['maxFinanceableAmount']),
        financingMode: j['financingMode'] as String? ?? 'MAXIMUM',
        financedAmount: _d(j['financedAmount']),
        cashPortionAmount: _d(j['cashPortionAmount']),
        financingCoverageRatio: _d(j['financingCoverageRatio']),
        tenureMonths: _i(j['tenureMonths']),
        estimatedMonthlyInstallment: _dn(j['estimatedMonthlyInstallment']),
        approvedAmount: _dn(j['approvedAmount']),
        proposedCashPortionAmount: _dn(j['proposedCashPortionAmount']),
        nextSteps: List<String>.from(j['nextSteps'] as List? ?? const []),
      );
}

class StatusHistoryEntry {
  final String? fromStatus;
  final String toStatus;
  final DateTime? changedAt;
  final String? notes;
  const StatusHistoryEntry({this.fromStatus, required this.toStatus, this.changedAt, this.notes});
  factory StatusHistoryEntry.fromJson(Map<String, dynamic> j) => StatusHistoryEntry(
        fromStatus: j['fromStatus'] as String?,
        toStatus: j['toStatus'] as String? ?? '',
        changedAt: _dt(j['changedAt']),
        notes: j['notes'] as String?,
      );
}

/// Reservation deposit owed to the provider, paid when the order is placed.
class PurchaseDeposit {
  final double amount;
  final String currency;
  final String status;
  final DateTime? dueAt;
  final String provider;
  final String? txRef;
  final String? checkoutUrl;
  final String? providerReference;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? failureReason;
  final int attempts;
  final bool termsPending;
  final bool checkoutAvailable;
  final String? refundReference;
  final String? waiveReason;

  /// The method the buyer picked on our side, if any.
  final String? preferredMethod;

  /// Set when an ETB deposit was paid in USD: the ETB amount and the rate used.
  final double? baseAmount;
  final String? baseCurrency;
  final double? exchangeRate;

  const PurchaseDeposit({
    required this.amount,
    required this.currency,
    required this.status,
    this.dueAt,
    required this.provider,
    this.txRef,
    this.checkoutUrl,
    this.providerReference,
    this.paymentMethod,
    this.paidAt,
    this.failureReason,
    required this.attempts,
    required this.termsPending,
    required this.checkoutAvailable,
    this.refundReference,
    this.waiveReason,
    this.preferredMethod,
    this.baseAmount,
    this.baseCurrency,
    this.exchangeRate,
  });

  bool get isSettled => status == 'PAID' || status == 'WAIVED';
  bool get isPayable => status == 'DUE' || status == 'PENDING' || status == 'FAILED';

  factory PurchaseDeposit.fromJson(Map<String, dynamic> j) => PurchaseDeposit(
        amount: _d(j['amount']),
        currency: j['currency'] as String? ?? 'ETB',
        status: j['status'] as String? ?? 'DUE',
        dueAt: _dt(j['dueAt']),
        provider: j['provider'] as String? ?? 'CHAPA',
        txRef: j['txRef'] as String?,
        checkoutUrl: j['checkoutUrl'] as String?,
        providerReference: j['providerReference'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        paidAt: _dt(j['paidAt']),
        failureReason: j['failureReason'] as String?,
        attempts: _in(j['attempts']) ?? 0,
        termsPending: j['termsPending'] == true,
        checkoutAvailable: j['checkoutAvailable'] == true,
        refundReference: j['refundReference'] as String?,
        waiveReason: j['waiveReason'] as String?,
        preferredMethod: j['preferredMethod'] as String?,
        baseAmount: _dn(j['baseAmount']),
        baseCurrency: j['baseCurrency'] as String?,
        exchangeRate: _dn(j['exchangeRate']),
      );
}

class DepositCheckout {
  final String checkoutUrl;
  final String txRef;
  const DepositCheckout({required this.checkoutUrl, required this.txRef});
  factory DepositCheckout.fromJson(Map<String, dynamic> j) =>
      DepositCheckout(checkoutUrl: j['checkoutUrl'] as String, txRef: j['txRef']?.toString() ?? '');
}

class PurchaseOrder {
  final String id;
  final String orderNumber;
  final String status;
  final String purchaseType;
  final String propertyId;
  final String? propertyTitle;
  final String? propertyCity;
  final String? realEstateCompanyName;
  final String contactPhone;
  final String? contactEmail;
  final double listedPrice;
  final String currency;
  final FinancingDetails? financing;
  final String? buyerMessage;
  final DateTime? expiresAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final List<String> warnings;
  final List<PurchaseAgreement> agreements;
  final int pendingSignatures;
  final PurchaseDeposit? deposit;
  final DateTime? createdAt;
  final List<StatusHistoryEntry> statusHistory;

  const PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.purchaseType,
    required this.propertyId,
    this.propertyTitle,
    this.propertyCity,
    this.realEstateCompanyName,
    required this.contactPhone,
    this.contactEmail,
    required this.listedPrice,
    required this.currency,
    this.financing,
    this.buyerMessage,
    this.expiresAt,
    this.cancellationReason,
    this.rejectionReason,
    required this.warnings,
    required this.agreements,
    required this.pendingSignatures,
    this.deposit,
    this.createdAt,
    required this.statusHistory,
  });

  static const openStatuses = {
    'PENDING_SELLER_REVIEW',
    'AWAITING_FINANCING',
    'FINANCING_APPROVED',
    'FINANCING_PARTIALLY_APPROVED',
    'FINANCING_REJECTED',
    'AWAITING_PAYMENT',
  };

  bool get isOpen => openStatuses.contains(status);
  bool get isFinanced => purchaseType == 'BANK_FINANCED';

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) {
    final property = j['property'] as Map<String, dynamic>? ?? const {};
    final buyer = j['buyer'] as Map<String, dynamic>? ?? const {};
    final pricing = j['pricing'] as Map<String, dynamic>? ?? const {};
    return PurchaseOrder(
      id: j['id'].toString(),
      orderNumber: j['orderNumber'] as String? ?? '',
      status: j['status'] as String? ?? '',
      purchaseType: j['purchaseType'] as String? ?? 'CASH',
      propertyId: property['id']?.toString() ?? '',
      propertyTitle: property['title'] as String?,
      propertyCity: property['city'] as String?,
      realEstateCompanyName: property['realEstateCompanyName'] as String?,
      contactPhone: buyer['contactPhone'] as String? ?? '',
      contactEmail: buyer['contactEmail'] as String?,
      listedPrice: _d(pricing['listedPrice']),
      currency: pricing['currency'] as String? ?? 'ETB',
      financing: j['financing'] == null ? null : FinancingDetails.fromJson(j['financing'] as Map<String, dynamic>),
      buyerMessage: j['buyerMessage'] as String?,
      expiresAt: _dt(j['expiresAt']),
      cancellationReason: j['cancellationReason'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      warnings: List<String>.from(j['warnings'] as List? ?? const []),
      agreements: (j['agreements'] as List? ?? []).map((e) => PurchaseAgreement.fromJson(e as Map<String, dynamic>)).toList(),
      pendingSignatures: _in(j['pendingSignatures']) ?? 0,
      deposit: j['deposit'] == null ? null : PurchaseDeposit.fromJson(j['deposit'] as Map<String, dynamic>),
      createdAt: _dt(j['createdAt']),
      statusHistory: (j['statusHistory'] as List? ?? []).map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Human labels for the order state machine.
class PurchaseOrderLabels {
  PurchaseOrderLabels._();

  static String status(String s) => const {
        'PENDING_SELLER_REVIEW': 'Awaiting seller review',
        'AWAITING_FINANCING': 'Awaiting bank decision',
        'FINANCING_APPROVED': 'Financing approved',
        'FINANCING_PARTIALLY_APPROVED': 'Financing partially approved',
        'FINANCING_REJECTED': 'Financing declined',
        'AWAITING_PAYMENT': 'Awaiting payment',
        'COMPLETED': 'Completed',
        'CANCELLED': 'Cancelled',
        'REJECTED': 'Rejected by seller',
        'EXPIRED': 'Expired',
      }[s] ?? s;

  static String statusHelp(String s) => const {
        'PENDING_SELLER_REVIEW': 'Your order has been sent to the seller. They can accept or decline it.',
        'AWAITING_FINANCING': 'The seller accepted. The bank is now reviewing your loan application.',
        'FINANCING_APPROVED': 'The bank approved your financing. Pay your share of the balance below.',
        'FINANCING_PARTIALLY_APPROVED': 'The bank approved a smaller loan than requested. Decide how to proceed below.',
        'FINANCING_REJECTED': 'The bank declined the loan. You can re-apply for less, continue without a loan, or cancel.',
        'AWAITING_PAYMENT': 'Pay the service fee and the balance below. The seller completes the sale once everything is paid.',
        'COMPLETED': 'The sale is complete. Congratulations!',
        'CANCELLED': 'You cancelled this order.',
        'REJECTED': 'The seller declined this order.',
        'EXPIRED': 'The seller did not respond in time and the order expired.',
      }[s] ?? '';

  static String financingStatus(String s) => const {
        'APPLICATION_SUBMITTED': 'Application submitted',
        'UNDER_REVIEW': 'Under review',
        'APPROVED': 'Approved',
        'PARTIALLY_APPROVED': 'Partially approved',
        'REJECTED': 'Declined',
        'DISBURSED': 'Disbursed',
        'WITHDRAWN': 'Withdrawn',
      }[s] ?? s;

  static String agreementStatus(String s) => const {
        'PENDING_BUYER_SIGNATURE': 'Awaiting your signature',
        'PENDING_PROVIDER_SIGNATURE': 'Awaiting provider signature',
        'FULLY_SIGNED': 'Signed',
        'VOID': 'Void',
      }[s] ?? s;

  static String purchaseType(String s) => s == 'BANK_FINANCED' ? 'Bank financed' : 'Direct purchase';

  static String depositStatus(String s) => const {
        'DUE': 'Due',
        'PENDING': 'Payment in progress',
        'PAID': 'Paid',
        'FAILED': 'Payment failed',
        'CANCELLED': 'Cancelled',
        'WAIVED': 'Waived',
        'REFUND_PENDING': 'Refund pending',
        'REFUNDED': 'Refunded',
      }[s] ?? s;
}

// ---------------------------------------------------------------- balance and service fee

class BalanceInstalment {
  final int sequence;
  final String label;
  final double amount;
  final String? dueDate;
  final double covered;
  final bool paid;
  final bool overdue;

  const BalanceInstalment({
    required this.sequence,
    required this.label,
    required this.amount,
    this.dueDate,
    required this.covered,
    required this.paid,
    required this.overdue,
  });

  factory BalanceInstalment.fromJson(Map<String, dynamic> j) => BalanceInstalment(
        sequence: _i(j['sequence']),
        label: j['label'] as String? ?? '',
        amount: _d(j['amount']),
        dueDate: j['dueDate']?.toString(),
        covered: _d(j['covered']),
        paid: j['paid'] == true,
        overdue: j['overdue'] == true,
      );
}

class BalancePayment {
  final String id;
  final String channel;
  final String purpose;
  final String status;
  final double amount;
  final String currency;
  final String? checkoutUrl;
  final String? preferredMethod;
  final String? paymentMethod;
  final String? reference;
  final String? paidOn;
  final bool hasSlip;
  final String? note;
  final DateTime? createdAt;

  const BalancePayment({
    required this.id,
    required this.channel,
    required this.purpose,
    required this.status,
    required this.amount,
    required this.currency,
    this.checkoutUrl,
    this.preferredMethod,
    this.paymentMethod,
    this.reference,
    this.paidOn,
    this.hasSlip = false,
    this.note,
    this.createdAt,
  });

  factory BalancePayment.fromJson(Map<String, dynamic> j) => BalancePayment(
        id: j['id'].toString(),
        channel: j['channel'] as String? ?? 'ONLINE',
        purpose: j['purpose'] as String? ?? 'BALANCE',
        status: j['status'] as String? ?? '',
        amount: _d(j['amount']),
        currency: j['currency'] as String? ?? 'ETB',
        checkoutUrl: j['checkoutUrl'] as String?,
        preferredMethod: j['preferredMethod'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        reference: j['reference'] as String?,
        paidOn: j['paidOn']?.toString(),
        hasSlip: j['hasSlip'] == true,
        note: j['note'] as String?,
        createdAt: _dt(j['createdAt']),
      );
}

class ProviderBankAccount {
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? branch;
  const ProviderBankAccount({this.bankName, this.accountName, this.accountNumber, this.branch});
  factory ProviderBankAccount.fromJson(Map<String, dynamic> j) => ProviderBankAccount(
        bankName: j['bankName'] as String?,
        accountName: j['accountName'] as String?,
        accountNumber: j['accountNumber'] as String?,
        branch: j['branch'] as String?,
      );
}

class BalanceFees {
  final double markupPercent;
  final double markupAmount;
  final double vatRate;
  final double vatAmount;
  final double total;
  final double paid;
  final double inProgress;
  final double remaining;
  final bool fullyPaid;

  const BalanceFees({
    required this.markupPercent,
    required this.markupAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    required this.paid,
    required this.inProgress,
    required this.remaining,
    required this.fullyPaid,
  });

  /// What can be paid now: remaining minus payments waiting for Chapa or a confirmation.
  double get room => (remaining - inProgress).clamp(0, double.infinity).toDouble();

  factory BalanceFees.fromJson(Map<String, dynamic> j) => BalanceFees(
        markupPercent: _d(j['markupPercent']),
        markupAmount: _d(j['markupAmount']),
        vatRate: _d(j['vatRate']),
        vatAmount: _d(j['vatAmount']),
        total: _d(j['total']),
        paid: _d(j['paid']),
        inProgress: _d(j['inProgress']),
        remaining: _d(j['remaining']),
        fullyPaid: j['fullyPaid'] == true,
      );
}

/// The balance of an order (price − deposit − loan) and the service fee, paid to the provider
/// once the seller accepts: online through Chapa in parts, or by bank transfer with a receipt.
class PurchaseBalance {
  final String currency;
  final double listedPrice;
  final double depositCredit;
  final double loanAmount;
  final double balanceDue;
  final double paid;
  final double inProgress;
  final double remaining;
  final bool fullyPaid;
  final bool payable;
  final bool checkoutAvailable;

  /// The most one online payment may be (Chapa's limit); null when none is set.
  final double? onlineMaxPerPayment;
  final List<String> paymentMethods;
  final ProviderBankAccount? bankAccount;
  final String transferReference;
  final List<BalanceInstalment> instalments;
  final List<BalancePayment> payments;
  final BalanceFees? fees;

  const PurchaseBalance({
    required this.currency,
    required this.listedPrice,
    required this.depositCredit,
    required this.loanAmount,
    required this.balanceDue,
    required this.paid,
    required this.inProgress,
    required this.remaining,
    required this.fullyPaid,
    required this.payable,
    required this.checkoutAvailable,
    this.onlineMaxPerPayment,
    required this.paymentMethods,
    this.bankAccount,
    required this.transferReference,
    required this.instalments,
    required this.payments,
    this.fees,
  });

  double get room => (remaining - inProgress).clamp(0, double.infinity).toDouble();

  factory PurchaseBalance.fromJson(Map<String, dynamic> j) => PurchaseBalance(
        currency: j['currency'] as String? ?? 'ETB',
        listedPrice: _d(j['listedPrice']),
        depositCredit: _d(j['depositCredit']),
        loanAmount: _d(j['loanAmount']),
        balanceDue: _d(j['balanceDue']),
        paid: _d(j['paid']),
        inProgress: _d(j['inProgress']),
        remaining: _d(j['remaining']),
        fullyPaid: j['fullyPaid'] == true,
        payable: j['payable'] == true,
        checkoutAvailable: j['checkoutAvailable'] == true,
        onlineMaxPerPayment: _dn(j['onlineMaxPerPayment']),
        paymentMethods: List<String>.from(j['paymentMethods'] as List? ?? DepositMethods.all),
        bankAccount: j['bankAccount'] == null ? null : ProviderBankAccount.fromJson(j['bankAccount'] as Map<String, dynamic>),
        transferReference: j['transferReference'] as String? ?? '',
        instalments: (j['instalments'] as List? ?? []).map((e) => BalanceInstalment.fromJson(e as Map<String, dynamic>)).toList(),
        payments: (j['payments'] as List? ?? []).map((e) => BalancePayment.fromJson(e as Map<String, dynamic>)).toList(),
        fees: j['fees'] == null ? null : BalanceFees.fromJson(j['fees'] as Map<String, dynamic>),
      );

  static String paymentStatus(String s) => const {
        'PENDING': 'Waiting for Chapa',
        'SUBMITTED': 'Awaiting confirmation',
        'PAID': 'Paid',
        'FAILED': 'Failed',
        'REJECTED': 'Rejected',
        'CANCELLED': 'Cancelled',
        'REFUND_PENDING': 'Refund due',
        'REFUNDED': 'Refunded',
      }[s] ?? s;

  static String channel(String c) => const {
        'ONLINE': 'Online',
        'BANK_TRANSFER': 'Bank transfer',
        'RECORDED': 'Recorded by seller',
      }[c] ?? c;
}
