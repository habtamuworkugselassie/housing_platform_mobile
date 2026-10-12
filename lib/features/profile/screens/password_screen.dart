import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../purchase/widgets/purchase_form_steps.dart' show fieldDecoration;

/// Sets a first password (buyers who signed up while ordering, or with Google) or changes it, so
/// the buyer can sign in again with email or phone after signing out. Pops with the new profile.
class PasswordScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const PasswordScreen({super.key, required this.profile});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  static const rules = 'At least 8 characters, with an uppercase letter, a lowercase letter and a number.';

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  static bool strong(String p) =>
      p.length >= 8 && RegExp('[a-z]').hasMatch(p) && RegExp('[A-Z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

  Future<void> _save() async {
    final needsCurrent = widget.profile.needsCurrentPassword;
    String? problem;
    if (needsCurrent && _current.text.isEmpty) {
      problem = 'Enter your current password.';
    } else if (!strong(_next.text)) {
      problem = rules;
    } else if (_next.text != _confirm.text) {
      problem = 'The two new passwords do not match.';
    }
    if (problem != null) return setState(() => _error = problem);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref.read(userServiceProvider).changePassword(
            currentPassword: needsCurrent ? _current.text : null,
            newPassword: _next.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password saved. Use it the next time you sign in.')),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException ? e.message : 'Could not save your password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final signInAs = p.email.isNotEmpty ? p.email : (p.phoneNumber ?? '');
    final title = p.hasPassword ? 'Change password' : 'Set a password';
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              p.hasPassword
                  ? 'Enter your current password, then choose a new one.'
                  : 'Your account has no password yet. Set one so you can sign in again after signing out, without waiting for a code.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (signInAs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('You will sign in with $signInAs and this password.',
                  key: const Key('password-sign-in-as'), style: const TextStyle(color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 20),
            if (p.needsCurrentPassword) ...[
              TextField(
                key: const Key('password-current'),
                controller: _current,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: fieldDecoration('Current password'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('password-new'),
              controller: _next,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: fieldDecoration('New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('password-confirm'),
              controller: _confirm,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: fieldDecoration('Repeat new password'),
            ),
            const SizedBox(height: 8),
            const Text(rules, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, key: const Key('password-error'), style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('password-save'),
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_busy ? 'Saving…' : title),
            ),
          ],
        ),
      ),
    );
  }
}
