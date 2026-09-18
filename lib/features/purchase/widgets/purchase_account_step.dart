import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../core/data/country_codes.dart';
import '../../../core/models/auth_model.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/phone_number.dart';
import '../../auth/screens/auth_screen.dart';
import '../../auth/widgets/country_code_phone_input.dart';

class AccountDetails {
  final String? fullName;
  final String? phone;
  final String? email;
  const AccountDetails({this.fullName, this.phone, this.email});
}

/// Step 0 for visitors. Three doors, all ending in a signed-in BUYER: Google, a quick sign-up
/// (name + phone), or a WhatsApp code for an existing phone.
class PurchaseAccountStep extends ConsumerStatefulWidget {
  final ValueChanged<AccountDetails> onAuthenticated;
  const PurchaseAccountStep({super.key, required this.onAuthenticated});

  @override
  ConsumerState<PurchaseAccountStep> createState() => _PurchaseAccountStepState();
}

class _PurchaseAccountStepState extends ConsumerState<PurchaseAccountStep> {
  bool _registerMode = true;
  bool _attempted = false;
  bool _busy = false;
  bool _codeSent = false;
  String? _error;

  String _countryCode = defaultCountryCode;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _loginPhone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _loginPhone, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _normalizedPhone => PhoneNumber.normalizeWithCountryCode(_countryCode, _phone.text);
  String? get _normalizedLoginPhone => PhoneNumber.normalizeWithCountryCode(_countryCode, _loginPhone.text);

  Map<String, String> get _registerErrors {
    final e = <String, String>{};
    if (_name.text.trim().length < 2) e['name'] = 'Enter your full name.';
    if (_phone.text.trim().isEmpty) {
      e['phone'] = 'Phone number is required.';
    } else if (_normalizedPhone == null) {
      e['phone'] = 'Enter a valid phone number for the selected country, e.g. 911 223 344 for Ethiopia.';
    }
    if (_email.text.trim().isNotEmpty && !PhoneNumber.isValidEmail(_email.text)) e['email'] = 'Please enter a valid email.';
    final pw = _password.text;
    if (pw.isNotEmpty && !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(pw)) {
      e['password'] = 'Password needs 8+ characters with upper, lower case and a number.';
    }
    return e;
  }

  void _fail(Object err, String fallback) {
    final message = err is ApiException && err.message.isNotEmpty ? err.message : fallback;
    setState(() => _error = message);
    // Phone already registered: steer to the sign-in tab with the number kept.
    if (_registerMode && message.toLowerCase().contains('already has an account')) {
      _loginPhone.text = _phone.text;
      setState(() => _registerMode = false);
    }
  }

  void _switchMode(bool register) => setState(() {
        _registerMode = register;
        _error = null;
        _attempted = false;
      });

