import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/utils/phone_number.dart';

void main() {
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
