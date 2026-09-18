import 'package:flutter/material.dart';
import '../../../core/data/country_codes.dart';
import '../../../core/theme/theme.dart';

/// Phone input with a country-code selector, aligned with the web `CountryCodePhoneInput`.
///
/// The closed selector shows the flag and dial code; tapping it opens a searchable sheet listing
/// flag, country name and code. The number box is a plain [TextFormField] on [phoneController].
class CountryCodePhoneInput extends StatelessWidget {
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final TextEditingController? phoneController;
  final String? placeholder;
  final String? Function(String?)? validator;

  /// Fired as the buyer types, for callers that derive helper text from the number.
  final ValueChanged<String>? onChanged;

  /// Paints both controls with the error colour, e.g. after a failed validation.
  final bool hasError;
  final bool enabled;

  /// Key for the number box so tests and forms can target it.
  final Key? fieldKey;

  const CountryCodePhoneInput({
    super.key,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.phoneController,
    this.placeholder,
    this.validator,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
    this.fieldKey,
  });

  Future<void> _pick(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CountryCodePicker(selected: countryCode),
    );
    if (chosen != null && chosen != countryCode) onCountryCodeChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final selected = findCountryCode(countryCode) ?? findCountryCode(defaultCountryCode)!;
    final borderColor = hasError ? AppTheme.error : AppTheme.borderColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Country code ${selected.code}',
          child: InkWell(
            key: const Key('country-code-button'),
            onTap: enabled ? () => _pick(context) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                color: enabled ? AppTheme.surfaceColor : AppTheme.surfaceMuted,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selected.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(selected.code, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            key: fieldKey,
            controller: phoneController,
            enabled: enabled,
            onChanged: onChanged,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: placeholder ?? 'Phone number',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              fillColor: enabled ? AppTheme.surfaceColor : AppTheme.surfaceMuted,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                borderSide: BorderSide(color: hasError ? AppTheme.error : AppTheme.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            validator: validator,
          ),
        ),
      ],
    );
  }
}

/// Searchable list of countries shown in a bottom sheet; pops with the chosen dial code.
class CountryCodePicker extends StatefulWidget {
  final String selected;
  const CountryCodePicker({super.key, required this.selected});

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CountryCodeEntry> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return countryCodes;
    return countryCodes
        .where((e) => e.code.contains(q) || e.label.toLowerCase().contains(q) || e.iso2.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const Key('country-code-search'),
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search country or code…',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('No countries match "${_search.text}"', style: const TextStyle(color: AppTheme.textSecondary)),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final e = items[i];
                        final isSelected = e.code == widget.selected;
                        return ListTile(
                          key: Key('country-option-${e.iso2}'),
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: AppTheme.surfaceMuted,
                          leading: Text(e.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(e.label, style: const TextStyle(color: AppTheme.textPrimary)),
                          trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                          onTap: () => Navigator.of(context).pop(e.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
