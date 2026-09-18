import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/utils/phone_number.dart';

void main() {
  _splitJoinTests();
  group('PhoneNumber.normalize (mirrors the backend PhoneNumberNormalizer)', () {
    const cases = {
      '0911223344': '+251911223344',
      '911223344': '+251911223344',
      '0711223344': '+251711223344',
      '251911223344': '+251911223344',
      '+251 911 22 33 44': '+251911223344',
      '+251-911-223344': '+251911223344',
      '00251911223344': '+251911223344',
      '+14155552671': '+14155552671',
    };
    cases.forEach((raw, expected) {
      test('normalises $raw', () => expect(PhoneNumber.normalize(raw), expected));
    });

    for (final bad in ['', '   ', 'abc', '12345', '+0123456789', '0811223344']) {
      test('rejects "$bad"', () {
        expect(PhoneNumber.normalize(bad), isNull);
        expect(PhoneNumber.isValid(bad), isFalse);
      });
    }

    test('joins a country code with a local part', () {
      expect(PhoneNumber.normalizeWithCountryCode('+251', '0911223344'), '+251911223344');
      expect(PhoneNumber.normalizeWithCountryCode('+251', '911 22 33 44'), '+251911223344');
      expect(PhoneNumber.normalizeWithCountryCode('+1', '4155552671'), '+14155552671');
      expect(PhoneNumber.normalizeWithCountryCode('+1', '+251911223344'), '+251911223344');
      expect(PhoneNumber.normalizeWithCountryCode('+251', ''), isNull);
    });

    test('display groups Ethiopian numbers', () {
      expect(PhoneNumber.display('+251911223344'), '+251 91 122 3344');
      expect(PhoneNumber.display('+14155552671'), '+14155552671');
    });

    test('email is optional but must be well formed', () {
      expect(PhoneNumber.isValidEmail(''), isTrue);
      expect(PhoneNumber.isValidEmail(null), isTrue);
      expect(PhoneNumber.isValidEmail('buyer@example.com'), isTrue);
      expect(PhoneNumber.isValidEmail('nope'), isFalse);
    });
  });
}

void _splitJoinTests() {
  group('PhoneNumber.split / join (country-code selector, mirrors the web helpers)', () {
    test('splits an E.164 number into the longest matching dial code and the rest', () {
      expect(PhoneNumber.split('+251911223344'), const PhoneParts('+251', '911223344'));
      expect(PhoneNumber.split('+1 415 555 1234'), const PhoneParts('+1', '4155551234'));
      expect(PhoneNumber.split('+44 7911 123456'), const PhoneParts('+44', '7911123456'));
      expect(PhoneNumber.split('00971501234567'), const PhoneParts('+971', '501234567'));
    });

    test('selects Ethiopia for local forms without the trunk 0', () {
      expect(PhoneNumber.split('0911223344'), const PhoneParts('+251', '911223344'));
      expect(PhoneNumber.split('0711223344'), const PhoneParts('+251', '711223344'));
      expect(PhoneNumber.split('251911223344'), const PhoneParts('+251', '911223344'));
    });

    test('falls back to Ethiopia and keeps unknown codes whole', () {
      expect(PhoneNumber.split(''), const PhoneParts('+251', ''));
      expect(PhoneNumber.split(null), const PhoneParts('+251', ''));
      expect(PhoneNumber.split('+99912345678'), const PhoneParts('+251', '+99912345678'));
      expect(PhoneNumber.split('12345', fallbackCountryCode: '+1'), const PhoneParts('+1', '12345'));
    });

    test('joins selector and number, dropping a trunk 0 except for Italy', () {
      expect(PhoneNumber.join('+251', '911 223 344'), '+251911223344');
      expect(PhoneNumber.join('+251', '0911223344'), '+251911223344');
      expect(PhoneNumber.join('+44', '07911 123456'), '+447911123456');
      expect(PhoneNumber.join('+39', '06 1234 5678'), '+390612345678');
      expect(PhoneNumber.join('+1', '(415) 555-1234'), '+14155551234');
    });

    test('a full international number in the number box wins over the selector', () {
      expect(PhoneNumber.join('+251', '+14155551234'), '+14155551234');
      expect(PhoneNumber.join('+251', '0044 7911 123456'), '+447911123456');
    });

    test('returns an empty string when there is nothing to store', () {
      expect(PhoneNumber.join('+251', ''), '');
      expect(PhoneNumber.join('+251', '  '), '');
      expect(PhoneNumber.join('+251', '0'), '');
      expect(PhoneNumber.join('+251', null), '');
    });

    test('round-trips through the backend normaliser rules', () {
      for (final raw in ['+251911223344', '0911223344', '+14155551234', '+447911123456']) {
        final parts = PhoneNumber.split(raw);
        expect(PhoneNumber.normalize(PhoneNumber.join(parts.countryCode, parts.national)), PhoneNumber.normalize(raw));
      }
    });
  });
}
