import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/purchase_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/financing_math.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/utils/simple_markdown.dart';
import '../widgets/agreement_review_panel.dart';
import '../widgets/balance_section.dart';
import '../widgets/purchase_payment_widgets.dart';
import '../widgets/purchase_status_badge.dart';

/// One purchase order: status, financing decisions, agreements to review or sign, history.
class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  final bool justCreated;

  /// The deposit checkout was just opened from the order form: confirm it when the app resumes.
  final bool checkoutOpened;
  const PurchaseOrderDetailScreen({super.key, required this.orderId, this.justCreated = false, this.checkoutOpened = false});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends ConsumerState<PurchaseOrderDetailScreen> with WidgetsBindingObserver {
  PurchaseOrder? _order;
  bool _checkoutOpen = false;
  String? _depositOutcome;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  /// The method for the next deposit checkout; defaults to the one picked when ordering.
  String? _depositMethod;
  List<PropertyDocumentItem> _documents = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkoutOpen = widget.checkoutOpened;
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the provider's checkout in the browser: ask the server what happened.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutOpen) {
      _checkoutOpen = false;
      _confirmDeposit();
    }
  }

  Future<void> _payDeposit() async {
    setState(() => _acting = true);
    try {
      final pending = _order!.deposit?.status == 'PENDING';
      final checkout = await ref.read(purchaseServiceProvider).startDepositCheckout(_order!.id, paymentMethod: pending ? null : _depositMethod);
      final uri = Uri.parse(checkout.checkoutUrl);
      _checkoutOpen = true;
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _checkoutOpen = false;
        throw const ServerException('Could not open the payment page.');
      }
    } catch (e) {
      _checkoutOpen = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Could not start the payment.'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmDeposit() async {
    if (_order?.deposit == null) return;
    setState(() => _acting = true);
    try {
      final deposit = await ref.read(purchaseServiceProvider).confirmDeposit(_order!.id);
      if (!mounted) return;
      setState(() {
        _depositOutcome = deposit.status == 'PAID' ? 'paid' : deposit.status == 'FAILED' ? 'failed' : 'pending';
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Could not confirm the payment yet.'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ref.read(purchaseServiceProvider).getById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _depositMethod ??= order.deposit?.currency == 'USD' ? 'CARD' : order.deposit?.preferredMethod;
        });
      }
      // Documents are secondary: the order still shows if they fail to load.
      ref.read(purchaseServiceProvider).orderDocuments(order.id).then((docs) {
        if (mounted) setState(() => _documents = docs);
      }).catchError((_) {});
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Could not load the purchase order.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<PurchaseOrder> Function() fn) async {
    setState(() => _acting = true);
    try {
      final order = await fn();
      if (mounted) setState(() => _order = order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'The action could not be completed.'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel purchase order?'),
        content: const Text('Any pending loan application will be withdrawn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel order', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (ok == true) await _act(() => ref.read(purchaseServiceProvider).cancel(_order!.id));
  }

  Future<void> _reapply() async {
    final f = _order!.financing!;
    final controller = TextEditingController(text: (f.financedAmount * 0.8).clamp(f.minFinanceableAmount, f.financedAmount - 1).toStringAsFixed(0));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-apply for a smaller amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New financed amount (${_order!.currency})',
            helperText: 'Between ${FinancingMath.formatMoney(f.minFinanceableAmount)} and ${FinancingMath.formatMoney(f.financedAmount - 1)}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)), child: const Text('Re-apply')),
        ],
      ),
    );
    if (amount != null) await _act(() => ref.read(purchaseServiceProvider).updateFinancing(_order!.id, financedAmount: amount));
  }

  Future<void> _openAgreement(PurchaseAgreement summary) async {
    final service = ref.read(purchaseServiceProvider);
    final full = await service.getAgreement(_order!.id, summary.id);
    if (!mounted) return;
    final signed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AgreementSheet(orderId: _order!.id, agreement: full),
    );
    if (signed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(order?.orderNumber ?? 'Purchase order'), backgroundColor: Colors.white, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: const TextStyle(color: AppTheme.error)), TextButton(onPressed: _load, child: const Text('Try again'))])))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (widget.justCreated) _banner(order!),
                      _card(children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(order!.propertyTitle ?? 'Property', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                                if (order.propertyCity != null) Text(order.propertyCity!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              PurchaseStatusBadge(order.status),
                              const SizedBox(height: 4),
                              Text(PurchaseOrderLabels.purchaseType(order.purchaseType), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(PurchaseOrderLabels.statusHelp(order.status), style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        if (order.expiresAt != null && order.status == 'PENDING_SELLER_REVIEW')
                          Padding(padding: const EdgeInsets.only(top: 4), child: Text('The seller has until ${_date(order.expiresAt)} to respond.', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                        const Divider(height: 24),
                        _kv('Listed price', FinancingMath.formatMoney(order.listedPrice, currency: order.currency)),
                        _kv('Your phone', PhoneNumber.display(order.contactPhone)),
                        _kv('Your email', order.contactEmail ?? 'No email provided'),
                        if (order.realEstateCompanyName != null) _kv('Seller', order.realEstateCompanyName!),
                      ]),
                      if (order.financing != null) _financingCard(order),
                      if (order.deposit != null) _depositCard(order),
                      BalanceSection(key: ValueKey('balance-${order.id}-${order.status}'), orderId: order.id),
                      _card(children: [
                        PropertyDocumentsList(
                          documents: _documents,
                          loadFile: (d) => ref.read(purchaseServiceProvider).orderDocumentFile(order.id, d.id),
                        ),
                      ]),
                      _agreementsCard(order),
                      _historyCard(order),
                      if (order.isOpen)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          child: OutlinedButton(
                            onPressed: _acting ? null : _cancel,
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Cancel purchase order'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _banner(PurchaseOrder order) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle, color: Color(0xFF047857)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Purchase order ${order.orderNumber} placed', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
              const Text('The seller has been notified. You will hear from them through the app and the contact details you provided.', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
              for (final w in order.warnings) Text('• $w', style: const TextStyle(fontSize: 12, color: Color(0xFF92400E))),
            ]),
          ),
        ]),
      );

  Widget _financingCard(PurchaseOrder order) {
    final f = order.financing!;
    final c = order.currency;
    return _card(title: 'Bank financing', children: [
      _kv('Bank', f.bankName ?? '—'),
      _kv('Product', f.creditProductName ?? '—'),
      _kv('Status', PurchaseOrderLabels.financingStatus(f.financingStatus)),
      _kv('Financed amount', FinancingMath.formatMoney(f.financedAmount, currency: c)),
      _kv('Your own contribution', FinancingMath.formatMoney(f.cashPortionAmount, currency: c)),
      _kv('Coverage', '${(f.financingCoverageRatio * 100).toStringAsFixed(1)}% · ${f.financingMode == 'MAXIMUM' ? 'maximum' : 'partial'}'),
      _kv('Interest rate', '${f.appliedInterestRate}%'),
      _kv('Repayment period', '${f.tenureMonths} months'),
      if (f.estimatedMonthlyInstallment != null) _kv('Est. instalment', FinancingMath.formatMoney(f.estimatedMonthlyInstallment!, currency: c)),
      if (order.status == 'FINANCING_PARTIALLY_APPROVED') ...[
        const SizedBox(height: 10),
        _notice(
          'The bank approved less than you requested',
          'Approved loan: ${FinancingMath.formatMoney(f.approvedAmount ?? 0, currency: c)}. If you accept, your own contribution becomes ${FinancingMath.formatMoney(f.proposedCashPortionAmount ?? 0, currency: c)}.',
          actions: [
            ElevatedButton(onPressed: _acting ? null : () => _act(() => ref.read(purchaseServiceProvider).acceptPartialApproval(order.id)), child: const Text('Accept and continue')),
            OutlinedButton(onPressed: _acting ? null : () => _act(() => ref.read(purchaseServiceProvider).convertToCash(order.id)), child: const Text('Continue without a loan')),
          ],
        ),
      ],
      if (order.status == 'FINANCING_REJECTED') ...[
        const SizedBox(height: 10),
        _notice(
          'Financing was declined',
          'You can apply again for a smaller amount, continue without a loan, or cancel the order.',
          actions: [
            ElevatedButton(onPressed: _acting ? null : _reapply, child: const Text('Re-apply for less')),
            OutlinedButton(onPressed: _acting ? null : () => _act(() => ref.read(purchaseServiceProvider).convertToCash(order.id)), child: const Text('Continue without a loan')),
          ],
        ),
      ],
      if (f.nextSteps.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Next steps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
        for (final s in f.nextSteps) Text('• $s', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    ]);
  }

  Widget _depositCard(PurchaseOrder order) {
    final d = order.deposit!;
    final providerName = order.agreements.isNotEmpty ? order.agreements.first.providerName : 'the provider';
    final paidStyle = d.isSettled;
    return _card(
      title: 'Reservation deposit',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: paidStyle ? const Color(0xFFD1FAE5) : d.status == 'FAILED' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(PurchaseOrderLabels.depositStatus(d.status),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: paidStyle ? const Color(0xFF047857) : d.status == 'FAILED' ? const Color(0xFFB91C1C) : const Color(0xFF92400E))),
      ),
      children: [
        Text('Paid to $providerName to reserve the property while the sale is arranged. Refund rules are in the deposit terms.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Text(FinancingMath.formatMoney(d.amount, currency: d.currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        if (d.baseAmount != null && d.exchangeRate != null)
          Text('Equivalent to ${FinancingMath.formatMoney(d.baseAmount!, currency: d.baseCurrency ?? 'ETB')} at ${d.exchangeRate} birr per US dollar',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        if (d.dueAt != null && (d.status == 'DUE' || d.status == 'FAILED'))
          Text('Due by ${_date(d.dueAt)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        if (d.paidAt != null) Text('Paid ${_date(d.paidAt)} via ${d.paymentMethod ?? d.provider}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        if (_depositOutcome != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _depositOutcome == 'paid' ? const Color(0xFFD1FAE5) : _depositOutcome == 'failed' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _depositOutcome == 'paid'
                  ? 'Your reservation deposit has been received. Thank you!'
                  : _depositOutcome == 'failed'
                      ? 'The payment did not go through. You can try again.'
                      : 'The provider has not confirmed the payment yet. Check again in a moment.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
        if (d.status == 'FAILED' && d.failureReason != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(d.failureReason!, style: const TextStyle(fontSize: 12, color: AppTheme.error))),
        if (d.isPayable && order.isOpen) ...[
          const SizedBox(height: 10),
          if (d.termsPending)
            _notice('Sign the Reservation Deposit Terms first', 'Review and sign the deposit terms in the agreements below before paying.', actions: const [])
          else if (!d.checkoutAvailable)
            const Text('Online payment is not available yet. The provider will contact you with payment instructions.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
          else ...[
            // A pending checkout resumes as it was started; otherwise the buyer can change the method.
            if (d.status != 'PENDING') ...[
              const Text('Pay the deposit with', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              DepositMethodPicker(
                methods: d.currency == 'USD' ? const ['CARD'] : DepositMethods.all,
                selected: _depositMethod,
                onChanged: _acting ? null : (m) => setState(() => _depositMethod = m),
              ),
            ],
            ElevatedButton.icon(
              key: const Key('pay-deposit'),
              onPressed: _acting || (d.status != 'PENDING' && _depositMethod == null) ? null : _payDeposit,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(d.status == 'PENDING' ? 'Continue payment' : d.status == 'FAILED' ? 'Try again' : 'Pay deposit'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            if (d.status == 'PENDING')
              TextButton(onPressed: _acting ? null : _confirmDeposit, child: const Text('I have paid — check status', style: TextStyle(fontSize: 12))),
            const Text("You will be taken to Chapa's secure checkout in your browser. Card details are entered there and are never stored on this platform.",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ],
      ],
    );
  }

  Widget _agreementsCard(PurchaseOrder order) => _card(
        title: 'Agreements',
        trailing: order.pendingSignatures > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(999)),
                child: Text('${order.pendingSignatures} to sign', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
              )
            : null,
        children: [
          for (final a in order.agreements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
              subtitle: Text(
                'version ${a.templateVersion} · ${a.providerName}${a.buyerSignedAt != null ? ' · signed ${_date(a.buyerSignedAt)}' : ''}\n${PurchaseOrderLabels.agreementStatus(a.status)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              isThreeLine: true,
              trailing: TextButton(onPressed: () => _openAgreement(a), child: Text(a.awaitingBuyer ? 'Review & sign' : 'View')),
            ),
        ],
      );

  Widget _historyCard(PurchaseOrder order) => _card(title: 'History', children: [
        for (final h in order.statusHistory.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 8, color: AppTheme.primaryColor)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(PurchaseOrderLabels.status(h.toStatus), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                  Text('${_date(h.changedAt)}${h.notes != null ? ' · ${h.notes}' : ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ),
            ]),
          ),
      ]);

  Widget _card({String? title, Widget? trailing, required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                if (trailing != null) trailing,
              ]),
            ),
          ...children,
        ]),
      );

  Widget _notice(String title, String body, {required List<Widget> actions}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFF78350F))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ]),
      );

  static Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
      );

  static String _date(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

class _AgreementSheet extends ConsumerStatefulWidget {
  final String orderId;
  final PurchaseAgreement agreement;
  const _AgreementSheet({required this.orderId, required this.agreement});

  @override
  ConsumerState<_AgreementSheet> createState() => _AgreementSheetState();
}

class _AgreementSheetState extends ConsumerState<_AgreementSheet> {
  bool _scrolled = false;
  bool _accepted = false;
  String _name = '';
  bool _attempted = false;
  bool _busy = false;
  String? _error;

  Future<void> _sign() async {
    setState(() => _attempted = true);
    if (!_scrolled || !_accepted || _name.trim().length < 3) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(purchaseServiceProvider).signAgreement(
            widget.orderId,
            widget.agreement.id,
            AgreementSignature(templateId: widget.agreement.templateId, accepted: true, signatoryFullName: _name.trim()),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'The action could not be completed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.agreement;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          if (a.awaitingBuyer)
            AgreementReviewPanel(
              title: a.title,
              content: a.content ?? '',
              version: a.templateVersion,
              providerName: a.providerName,
              scrolledToEnd: _scrolled,
              accepted: _accepted,
              signatoryName: _name,
              attempted: _attempted,
              enabled: !_busy,
              onScrolledToEnd: (v) => setState(() => _scrolled = v),
              onAccepted: (v) => setState(() => _accepted = v),
              onSignatoryName: (v) => setState(() => _name = v),
              maxHeight: 360,
            )
          else ...[
            Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(14)),
              child: SimpleMarkdown(a.content ?? '', baseStyle: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Document fingerprint (SHA-256): ${a.contentHash}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace')),
              if (a.buyerSignedAt != null) Text('Signed by ${a.buyerSignatoryName}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              if (a.providerSignedAt != null) Text('Signed for ${a.providerName} by ${a.providerSignatoryName}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: AppTheme.error))),
          if (a.awaitingBuyer) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _sign,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign agreement', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
