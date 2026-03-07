import 'package:flutter/material.dart';
import '../../../core/data/country_codes.dart';
import '../../../core/theme/theme.dart';

/// Phone input with country code dropdown (aligned with frontend).
class CountryCodePhoneInput extends StatelessWidget {
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final TextEditingController? phoneController;
  final String? placeholder;
  final String? Function(String?)? validator;

  const CountryCodePhoneInput({
    Key? key,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.phoneController,
    this.placeholder,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            color: AppTheme.surfaceColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: countryCodes.any((e) => e.code == countryCode) ? countryCode : defaultCountryCode,
              isExpanded: false,
              dropdownColor: AppTheme.surfaceColor,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
              style: const TextStyle(color: AppTheme.textPrimary),
              items: countryCodes
                  .map((e) => DropdownMenuItem(value: e.code, child: Text(e.code, style: const TextStyle(color: AppTheme.textPrimary))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onCountryCodeChanged(v);
              },
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: phoneController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: placeholder ?? 'Phone number',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              fillColor: AppTheme.surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.phone,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
