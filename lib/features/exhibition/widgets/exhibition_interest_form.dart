import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/data/country_codes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../auth/widgets/country_code_phone_input.dart';

/// Exhibition interest registration form (same API as frontend: POST /exhibition/interest).
class ExhibitionInterestForm extends ConsumerStatefulWidget {
  const ExhibitionInterestForm({Key? key}) : super(key: key);

  @override
  ConsumerState<ExhibitionInterestForm> createState() => _ExhibitionInterestFormState();
}

class _ExhibitionInterestFormState extends ConsumerState<ExhibitionInterestForm> {
  final _emailController = TextEditingController();
  String _countryCode = defaultCountryCode;
  final _phoneController = TextEditingController();
  String _organizationType = 'REAL_ESTATE_COMPANY';
  String _interestType = 'visitor';
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();

  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Valid email is required');
      return;
    }
    final phoneRaw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phoneNumber = phoneRaw.isEmpty ? null : (_countryCode + phoneRaw);

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await ref.read(exhibitionServiceProvider).registerInterest(
            email: email,
            phoneNumber: phoneNumber,
            organizationType: _organizationType,
            interestType: _interestType,
            company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
            message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _submitting = false;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 48),
            const SizedBox(height: 12),
            Text(
              'Thank you for your interest',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade200,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We will get in touch with you soon.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register your interest',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exhibitor or visitor — we\'ll contact you.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textSecondary),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const Text('Phone (optional)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          CountryCodePhoneInput(
            countryCode: _countryCode,
            onCountryCodeChanged: (v) => setState(() => _countryCode = v),
            phoneController: _phoneController,
            placeholder: 'Phone',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _organizationType,
            decoration: const InputDecoration(
              labelText: 'Organization type *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'REAL_ESTATE_COMPANY', child: Text('Real estate')),
              DropdownMenuItem(value: 'CONTRACTOR', child: Text('Contractor')),
              DropdownMenuItem(value: 'DEVELOPER', child: Text('Developer')),
              DropdownMenuItem(value: 'SUPPLIER', child: Text('Supplier')),
              DropdownMenuItem(value: 'CONSULTANT_ARCHITECT', child: Text('Consultant / Architect')),
              DropdownMenuItem(value: 'FINISHING_CONTRACTOR', child: Text('Finishing contractor')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _organizationType = v);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _interestType,
            decoration: const InputDecoration(
              labelText: 'I want to participate as *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'exhibitor', child: Text('Exhibitor')),
              DropdownMenuItem(value: 'visitor', child: Text('Visitor')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _interestType = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Company (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
