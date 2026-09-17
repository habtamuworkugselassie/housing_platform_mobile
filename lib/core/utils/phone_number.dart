/// Phone normalisation identical to the backend `PhoneNumberNormalizer`, so the form rejects
/// exactly what the server would reject and can show the number as it will be stored.
///
/// Accepted: +2519XXXXXXXX / +2517XXXXXXXX, 09XXXXXXXX / 07XXXXXXXX, 2519…, 00251…, and any other
/// well-formed international number (+ followed by 8–15 digits).
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

  /// Joins a country-code dropdown value with the typed local part, e.g. ("+251", "0911223344").
  static String? normalizeWithCountryCode(String countryCode, String local) {
    final trimmed = local.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('+') || trimmed.startsWith('00')) return normalize(trimmed);
    if (countryCode == '+251') return normalize(trimmed);
    final digits = trimmed.replaceAll(RegExp(r'[\s\-().]'), '').replaceFirst(RegExp(r'^0+'), '');
    return normalize('$countryCode$digits');
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
