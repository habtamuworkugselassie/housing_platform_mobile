import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/property_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/purchase_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/financing_math.dart';
import '../widgets/purchase_account_step.dart';
import '../widgets/purchase_form_steps.dart';
import '../widgets/wizard_steps_header.dart';
import 'purchase_order_detail_screen.dart';

/// The multi-step purchase-order form. Visitors start on the account step; buyers on contact.
class PurchaseOrderScreen extends ConsumerStatefulWidget {
  final PropertyModel property;
  const PurchaseOrderScreen({super.key, required this.property});

  @override
  ConsumerState<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends ConsumerState<PurchaseOrderScreen> {
  final Set<WizardStep> _attempted = {};
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      ref.read(purchaseFormProvider(widget.property.id).notifier).init(user: auth.user, requireAccount: !auth.isAuthenticated);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _primary(PurchaseFormNotifier notifier, PurchaseFormState form) async {
    if (form.step == WizardStep.review) {
      final order = await notifier.submit();
      if (order != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(orderId: order.id, justCreated: true)),
        );
      }
      return;
    }
    setState(() => _attempted.add(form.step));
    if (notifier.next()) {
      _attempted.remove(ref.read(purchaseFormProvider(widget.property.id)).step);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(purchaseFormProvider(widget.property.id));
    final notifier = ref.read(purchaseFormProvider(widget.property.id).notifier);
    final auth = ref.watch(authProvider);
    final isBuyer = auth.user?.roles.contains('BUYER') ?? true;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Place a purchase order'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Builder(builder: (context) {
        if (form.loadingPreview && form.preview == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (form.previewError != null && form.preview == null) {
          return _message(form.previewError!, retry: notifier.loadPreview);
        }
        if (auth.isAuthenticated && !isBuyer) {
          return _message('This account cannot place purchase orders. Sign in with a buyer account to order a property.');
        }
        if (form.preview == null) return const SizedBox.shrink();
        final preview = form.preview!;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PropertySummary(property: widget.property, preview: preview),
                    const SizedBox(height: 16),
                    WizardStepsHeader(form: form, onSelect: notifier.goTo),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: _stepBody(form, notifier),
                    ),
                    if (form.step == WizardStep.review && form.submitError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(form.submitError!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                            for (final e in form.serverFieldErrors.entries)
                              Text('${e.key}: ${e.value}', style: const TextStyle(color: AppTheme.error, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: form.preview == null || form.step == WizardStep.account || (auth.isAuthenticated && !isBuyer)
          ? null
          : _NavBar(form: form, notifier: notifier, onPrimary: () => _primary(notifier, form)),
    );
  }

  Widget _stepBody(PurchaseFormState form, PurchaseFormNotifier notifier) {
    switch (form.step) {
      case WizardStep.account:
        return PurchaseAccountStep(
          onAuthenticated: (d) => notifier.accountReady(fullName: d.fullName, phone: d.phone, email: d.email),
        );
      case WizardStep.contact:
        return PurchaseContactStep(form: form, notifier: notifier, attempted: _attempted.contains(WizardStep.contact));
      case WizardStep.financing:
        return PurchaseFinancingStep(form: form, notifier: notifier, attempted: _attempted.contains(WizardStep.financing));
      case WizardStep.agreement:
        return PurchaseAgreementStep(form: form, notifier: notifier, attempted: _attempted.contains(WizardStep.agreement));
      case WizardStep.review:
        return PurchaseReviewStep(form: form, notifier: notifier, propertyTitle: widget.property.title);
    }
  }

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
              if (retry != null) TextButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _PropertySummary extends StatelessWidget {
  final PropertyModel property;
  final dynamic preview;
  const _PropertySummary({required this.property, required this.preview});

  @override
  Widget build(BuildContext context) {
    final financing = preview.financingAvailable == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 16)),
          Text(property.location, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(FinancingMath.formatMoney((preview.listedPrice as num).toDouble(), currency: preview.currency as String),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor, fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: financing ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: Text(financing ? 'Bank financing is available for this property' : 'Standard cash purchase — no financing product is linked',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: financing ? const Color(0xFF1D4ED8) : AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final PurchaseFormState form;
  final PurchaseFormNotifier notifier;
  final VoidCallback onPrimary;
  const _NavBar({required this.form, required this.notifier, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    final isReview = form.step == WizardStep.review;
    final canBack = form.stepIndex > 0 && form.steps[form.stepIndex - 1] != WizardStep.account;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            OutlinedButton(
              key: const Key('wizard-back'),
              onPressed: canBack && !form.submitting ? notifier.back : null,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('wizard-primary'),
                onPressed: (isReview ? form.canSubmit : true) && !form.submitting ? onPrimary : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: form.submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isReview ? 'Submit purchase order' : 'Next', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
