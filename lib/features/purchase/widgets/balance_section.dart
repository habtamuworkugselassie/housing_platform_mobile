import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/purchase_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import 'purchase_form_steps.dart' show money, fieldDecoration;
import 'purchase_payment_widgets.dart';

/// The rest of the price (price − deposit − loan) and the provider's service fee, paid once the
/// seller accepts: online through Chapa in as many parts as wallet or card limits need, or by
/// bank transfer with a photo of the receipt that the seller or an admin confirms.
class BalanceSection extends ConsumerStatefulWidget {
  final String orderId;

  /// Lets tests pick a receipt without the platform image picker.
  final Future<XFile?> Function()? pickReceipt;
  final Future<bool> Function(Uri url)? openUrl;
  const BalanceSection({super.key, required this.orderId, this.pickReceipt, this.openUrl});

  @override
  ConsumerState<BalanceSection> createState() => _BalanceSectionState();
}

class _BalanceSectionState extends ConsumerState<BalanceSection> with WidgetsBindingObserver {
  PurchaseBalance? _balance;
  bool _busy = false;
  bool _checkoutOpen = false;
  String? _error;
  String? _outcome;
  String _purpose = 'BALANCE';
  bool _transfer = false;
  String? _method;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  XFile? _receipt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(first: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  /// Back from Chapa in the browser: settle the pending online payments.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutOpen) {
      _checkoutOpen = false;
      _confirm();
    }
  }

  double get _feesRoom => _balance?.fees?.room ?? 0;
  double get _balanceRoom => _balance?.room ?? 0;
  double get _room => _purpose == 'FEES' ? _feesRoom : _balanceRoom;

  void _set(PurchaseBalance b, {bool first = false}) {
    _balance = b;
    // Open with the service fee while it is due; afterwards keep the buyer's choice when possible.
    if (first && b.fees != null && _feesRoom > 0) _purpose = 'FEES';
    if (_purpose == 'FEES' && _feesRoom <= 0) _purpose = 'BALANCE';
    if (_purpose == 'BALANCE' && _balanceRoom <= 0 && _feesRoom > 0) _purpose = 'FEES';
    final current = double.tryParse(_amount.text);
    if (first || current == null || current > _room) _amount.text = _suggested().toStringAsFixed(0);
    if (_method == null && b.paymentMethods.length == 1) _method = b.paymentMethods.first;
  }

  /// The uncovered part of the next instalment (or the fee), within what can be paid now.
  double _suggested() {
    final b = _balance;
    if (b == null) return 0;
    if (_purpose == 'FEES') return _feesRoom;
    BalanceInstalment? next;
    for (final i in b.instalments) {
      if (!i.paid) {
        next = i;
        break;
      }
    }
    final suggested = next != null ? next.amount - next.covered : b.remaining;
    return suggested < _balanceRoom ? suggested : _balanceRoom;
  }

  Future<void> _load({bool first = false}) async {
    try {
      final b = await ref.read(purchaseServiceProvider).getBalance(widget.orderId);
      if (mounted) setState(() => _set(b, first: first));
    } catch (_) {
      // No balance yet (older orders) or not visible: the section stays hidden.
    }
  }

  Future<void> _run(Future<PurchaseBalance?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final b = await action();
      if (b != null && mounted) setState(() => _set(b));
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double? get _validAmount {
    final v = double.tryParse(_amount.text.trim());
    if (v == null || v <= 0 || v > _room + 1e-9) return null;
    return (v * 100).roundToDouble() / 100;
  }

  Future<void> _payOnline() => _run(() async {
        final checkout = await ref.read(purchaseServiceProvider).payBalanceOnline(widget.orderId, _validAmount!, _method, purpose: _purpose);
        _checkoutOpen = true;
        final open = widget.openUrl ?? (Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
        if (!await open(Uri.parse(checkout.checkoutUrl))) {
          _checkoutOpen = false;
          throw const ServerException('Could not open the payment page.');
        }
        return null;
      });

  Future<void> _confirm() => _run(() async {
        final b = await ref.read(purchaseServiceProvider).confirmBalance(widget.orderId);
        BalancePayment? last;
        for (final p in b.payments.reversed) {
          if (p.channel == 'ONLINE') {
            last = p;
            break;
          }
        }
        _outcome = last?.status == 'PAID' ? 'paid' : last?.status == 'FAILED' ? 'failed' : 'pending';
        return b;
      });

  Future<void> _pickReceipt() async {
    final picked = await (widget.pickReceipt ?? () => ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2400))();
    if (picked == null) return;
    final size = await picked.length();
    if (size > 10 * 1024 * 1024) {
      setState(() => _error = 'The receipt is larger than 10 MB.');
      return;
    }
    setState(() {
      _receipt = picked;
      _error = null;
    });
  }

  Future<void> _sendTransfer() => _run(() async {
        final bytes = await _receipt!.readAsBytes();
        final b = await ref.read(purchaseServiceProvider).reportTransfer(
              widget.orderId,
              amount: _validAmount!,
              reference: _reference.text.trim(),
              receipt: bytes,
              receiptName: _receipt!.name,
              purpose: _purpose,
            );
        _reference.clear();
        _receipt = null;
        return b;
      });

  Future<void> _openReceipt(BalancePayment p) async {
    try {
      final bytes = await ref.read(purchaseServiceProvider).balanceReceipt(widget.orderId, p.id);
      if (mounted) await openFileBytes(context, bytes, 'receipt-${p.reference ?? p.id}.jpg', isImage: true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the receipt.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    if (b == null) return const SizedBox.shrink();
    final c = b.currency;
    final percent = b.balanceDue <= 0 ? 1.0 : (b.paid / b.balanceDue).clamp(0.0, 1.0);
    final canPay = b.payable && (_feesRoom > 0 || _balanceRoom > 0);

    Widget row(String k, String v, {bool bold = false, Color? color, Key? key}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: bold ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
            Text(v, key: key, style: TextStyle(fontSize: bold ? 15 : 13, color: color ?? AppTheme.textPrimary, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ]),
        );

    return Container(
      key: const Key('balance-section'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary))),
            _pill(b.fullyPaid ? 'Paid in full' : 'Open', b.fullyPaid),
          ]),
          const Text('The rest of the price, paid to Dream Teams Trading PLC after the seller accepts.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          row('Price', money(b.listedPrice, c)),
          if (b.depositCredit > 0) row('Reservation deposit', '− ${money(b.depositCredit, c)}'),
          if (b.loanAmount > 0) row('Bank loan', '− ${money(b.loanAmount, c)}'),
          row('Balance due', money(b.balanceDue, c), bold: true),
          row('Paid', money(b.paid, c), color: AppTheme.success),
          if (b.inProgress > 0) row('Awaiting confirmation', money(b.inProgress, c), color: const Color(0xFFB45309)),
          row('Left to pay', money(b.remaining, c), bold: true, key: const Key('balance-remaining')),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: AppTheme.surfaceColor, color: AppTheme.success)),
          if (b.fees != null) ...[
            const SizedBox(height: 12),
            FeeSummary(
              markupPercent: b.fees!.markupPercent,
              markupAmount: b.fees!.markupAmount,
              vatRate: b.fees!.vatRate,
              vatAmount: b.fees!.vatAmount,
              total: b.fees!.total,
              currency: c,
              extra: [
                if (b.fees!.paid > 0) row('Paid', money(b.fees!.paid, c), color: AppTheme.success),
                if (!b.fees!.fullyPaid) row('Left to pay', money(b.fees!.remaining, c)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Text('Payment schedule', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          for (final i in b.instalments)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                    Text(i.dueDate != null ? 'Due ${i.dueDate}' : 'No due date', style: TextStyle(fontSize: 11, color: i.overdue ? AppTheme.error : AppTheme.textSecondary)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(i.amount, c), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                    i.paid ? 'Paid' : i.covered > 0 ? '${money(i.covered, c)} paid' : i.overdue ? 'Overdue' : 'Due',
                    style: TextStyle(fontSize: 11, color: i.paid ? AppTheme.success : i.overdue ? AppTheme.error : AppTheme.textSecondary),
                  ),
                ]),
              ]),
            ),
          if (_outcome != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _outcome == 'paid' ? const Color(0xFFD1FAE5) : _outcome == 'failed' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _outcome == 'paid'
                    ? 'Payment received. Thank you!'
                    : _outcome == 'failed'
                        ? 'The payment did not go through. You can try again.'
                        : 'We are still waiting for Chapa to confirm the payment.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
          if (canPay) ..._payForm(b) else if (!b.payable && !b.fullyPaid)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('You can pay the balance once the seller accepts your order.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ),
          if (b.payments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Payments', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            for (final p in b.payments.reversed)
              Padding(
                key: Key('balance-payment-${p.id}'),
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${money(p.amount, p.currency)}${p.purpose == 'FEES' ? ' · Service fee & VAT' : ''} · ${PurchaseBalance.channel(p.channel)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text([p.reference, p.paymentMethod ?? (p.preferredMethod != null ? DepositMethods.label(p.preferredMethod!) : null)].whereType<String>().join(' · '),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      if (p.note != null && (p.status == 'REJECTED' || p.status == 'FAILED')) Text(p.note!, style: const TextStyle(fontSize: 11, color: AppTheme.error)),
                    ]),
                  ),
                  _pill(PurchaseBalance.paymentStatus(p.status), p.status == 'PAID'),
                  if (p.status == 'PENDING' && p.checkoutUrl != null)
                    TextButton(onPressed: () => launchUrl(Uri.parse(p.checkoutUrl!), mode: LaunchMode.externalApplication).then((_) => _checkoutOpen = true), child: const Text('Continue')),
                  if (p.hasSlip) TextButton(onPressed: () => _openReceipt(p), child: const Text('Receipt')),
                ]),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _payForm(PurchaseBalance b) {
    final c = b.currency;
    final account = b.bankAccount;
    final reference = _purpose == 'FEES' ? b.transferReference.replaceAll(RegExp(r'-BAL$'), '-FEE') : b.transferReference;
    return [
      const SizedBox(height: 14),
      if (b.fees != null && _feesRoom > 0 && _balanceRoom > 0) ...[
        Row(children: [
          for (final p in const ['FEES', 'BALANCE'])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p == 'FEES' ? 6 : 0, left: p == 'BALANCE' ? 6 : 0),
                child: _choice(
                  key: Key('purpose-$p'),
                  selected: _purpose == p,
                  title: p == 'FEES' ? 'Service fee & VAT' : 'Balance of the price',
                  subtitle: money(p == 'FEES' ? _feesRoom : _balanceRoom, c),
                  onTap: () => setState(() {
                    _purpose = p;
                    _amount.text = _suggested().toStringAsFixed(0);
                  }),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 10),
      ],
      Row(children: [
        Expanded(child: _choice(key: const Key('tab-online'), selected: !_transfer, title: 'Pay online', onTap: () => setState(() => _transfer = false))),
        const SizedBox(width: 12),
        Expanded(child: _choice(key: const Key('tab-transfer'), selected: _transfer, title: 'Bank transfer', onTap: () => setState(() => _transfer = true))),
      ]),
      const SizedBox(height: 10),
      TextField(
        key: const Key('balance-amount'),
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: (_) => setState(() {}),
        decoration: fieldDecoration('Amount', helper: 'Up to ${money(_room, c)}. You can pay in several parts.'),
      ),
      const SizedBox(height: 10),
      if (!_transfer) ...[
        if (!b.checkoutAvailable)
          const Text('Online payment is not available yet. The provider will contact you with payment instructions.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
        else ...[
          DepositMethodPicker(methods: b.paymentMethods, selected: _method, onChanged: _busy ? null : (m) => setState(() => _method = m)),
          const Text('Wallets and cards have limits per payment and per day. If a payment is refused, pay a smaller amount or use a bank transfer.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('balance-pay-online'),
              onPressed: _busy || _validAmount == null || _method == null ? null : _payOnline,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(_validAmount == null ? 'Pay now' : 'Pay ${money(_validAmount, c)} now'),
            ),
          ),
        ],
      ] else ...[
        if (account != null)
          Container(
            key: const Key('bank-account'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TRANSFER TO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              Text('${account.bankName ?? ''}${account.branch != null ? ' · ${account.branch}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (account.accountName != null) Text(account.accountName!),
              SelectableText(account.accountNumber ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Quote this reference: $reference', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          )
        else
          const Text("The provider's bank details are not published yet. Contact support before transferring.", style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
        const SizedBox(height: 10),
        TextField(key: const Key('transfer-reference'), controller: _reference, onChanged: (_) => setState(() {}), decoration: fieldDecoration('Bank transaction reference')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('transfer-receipt'),
          onPressed: _busy ? null : _pickReceipt,
          icon: const Icon(Icons.receipt_long, size: 18),
          label: Text(_receipt == null ? 'Add a photo of the bank receipt' : _receipt!.name, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('transfer-submit'),
            onPressed: _busy || _validAmount == null || _reference.text.trim().isEmpty || _receipt == null ? null : _sendTransfer,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Send for confirmation'),
          ),
        ),
      ],
    ];
  }

  Widget _choice({required Key key, required bool selected, required String title, String? subtitle, required VoidCallback onTap}) => InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF3E8FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.borderColor),
          ),
          child: Column(children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      );

  Widget _pill(String text, bool good) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: good ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: good ? const Color(0xFF047857) : const Color(0xFF1D4ED8))),
      );
}
