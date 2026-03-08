import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/data/country_codes.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../auth/widgets/country_code_phone_input.dart';

/// Edit profile form. Saves via PUT /users/me; same structure and validation as frontend.
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({Key? key, required this.initialProfile}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _countryCode = defaultCountryCode;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialProfile.firstName);
    _lastNameController = TextEditingController(text: widget.initialProfile.lastName);
    _emailController = TextEditingController(text: widget.initialProfile.email);
    _phoneController = TextEditingController();
    _parsePhone(widget.initialProfile.phoneNumber);
  }

  void _parsePhone(String? phone) {
    if (phone == null || phone.isEmpty) return;
    for (final e in countryCodes) {
      final code = e.code.replaceAll(RegExp(r'\s'), '');
      if (phone.startsWith(code) || phone.replaceAll(RegExp(r'\s'), '').startsWith(code)) {
        _countryCode = e.code;
        final numPart = phone
            .replaceFirst(RegExp(r'^\+?\d{1,4}\s*'), '')
            .replaceAll(RegExp(r'\s'), '');
        _phoneController.text = numPart;
        break;
      }
    }
    if (_phoneController.text.isEmpty && phone.trim().isNotEmpty) {
      _phoneController.text = phone.trim();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _error = null;
      _isSaving = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }
    final combinedPhone = _phoneController.text.trim().isNotEmpty
        ? (_countryCode.trim() + _phoneController.text.trim().replaceAll(RegExp(r'\s'), ''))
        : null;
    final request = UserUpdateRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: combinedPhone,
    );
    try {
      final userService = ref.read(userServiceProvider);
      final updated = await userService.updateMe(request);
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
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
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _firstNameController,
                decoration: _inputDecoration('First name'),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'First name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: _inputDecoration('Last name'),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Last name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: _inputDecoration('Email'),
                style: const TextStyle(color: AppTheme.textPrimary),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CountryCodePhoneInput(
                countryCode: _countryCode,
                onCountryCodeChanged: (c) => setState(() => _countryCode = c),
                phoneController: _phoneController,
                placeholder: 'Phone (optional)',
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }
}
