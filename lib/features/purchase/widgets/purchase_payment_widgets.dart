import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/models/purchase_model.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import 'purchase_form_steps.dart';

// ---------------------------------------------------------------- method picker

/// One choice per payment method; each opens Chapa's checkout on that method.
class DepositMethodPicker extends StatelessWidget {
  final List<String> methods;
  final String? selected;
  final ValueChanged<String>? onChanged;
  const DepositMethodPicker({super.key, required this.methods, required this.selected, required this.onChanged});

  static const _badge = {
    'TELEBIRR': (Color(0xFF0284C7), 'tb'),
    'CBE_BIRR': (Color(0xFF7E22CE), 'CBE'),
    'MPESA': (Color(0xFF16A34A), 'M-P'),
    'AWASH_BIRR': (Color(0xFFF97316), 'AW'),
    'CARD': (Color(0xFF334155), 'VISA'),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('method-$m'),
              borderRadius: BorderRadius.circular(14),
              onTap: onChanged == null ? null : () => onChanged!(m),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: m == selected ? const Color(0xFFF3E8FF) : Colors.white,
                  border: Border.all(color: m == selected ? AppTheme.primaryColor : AppTheme.borderColor, width: m == selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: (_badge[m]?.$1) ?? AppTheme.textSecondary, borderRadius: BorderRadius.circular(10)),
                      child: Text(_badge[m]?.$2 ?? '', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DepositMethods.label(m), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          Text(DepositMethods.help(m), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(m == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: m == selected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- payment step

/// Deposit amount, birr / US dollars switch, method choice, and the service fee to come.
class PurchasePaymentStep extends StatelessWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const PurchasePaymentStep({super.key, required this.form, required this.notifier, required this.attempted});

  @override
  Widget build(BuildContext context) {
    final quote = form.depositQuote;
    final fees = form.preview?.fees;
    final usdOffered = form.depositOnline && (form.depositCurrency == 'USD' || quote?.usdAmount != null);
    final usd = form.depositCurrency == 'USD';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepHeader('Payment method',
            "Choose how you will pay the reservation deposit. You pay it right after placing the order, on Chapa's secure checkout."),
        if (usdOffered) ...[
          Row(
            children: [
              for (final c in const ['ETB', 'USD'])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: c == 'ETB' ? 6 : 0, left: c == 'USD' ? 6 : 0),
                    child: OutlinedButton(
                      key: Key('currency-$c'),
                      onPressed: form.loadingPreview ? null : () => notifier.setDepositCurrency(c),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: (c == 'USD') == usd ? const Color(0xFFF3E8FF) : Colors.white,
                        side: BorderSide(color: (c == 'USD') == usd ? AppTheme.primaryColor : AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Column(children: [
                        Text(c == 'ETB' ? 'Birr (ETB)' : 'US dollars (USD)', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        Text(c == 'ETB' ? 'Wallets or card' : 'International card', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (quote != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESERVATION DEPOSIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: .5)),
                const SizedBox(height: 4),
                Text(money(quote.amount, quote.currency), key: const Key('deposit-quote'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                if (quote.converted)
                  Text('Equivalent to ${money(quote.baseAmount, quote.baseCurrency ?? 'ETB')} at ${quote.exchangeRate} birr per US dollar',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                const Text('Paid to reserve the property while the seller reviews your order. Refunded in full if the seller declines or does not respond.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (form.depositOnline) ...[
          fieldLabel('Pay the deposit with'),
          DepositMethodPicker(methods: quote?.paymentMethods ?? DepositMethods.all, selected: form.paymentMethod, onChanged: notifier.setPaymentMethod),
          if (attempted && form.paymentErrors['method'] != null)
            Text(form.paymentErrors['method']!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          const SizedBox(height: 4),
          const Text("You will be taken to Chapa's secure checkout. Card details are entered there and are never stored on this platform.",
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ] else
          const Text('Online payment is not available yet. The provider will contact you with payment instructions.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        if (fees != null) ...[
          const SizedBox(height: 16),
          FeeSummary(markupPercent: fees.markupPercent, markupAmount: fees.markupAmount, vatRate: fees.vatRate, vatAmount: fees.vatAmount, total: fees.total, currency: fees.currency,
              note: 'Paid to Dream Teams Trading PLC once the seller accepts, separately from the price. Stated in the Promise to Purchase.'),
        ],
        if (form.financingApplied) ...[
          const SizedBox(height: 12),
          const Text('The deposit is separate from your loan; the bank pays its share after approval.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }
}

/// Service fee (markup) + VAT on price and fee.
class FeeSummary extends StatelessWidget {
  final double markupPercent, markupAmount, vatRate, vatAmount, total;
  final String currency;
  final String? note;
  final List<Widget> extra;
  const FeeSummary({
    super.key,
    required this.markupPercent,
    required this.markupAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.total,
    required this.currency,
    this.note,
    this.extra = const [],
  });

  static String pct(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 13, color: bold ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
            Text(v, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ]),
        );
    return Container(
      key: const Key('fee-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor), color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service fee and VAT', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          row('Service fee (${pct(markupPercent)} %)', money(markupAmount, currency)),
          row('VAT (${pct(vatRate)} % on price + fee)', money(vatAmount, currency)),
          row('Total fee', money(total, currency), bold: true),
          ...extra,
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- property documents

/// Verified official documents of the property (Annex A of the Promise to Purchase).
class PropertyDocumentsList extends StatefulWidget {
  final List<PropertyDocumentItem> documents;
  final Future<List<int>> Function(PropertyDocumentItem doc) loadFile;
  const PropertyDocumentsList({super.key, required this.documents, required this.loadFile});

  @override
  State<PropertyDocumentsList> createState() => _PropertyDocumentsListState();
}

class _PropertyDocumentsListState extends State<PropertyDocumentsList> {
  String? _opening;

  Future<void> _open(PropertyDocumentItem d) async {
    setState(() => _opening = d.id);
    try {
      final bytes = await widget.loadFile(d);
      if (!mounted) return;
      await openFileBytes(context, bytes, d.fileName, isImage: d.isImage);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the document.')));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.documents;
    return Column(
      key: const Key('property-documents'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property documents', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(
          docs.isEmpty
              ? 'No verified title deed or lease contract is on file for this property yet. You can ask the provider for them before completion.'
              : 'Verified by the platform and listed in Annex A of the agreement. Open them to check before you sign.',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final d in docs)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor), color: Colors.white),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PropertyDocumentItem.typeLabel(d.documentType) + (d.documentNumber != null ? ' · ${d.documentNumber}' : ''),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
                      Text([d.issuingAuthority, d.issuedOn].whereType<String>().join(' · ').isNotEmpty
                              ? [d.issuingAuthority, d.issuedOn].whereType<String>().join(' · ')
                              : d.fileName,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                TextButton(
                  key: Key('open-doc-${d.id}'),
                  onPressed: _opening == null ? () => _open(d) : null,
                  child: _opening == d.id ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('View'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shows a downloaded private file: images in the app, anything else (PDF) in the phone's viewer.
Future<void> openFileBytes(BuildContext context, List<int> bytes, String fileName, {bool isImage = false}) async {
  final lower = fileName.toLowerCase();
  // Trust the content over the name: receipts uploaded on the web may be PDFs.
  final pdf = bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
  final image = !pdf && (isImage || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png'));
  if (image) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: InteractiveViewer(child: Image.memory(Uint8List.fromList(bytes)))),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        ),
      ),
    );
    return;
  }
  final dir = await Directory.systemTemp.createTemp('ebc-doc');
  var safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (pdf && !safe.toLowerCase().endsWith('.pdf')) safe = '$safe.pdf';
  final file = File('${dir.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No app can open this file: ${result.message}')));
  }
}