  Future<void> _submitRegister() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    if (_registerErrors.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      final phone = _normalizedPhone!;
      final auth = await ref.read(authProvider.notifier).quickRegister(QuickRegistrationRequest(
            fullName: _name.text.trim(),
            phoneNumber: phone,
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            password: _password.text.isEmpty ? null : _password.text,
          ));
      widget.onAuthenticated(AccountDetails(fullName: _name.text.trim(), phone: phone, email: auth.email.isEmpty ? null : auth.email));
    } catch (e) {
      _fail(e, 'Could not create the account. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    final phone = _normalizedLoginPhone;
    if (phone == null) return;
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).sendOtpLogin(phone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = ok;
      _attempted = false;
      if (!ok) _error = 'Could not send the code. Check the number and try again.';
    });
  }

  Future<void> _confirmCode() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    final phone = _normalizedLoginPhone;
    if (phone == null || _code.text.trim().length != 6) return;
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).confirmOtpLogin(phone, _code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      final user = ref.read(authProvider).user;
      widget.onAuthenticated(AccountDetails(
        fullName: user?.fullName,
        phone: phone,
        email: (user?.email.isEmpty ?? true) ? null : user!.email,
      ));
    } else {
      final err = ref.read(authProvider).error;
      setState(() => _error = err ?? 'Enter the 6-digit code from WhatsApp.');
      ref.read(authProvider.notifier).clearError();
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final idToken = await ref.read(googleAuthGatewayProvider).obtainIdToken();
      if (idToken == null) return; // dismissed
      final auth = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      widget.onAuthenticated(AccountDetails(fullName: auth.fullName, email: auth.email.isEmpty ? null : auth.email, phone: auth.phoneNumber));
    } catch (e) {
      _fail(e, 'Google sign-in did not complete. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleAvailable = ref.read(googleAuthGatewayProvider).isAvailable;
    final errors = _registerErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('First, who is ordering?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Create an account in seconds or sign in. Your order and the agreements you sign are kept under it.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        if (googleAvailable) ...[
          OutlinedButton.icon(
            key: const Key('google-button'),
            onPressed: _busy ? null : _google,
            icon: const Icon(Icons.g_mobiledata, size: 26),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(fontSize: 11, color: AppTheme.textMuted))),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _tab("I'm new here", _registerMode, () => _switchMode(true)),
            _tab('I have an account', !_registerMode, () => _switchMode(false)),
          ]),
        ),
        const SizedBox(height: 20),
        if (_registerMode) ..._registerForm(errors) else ..._loginForm(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('account-error'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
            child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('account-primary'),
          onPressed: _busy ? null : (_registerMode ? _submitRegister : (_codeSent ? _confirmCode : _sendCode)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_registerMode ? 'Create account & continue' : (_codeSent ? 'Verify & continue' : 'Send me a code'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        if (!_registerMode)
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('Prefer email and password? Sign in the classic way', style: TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _tab(String text, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
            ),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppTheme.primaryColor : AppTheme.textSecondary)),
          ),
        ),
      );

  List<Widget> _registerForm(Map<String, String> errors) => [
        _label('Full name *'),
        TextField(
          key: const Key('account-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: _decoration('As written on your ID', _attempted ? errors['name'] : null),
        ),
        const SizedBox(height: 14),
        _label('Phone number *'),
        CountryCodePhoneInput(
          fieldKey: const Key('account-phone'),
          countryCode: _countryCode,
          onCountryCodeChanged: (v) => setState(() => _countryCode = v),
          phoneController: _phone,
          onChanged: (_) => setState(() {}),
          hasError: _attempted && errors['phone'] != null,
          placeholder: _countryCode == '+251' ? '9XX XXX XXX' : 'Phone number',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _attempted && errors['phone'] != null
                ? errors['phone']!
                : (_normalizedPhone != null ? 'Will be stored as ${_normalizedPhone!}' : 'We will send a WhatsApp code to confirm this number. It is also how the seller reaches you.'),
            style: TextStyle(fontSize: 12, color: _attempted && errors['phone'] != null ? AppTheme.error : AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        _label('Email (optional)'),
        TextField(
          key: const Key('account-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          decoration: _decoration('you@example.com', _attempted ? errors['email'] : null),
        ),
        const SizedBox(height: 14),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Add a password (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          subtitle: const Text('Without one you sign in with a WhatsApp code.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          children: [
            TextField(
              key: const Key('account-password'),
              controller: _password,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: _decoration('At least 8 characters, upper/lower case and a number', _attempted ? errors['password'] : null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('By continuing you create an Ethio Build Connect buyer account and accept the platform terms.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ];

  List<Widget> _loginForm() => [
        _label('Phone number'),
        CountryCodePhoneInput(
          fieldKey: const Key('login-phone'),
          countryCode: _countryCode,
          onCountryCodeChanged: (v) => setState(() => _countryCode = v),
          phoneController: _loginPhone,
          onChanged: (_) => setState(() {}),
          enabled: !_codeSent,
          hasError: _attempted && _normalizedLoginPhone == null,
          placeholder: _countryCode == '+251' ? '9XX XXX XXX' : 'Phone number',
        ),
        if (_attempted && _normalizedLoginPhone == null)
          const Padding(padding: EdgeInsets.only(top: 6), child: Text('Enter a valid phone number.', style: TextStyle(fontSize: 12, color: AppTheme.error))),
        if (_codeSent) ...[
          const SizedBox(height: 18),
          _label('6-digit code'),
          Center(
            child: Pinput(
              key: const Key('account-code'),
              controller: _code,
              length: 6,
              onCompleted: (_) => _confirmCode(),
              enabled: !_busy,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Sent to your WhatsApp. It expires after a few minutes.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          TextButton(
            onPressed: _busy ? null : () => setState(() {
                  _codeSent = false;
                  _code.clear();
                }),
            child: const Text('Use a different number', style: TextStyle(fontSize: 12)),
          ),
        ],
      ];

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      );

  InputDecoration _decoration(String hint, String? error) => InputDecoration(
        hintText: hint,
        errorText: error,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
