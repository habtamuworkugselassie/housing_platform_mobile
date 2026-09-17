import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/data/country_codes.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/financing_math.dart';
import '../../../core/utils/phone_number.dart';
import '../../auth/widgets/country_code_phone_input.dart';
import 'agreement_review_panel.dart';

// ---------------------------------------------------------------- shared bits

Widget stepHeader(String title, String subtitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
      ],
    );

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    );

InputDecoration fieldDecoration(String hint, {String? error, String? helper}) => InputDecoration(
      hintText: hint,
      errorText: error,
      helperText: helper,
      helperMaxLines: 2,
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

String money(double? v, String currency) => FinancingMath.formatMoney(v ?? 0, currency: currency);

// ---------------------------------------------------------------- contact

class PurchaseContactStep extends StatefulWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const PurchaseContactStep({super.key, required this.form, required this.notifier, required this.attempted});

  @override
  State<PurchaseContactStep> createState() => _PurchaseContactStepState();
}

class _PurchaseContactStepState extends State<PurchaseContactStep> {
  String _countryCode = defaultCountryCode;
  late final TextEditingController _phone = TextEditingController(text: widget.form.phone);
  late final TextEditingController _email = TextEditingController(text: widget.form.email);
  late final TextEditingController _message = TextEditingController(text: widget.form.message);

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _phoneChanged() {
    final normalized = PhoneNumber.normalizeWithCountryCode(_countryCode, _phone.text);
    widget.notifier.setPhone(normalized ?? _phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final errors = widget.form.contactErrors;
    final normalized = PhoneNumber.normalize(widget.form.phone);
    final showPhoneError = widget.attempted && errors['phone'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepHeader('How can the seller reach you?',
            'Your phone number is required so the seller and, if applicable, the bank can contact you. Email is optional.'),
        fieldLabel('Phone number *'),
        CountryCodePhoneInput(
          countryCode: _countryCode,
          onCountryCodeChanged: (v) {
            setState(() => _countryCode = v);
            _phoneChanged();
          },
          phoneController: _phone..addListener(_phoneChanged),
          placeholder: '9XX XXX XXX',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            showPhoneError
                ? errors['phone']!
                : normalized != null
                    ? 'Will be stored as ${PhoneNumber.display(normalized)}'
                    : 'Ethiopian numbers as 09XX XXX XXX; other countries with their + code.',
            style: TextStyle(fontSize: 12, color: showPhoneError ? AppTheme.error : AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        fieldLabel('Email address (optional)'),
        TextField(
          key: const Key('contact-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: widget.notifier.setEmail,
          decoration: fieldDecoration('you@example.com',
              error: widget.attempted ? errors['email'] : null, helper: 'We will send order updates here as well if you provide one.'),
        ),
        const SizedBox(height: 16),
        fieldLabel('Message to the seller (optional)'),
        TextField(
          key: const Key('contact-message'),
          controller: _message,
          maxLines: 3,
          maxLength: 2000,
          onChanged: widget.notifier.setMessage,
          decoration: fieldDecoration('Anything the seller should know, e.g. preferred viewing time.'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- financing

class PurchaseFinancingStep extends StatelessWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const PurchaseFinancingStep({super.key, required this.form, required this.notifier, required this.attempted});

  @override
  Widget build(BuildContext context) {
    final preview = form.preview!;
    final currency = preview.currency;
    final offer = form.selectedOffer;
    final split = form.split;
    final errors = form.financingErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepHeader('Bank financing', 'This property has an active financing product. Choose how much of the price you want to finance.'),
        SwitchListTile(
          key: const Key('financing-toggle'),
          value: form.useFinancing,
          onChanged: notifier.setUseFinancing,
          activeThumbColor: AppTheme.primaryColor,
          contentPadding: EdgeInsets.zero,
          title: const Text('Finance part of the purchase through a bank', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          subtitle: const Text('Turn off to place a plain cash order even though financing is available.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
        if (!form.useFinancing)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(12)),
            child: const Text('You chose to pay cash. The order will not include a loan application.', style: TextStyle(color: AppTheme.textSecondary)),
          )
        else ...[
          fieldLabel('Choose a financing offer'),
          for (final o in preview.financingOffers)
            _OfferCard(offer: o, selected: o.financingOfferId == form.selectedOfferId, currency: currency, onTap: () => notifier.selectOffer(o.financingOfferId)),
          if (attempted && errors['offer'] != null) Text(errors['offer']!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          if (offer != null && split != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('How much do you want to finance?', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: split.isMaximum ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(split.isMaximum ? 'Maximum financing' : 'Partial financing',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: split.isMaximum ? const Color(0xFF1D4ED8) : const Color(0xFF92400E))),
                      ),
                    ],
                  ),
                  if (offer.partialFinancingAllowed) ...[
                    Slider(
                      key: const Key('financing-slider'),
                      value: split.financedAmount.clamp(offer.minFinanceableAmount, offer.maxFinanceableAmount),
                      min: offer.minFinanceableAmount,
                      max: offer.maxFinanceableAmount,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => notifier.setFinancedAmount(FinancingMath.round2(v)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _AmountField(
                            key: ValueKey('financed-${split.financedAmount}'),
                            label: 'Financed amount',
                            value: split.financedAmount,
                            onSubmitted: notifier.setFinancedAmount,
                            helper: 'Between ${money(offer.minFinanceableAmount, currency)} and ${money(offer.maxFinanceableAmount, currency)}',
                            error: attempted ? errors['financedAmount'] : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AmountField(
                            key: ValueKey('cash-${split.cashPortion}'),
                            label: 'Your own contribution',
                            value: split.cashPortion,
                            onSubmitted: notifier.setDownPayment,
                            helper: 'At least ${money(offer.minimumDownPayment, currency)}',
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('This product only offers a single loan amount.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                  const SizedBox(height: 8),
                  fieldLabel('Repayment period: ${split.tenureMonths} months'),
                  Slider(
                    key: const Key('tenure-slider'),
                    value: split.tenureMonths.toDouble(),
                    min: offer.minTenureMonths.toDouble(),
                    max: offer.maxTenureMonths.toDouble(),
                    divisions: (offer.maxTenureMonths - offer.minTenureMonths).clamp(1, 1000),
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => notifier.setTenure(v.round()),
                  ),
                  if (attempted && errors['tenureMonths'] != null) Text(errors['tenureMonths']!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      _kv('Financed amount', money(split.financedAmount, currency)),
                      _kv('Your own contribution', money(split.cashPortion, currency)),
                      _kv('Coverage', '${(split.coverageRatio * 100).toStringAsFixed(1)}%'),
                      _kv('Est. instalment', '${money(split.installment, currency)} / month', highlight: true),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  const Text("Estimates use the product's listed rate. The bank confirms the final terms when it reviews your loan application.",
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  static Widget _kv(String k, String v, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary)),
          ],
        ),
      );
}

class _OfferCard extends StatelessWidget {
  final FinancingOption offer;
  final bool selected;
  final String currency;
  final VoidCallback onTap;
  const _OfferCard({required this.offer, required this.selected, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surfaceMuted : Colors.white,
          border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.borderColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: selected ? AppTheme.primaryColor : AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(offer.bankName ?? 'Bank', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                if (offer.recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(999)),
                    child: const Text('Recommended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                  ),
              ],
            ),
            if (offer.creditProductName != null)
              Padding(padding: const EdgeInsets.only(left: 28, top: 2), child: Text(offer.creditProductName!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _stat('Rate', '${offer.interestRate}%'),
                  _stat('Max. coverage', '${(offer.ltvRatio * 100).round()}%'),
                  _stat('Max. loan', money(offer.maxFinanceableAmount, currency)),
                  _stat('Tenure', '${offer.minTenureMonths}–${offer.maxTenureMonths} mo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _stat(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      );
}

class _AmountField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onSubmitted;
  final String? helper;
  final String? error;
  const _AmountField({super.key, required this.label, required this.value, required this.onSubmitted, this.helper, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toStringAsFixed(0),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onFieldSubmitted: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) onSubmitted(parsed);
          },
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: fieldDecoration('', helper: helper, error: error).copyWith(helperStyle: const TextStyle(fontSize: 10)),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- agreement

class PurchaseAgreementStep extends StatelessWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const PurchaseAgreementStep({super.key, required this.form, required this.notifier, required this.attempted});

  static String providerNameFrom(String content) {
    final m = RegExp(r'\*\*([^*]+)\*\*').firstMatch(content);
    return m?.group(1) ?? 'the provider';
  }

  @override
  Widget build(BuildContext context) {
    final agreement = form.promiseAgreement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepHeader('Promise to Purchase Agreement',
            'Before your order is sent, you sign a Promise to Purchase with the platform provider. Please read the whole text.'),
        if (agreement == null)
          const Text('The Promise to Purchase agreement is not available right now. Please try again later.', style: TextStyle(color: AppTheme.error))
        else
          AgreementReviewPanel(
            title: agreement.title,
            content: agreement.content,
            version: agreement.version,
            providerName: providerNameFrom(agreement.content),
            scrolledToEnd: form.scrolledToEnd,
            accepted: form.accepted,
            signatoryName: form.signatoryName,
            attempted: attempted,
            onScrolledToEnd: notifier.setScrolledToEnd,
            onAccepted: notifier.setAccepted,
            onSignatoryName: notifier.setSignatoryName,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- review

class PurchaseReviewStep extends StatelessWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final String propertyTitle;
  const PurchaseReviewStep({super.key, required this.form, required this.notifier, required this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    final payload = form.payload;
    final currency = form.preview?.currency ?? 'ETB';
    final split = form.split;
    final offer = form.selectedOffer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepHeader('Review and submit', 'Check everything once more. Submitting sends the order to the seller and signs the agreement.'),
        _section('Property', [
          Text(propertyTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text(money(form.preview?.listedPrice, currency), style: const TextStyle(color: AppTheme.textSecondary)),
        ]),
        _section('Contact', [
          Text(PhoneNumber.display(payload?.contactPhone), style: const TextStyle(color: AppTheme.textPrimary)),
          Text(payload?.contactEmail ?? 'No email provided', style: const TextStyle(color: AppTheme.textSecondary)),
          if (payload?.buyerMessage != null) Text('“${payload!.buyerMessage}”', style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
        ], onEdit: () => notifier.goTo(WizardStep.contact)),
        _section('Payment', [
          if (form.financingApplied && split != null && offer != null) ...[
            const Text('Bank financed', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
            Text('${offer.bankName} · ${offer.creditProductName} · ${offer.interestRate}%', style: const TextStyle(color: AppTheme.textSecondary)),
            Text('Financed ${money(split.financedAmount, currency)} (${(split.coverageRatio * 100).toStringAsFixed(1)}%), own contribution ${money(split.cashPortion, currency)}',
                style: const TextStyle(color: AppTheme.textPrimary)),
            Text('${split.tenureMonths} months · ≈ ${money(split.installment, currency)}/month', style: const TextStyle(color: AppTheme.textSecondary)),
          ] else ...[
            const Text('Cash purchase', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const Text('Direct purchase without bank financing.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ], onEdit: form.financingAvailable ? () => notifier.goTo(WizardStep.financing) : null),
        _section('Agreement', [
          const Row(children: [
            Icon(Icons.check_circle, size: 16, color: AppTheme.success),
            SizedBox(width: 6),
            Text('Accepted', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.success)),
          ]),
          Text('${form.promiseAgreement?.title} · version ${form.promiseAgreement?.version}', style: const TextStyle(color: AppTheme.textSecondary)),
          Text('Signed as ${payload?.promiseToPurchase.signatoryFullName}', style: const TextStyle(color: AppTheme.textSecondary)),
        ], onEdit: () => notifier.goTo(WizardStep.agreement), editLabel: 'Re-read'),
        const SizedBox(height: 8),
        const Text('By submitting you confirm the details above and electronically sign the Promise to Purchase Agreement.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  static Widget _section(String title, List<Widget> children, {VoidCallback? onEdit, String editLabel = 'Edit'}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(14), color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                if (onEdit != null) GestureDetector(onTap: onEdit, child: Text(editLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor))),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      );
}
