/// Phone normalisation identical to the backend `PhoneNumberNormalizer`, so the form rejects
/// exactly what the server would reject and can show the number as it will be stored.
///
/// Accepted: +2519XXXXXXXX / +2517XXXXXXXX, 09XXXXXXXX / 07XXXXXXXX, 2519…, 00251…, and any other
/// well-formed international number (+ followed by 8–15 digits).
import '../data/country_codes.dart';

/// What the country-code selector shows and what sits in the number box.
class PhoneParts {
  /// Dial code as the selector shows it, e.g. "+251".
  final String countryCode;

  /// The rest of the digits; starts with "+" only when the dial code is not in our list.
  final String national;

  const PhoneParts(this.countryCode, this.national);

  @override
  bool operator ==(Object other) => other is PhoneParts && other.countryCode == countryCode && other.national == national;

  @override
  int get hashCode => Object.hash(countryCode, national);

  @override
  String toString() => 'PhoneParts($countryCode, $national)';
}

class PhoneNumber {
  PhoneNumber._();

  static final RegExp _e164 = RegExp(r'^\+[1-9][0-9]{7,14}$');
  static final RegExp _ethiopianLocal = RegExp(r'^0?([79][0-9]{8})$');
  static final RegExp _ethiopianIntlNoPlus = RegExp(r'^251([79][0-9]{8})$');
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Returns the E.164 form, or null when the input is not a phone number we accept.
  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var digits = raw.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.startsWith('00')) digits = '+${digits.substring(2)}';

    final local = _ethiopianLocal.firstMatch(digits);
    if (local != null) return '+251${local.group(1)}';
    final intl = _ethiopianIntlNoPlus.firstMatch(digits);
    if (intl != null) return '+251${intl.group(1)}';
    if (_e164.hasMatch(digits)) return digits;
    return null;
  }

  /// Split a stored or typed number into the selector value and the national part (mirrors the
  /// web `splitPhone`). Ethiopian local forms select +251; an international number selects its
  /// country when we know the code and otherwise stays whole in the national box so nothing the
  /// buyer typed is lost.
  static PhoneParts split(String? raw, {String fallbackCountryCode = defaultCountryCode}) {
    if (raw == null || raw.trim().isEmpty) return PhoneParts(fallbackCountryCode, '');
    var digits = raw.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.startsWith('00')) digits = '+${digits.substring(2)}';

    if (digits.startsWith('+')) {
      for (final code in dialCodesLongestFirst) {
        if (digits.startsWith(code)) return PhoneParts(code, digits.substring(code.length));
      }
      return PhoneParts(fallbackCountryCode, digits);
    }
    final local = _ethiopianLocal.firstMatch(digits);
    if (local != null) return PhoneParts('+251', local.group(1)!);
    final intl = _ethiopianIntlNoPlus.firstMatch(digits);
    if (intl != null) return PhoneParts('+251', intl.group(1)!);
    return PhoneParts(fallbackCountryCode, digits);
  }

  /// Recombine selector + national number into the single string the form and API use (mirrors
  /// the web `joinPhone`). A leading trunk "0" is dropped (0911… under +251 becomes +251911…),
  /// except for Italy where the 0 is part of the number. A full "+…" or "00…" number typed into
  /// the national box wins over the selector, so pasting an international number just works.
  /// Returns "" when there is nothing to store, so a "required" check still fires.
  static String join(String countryCode, String? national) {
    var n = (national ?? '').trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (n.isEmpty) return '';
    if (n.startsWith('00')) n = '+${n.substring(2)}';
    if (n.startsWith('+')) return n;
    if (countryCode != '+39') n = n.replaceFirst(RegExp(r'^0+'), '');
    if (n.isEmpty) return '';
    return '$countryCode$n';
  }

  /// Joins a country-code dropdown value with the typed local part and normalises the result,
  /// e.g. ("+251", "0911223344") → "+251911223344". Null when the result is not a valid number.
  static String? normalizeWithCountryCode(String countryCode, String local) {
    final joined = join(countryCode, local);
    return joined.isEmpty ? null : normalize(joined);
  }

  static bool isValid(String? raw) => normalize(raw) != null;

  /// Optional field: empty is fine, otherwise it must look like an address.
  static bool isValidEmail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return true;
    return _email.hasMatch(raw.trim());
  }

  /// +251 91 122 3344 for Ethiopian numbers, unchanged otherwise.
  static String display(String? e164) {
    if (e164 == null) return '';
    final m = RegExp(r'^\+251([79])([0-9])([0-9]{3})([0-9]{4})$').firstMatch(e164);
    if (m == null) return e164;
    return '+251 ${m.group(1)}${m.group(2)} ${m.group(3)} ${m.group(4)}';
  }
}
