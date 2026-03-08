import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/data/country_codes.dart';
import '../../../core/models/auth_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../widgets/country_code_phone_input.dart';
import '../../marketplace/screens/root_screen.dart';

/// Unified auth screen with Login and Register tabs (aligned with frontend).
/// Supports Buyer and other roles; country code + phone validation.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Login
  bool _loginWithEmail = true;
  String _loginCountryCode = defaultCountryCode;
  final _loginPhoneController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  // Register
  final _regFirstNameController = TextEditingController();
  final _regLastNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  String _regCountryCode = defaultCountryCode;
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  String _regRole = 'BUYER';
  bool _obscurePassword = true;
  bool _obscureLoginPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final username = _loginWithEmail
        ? _loginEmailController.text.trim()
        : _loginCountryCode + _loginPhoneController.text.trim().replaceAll(RegExp(r'\s'), '');
    if (username.isEmpty) {
      ref.read(authProvider.notifier).clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email or phone number'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final password = _loginPasswordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submitRegister() async {
    final email = _regEmailController.text.trim();
    final phoneRaw = _regPhoneController.text.trim().replaceAll(RegExp(r'\s'), '');
    final phoneNumber = phoneRaw.isEmpty ? null : (_regCountryCode + phoneRaw);
    final request = RegistrationRequest(
      firstName: _regFirstNameController.text.trim(),
      lastName: _regLastNameController.text.trim(),
      email: email,
      password: _regPasswordController.text,
      phoneNumber: phoneNumber,
      role: _regRole,
    );
    if (request.firstName.isEmpty || request.lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First and last name are required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid email is required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (request.password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: AppTheme.error),
      );
      return;
    }
    final success = await ref.read(authProvider.notifier).register(request);
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.error),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: const Text('Sign in', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Register'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(authState.isLoading),
          _buildRegisterTab(authState.isLoading),
        ],
      ),
    );
  }

  Widget _buildLoginTab(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _loginWithEmail ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _loginWithEmail = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _loginWithEmail ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: !_loginWithEmail ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() => _loginWithEmail = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Phone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_loginWithEmail ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loginWithEmail)
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textSecondary),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phone number', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                CountryCodePhoneInput(
                  countryCode: _loginCountryCode,
                  onCountryCodeChanged: (v) => setState(() => _loginCountryCode = v),
                  phoneController: _loginPhoneController,
                  placeholder: 'Phone number',
                ),
              ],
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword ? LucideIcons.eyeOff : LucideIcons.eye, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _submitLogin,
            child: loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _regFirstNameController,
                  decoration: const InputDecoration(labelText: 'First name *', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _regLastNameController,
                  decoration: const InputDecoration(labelText: 'Last name *', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regEmailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textSecondary),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone (optional)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              CountryCodePhoneInput(
                countryCode: _regCountryCode,
                onCountryCodeChanged: (v) => setState(() => _regCountryCode = v),
                phoneController: _regPhoneController,
                placeholder: 'Phone number',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 6) return 'Enter a valid phone number';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _regRole,
            decoration: const InputDecoration(
              labelText: 'Account type *',
              prefixIcon: Icon(LucideIcons.user, color: AppTheme.textSecondary),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'BUYER', child: Text('Buyer')),
              DropdownMenuItem(value: 'REALTOR', child: Text('Real Estate Agent')),
              DropdownMenuItem(value: 'BANKER', child: Text('Banker')),
              DropdownMenuItem(value: 'SUPPLIER', child: Text('Supplier')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _regRole = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password * (min 8 characters)',
              prefixIcon: const Icon(LucideIcons.lock, color: AppTheme.textSecondary),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : _submitRegister,
            child: loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
