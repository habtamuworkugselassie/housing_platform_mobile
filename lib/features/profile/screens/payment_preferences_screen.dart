import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../purchase/widgets/purchase_form_steps.dart' show fieldDecoration;
import '../../purchase/widgets/purchase_payment_widgets.dart' show DepositMethodPicker;

/// How the buyer usually pays: preselected for deposits, the balance and fees. Chapa hosts the
/// payment, so only the method and a mobile-money number are kept. Pops with the new profile.
class PaymentPreferencesScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const PaymentPreferencesScreen({super.key, required this.profile});

  @override
  ConsumerState<PaymentPreferencesScreen> createState() => _PaymentPreferencesScreenState();
}

class _PaymentPreferencesScreenState extends ConsumerState<PaymentPreferencesScreen> {
  static const methods = ['TELEBIRR', 'CBE_BIRR', 'MPESA', 'AWASH_BIRR', 'CARD'];

  late String? _method = widget.profile.preferredPaymentMethod;
  late final _phone = TextEditingController(text: widget.profile.paymentPhone ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final phone = _phone.text.trim();
      final updated = await ref.read(userServiceProvider).updatePaymentPreferences(
            method: _method,
            phone: phone.isEmpty ? null : phone,
          );
      ref.invalidate(savedPaymentMethodProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment method saved.')));
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException ? e.message : 'Could not save your payment method. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text('Payment method', style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how you usually pay. It is selected for you when you pay a deposit, the balance or fees; you can still pick another method each time.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            DepositMethodPicker(
              methods: methods,
              selected: _method,
              onChanged: _busy ? null : (m) => setState(() => _method = m),
            ),
            if (_method != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('payment-clear'),
                  onPressed: _busy ? null : () => setState(() => _method = null),
                  child: const Text('No preferred method'),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('payment-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration('Mobile money number (09…)'),
            ),
            const SizedBox(height: 6),
            const Text(
              "Used for telebirr, CBE Birr, M-Pesa and Awash Birr payments. Leave empty to use your order's contact phone.",
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Payments are processed by Chapa. We never store card numbers or wallet PINs.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, key: const Key('payment-error'), style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('payment-save'),
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_busy ? 'Saving…' : 'Save payment method'),
            ),
          ],
        ),
      ),
    );
  }
}
