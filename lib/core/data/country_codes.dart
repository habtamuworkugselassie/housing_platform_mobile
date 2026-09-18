/// Country calling codes for phone inputs. Kept identical to the web app's
/// `src/shared/data/countryCodes.ts` so both clients offer the same list.
class CountryCodeEntry {
  final String code;
  final String label;
  final String iso2;

  const CountryCodeEntry({required this.code, required this.label, required this.iso2});

  /// Regional-indicator flag emoji for [iso2] (ET → 🇪🇹).
  String get flag => iso2ToFlag(iso2);
}

const List<CountryCodeEntry> countryCodes = [
  CountryCodeEntry(code: '+251', label: 'Ethiopia (+251)', iso2: 'ET'),
  CountryCodeEntry(code: '+291', label: 'Eritrea (+291)', iso2: 'ER'),
  CountryCodeEntry(code: '+253', label: 'Djibouti (+253)', iso2: 'DJ'),
  CountryCodeEntry(code: '+252', label: 'Somalia (+252)', iso2: 'SO'),
  CountryCodeEntry(code: '+249', label: 'Sudan (+249)', iso2: 'SD'),
  CountryCodeEntry(code: '+211', label: 'South Sudan (+211)', iso2: 'SS'),
  CountryCodeEntry(code: '+972', label: 'Israel (+972)', iso2: 'IL'),
  CountryCodeEntry(code: '+974', label: 'Qatar (+974)', iso2: 'QA'),
  CountryCodeEntry(code: '+965', label: 'Kuwait (+965)', iso2: 'KW'),
  CountryCodeEntry(code: '+973', label: 'Bahrain (+973)', iso2: 'BH'),
  CountryCodeEntry(code: '+968', label: 'Oman (+968)', iso2: 'OM'),
  CountryCodeEntry(code: '+961', label: 'Lebanon (+961)', iso2: 'LB'),
  CountryCodeEntry(code: '+962', label: 'Jordan (+962)', iso2: 'JO'),
  CountryCodeEntry(code: '+1', label: 'USA/Canada (+1)', iso2: 'US'),
  CountryCodeEntry(code: '+44', label: 'UK (+44)', iso2: 'GB'),
  CountryCodeEntry(code: '+91', label: 'India (+91)', iso2: 'IN'),
  CountryCodeEntry(code: '+86', label: 'China (+86)', iso2: 'CN'),
  CountryCodeEntry(code: '+81', label: 'Japan (+81)', iso2: 'JP'),
  CountryCodeEntry(code: '+49', label: 'Germany (+49)', iso2: 'DE'),
  CountryCodeEntry(code: '+33', label: 'France (+33)', iso2: 'FR'),
  CountryCodeEntry(code: '+39', label: 'Italy (+39)', iso2: 'IT'),
  CountryCodeEntry(code: '+34', label: 'Spain (+34)', iso2: 'ES'),
  CountryCodeEntry(code: '+31', label: 'Netherlands (+31)', iso2: 'NL'),
  CountryCodeEntry(code: '+41', label: 'Switzerland (+41)', iso2: 'CH'),
  CountryCodeEntry(code: '+43', label: 'Austria (+43)', iso2: 'AT'),
  CountryCodeEntry(code: '+32', label: 'Belgium (+32)', iso2: 'BE'),
  CountryCodeEntry(code: '+46', label: 'Sweden (+46)', iso2: 'SE'),
  CountryCodeEntry(code: '+47', label: 'Norway (+47)', iso2: 'NO'),
  CountryCodeEntry(code: '+45', label: 'Denmark (+45)', iso2: 'DK'),
  CountryCodeEntry(code: '+358', label: 'Finland (+358)', iso2: 'FI'),
  CountryCodeEntry(code: '+353', label: 'Ireland (+353)', iso2: 'IE'),
  CountryCodeEntry(code: '+351', label: 'Portugal (+351)', iso2: 'PT'),
  CountryCodeEntry(code: '+48', label: 'Poland (+48)', iso2: 'PL'),
  CountryCodeEntry(code: '+420', label: 'Czech Republic (+420)', iso2: 'CZ'),
  CountryCodeEntry(code: '+36', label: 'Hungary (+36)', iso2: 'HU'),
  CountryCodeEntry(code: '+30', label: 'Greece (+30)', iso2: 'GR'),
  CountryCodeEntry(code: '+90', label: 'Turkey (+90)', iso2: 'TR'),
  CountryCodeEntry(code: '+7', label: 'Russia (+7)', iso2: 'RU'),
  CountryCodeEntry(code: '+380', label: 'Ukraine (+380)', iso2: 'UA'),
  CountryCodeEntry(code: '+971', label: 'UAE (+971)', iso2: 'AE'),
  CountryCodeEntry(code: '+966', label: 'Saudi Arabia (+966)', iso2: 'SA'),
  CountryCodeEntry(code: '+20', label: 'Egypt (+20)', iso2: 'EG'),
  CountryCodeEntry(code: '+254', label: 'Kenya (+254)', iso2: 'KE'),
  CountryCodeEntry(code: '+234', label: 'Nigeria (+234)', iso2: 'NG'),
  CountryCodeEntry(code: '+27', label: 'South Africa (+27)', iso2: 'ZA'),
  CountryCodeEntry(code: '+61', label: 'Australia (+61)', iso2: 'AU'),
  CountryCodeEntry(code: '+64', label: 'New Zealand (+64)', iso2: 'NZ'),
  CountryCodeEntry(code: '+55', label: 'Brazil (+55)', iso2: 'BR'),
  CountryCodeEntry(code: '+52', label: 'Mexico (+52)', iso2: 'MX'),
  CountryCodeEntry(code: '+54', label: 'Argentina (+54)', iso2: 'AR'),
  CountryCodeEntry(code: '+57', label: 'Colombia (+57)', iso2: 'CO'),
  CountryCodeEntry(code: '+233', label: 'Ghana (+233)', iso2: 'GH'),
  CountryCodeEntry(code: '+255', label: 'Tanzania (+255)', iso2: 'TZ'),
  CountryCodeEntry(code: '+256', label: 'Uganda (+256)', iso2: 'UG'),
  CountryCodeEntry(code: '+250', label: 'Rwanda (+250)', iso2: 'RW'),
  CountryCodeEntry(code: '+260', label: 'Zambia (+260)', iso2: 'ZM'),
  CountryCodeEntry(code: '+263', label: 'Zimbabwe (+263)', iso2: 'ZW'),
  CountryCodeEntry(code: '+267', label: 'Botswana (+267)', iso2: 'BW'),
  CountryCodeEntry(code: '+212', label: 'Morocco (+212)', iso2: 'MA'),
  CountryCodeEntry(code: '+213', label: 'Algeria (+213)', iso2: 'DZ'),
  CountryCodeEntry(code: '+216', label: 'Tunisia (+216)', iso2: 'TN'),
  CountryCodeEntry(code: '+237', label: 'Cameroon (+237)', iso2: 'CM'),
  CountryCodeEntry(code: '+225', label: 'Côte d\'Ivoire (+225)', iso2: 'CI'),
  CountryCodeEntry(code: '+221', label: 'Senegal (+221)', iso2: 'SN'),
  CountryCodeEntry(code: '+82', label: 'South Korea (+82)', iso2: 'KR'),
  CountryCodeEntry(code: '+852', label: 'Hong Kong (+852)', iso2: 'HK'),
  CountryCodeEntry(code: '+65', label: 'Singapore (+65)', iso2: 'SG'),
  CountryCodeEntry(code: '+60', label: 'Malaysia (+60)', iso2: 'MY'),
  CountryCodeEntry(code: '+62', label: 'Indonesia (+62)', iso2: 'ID'),
  CountryCodeEntry(code: '+66', label: 'Thailand (+66)', iso2: 'TH'),
  CountryCodeEntry(code: '+63', label: 'Philippines (+63)', iso2: 'PH'),
  CountryCodeEntry(code: '+84', label: 'Vietnam (+84)', iso2: 'VN'),
  CountryCodeEntry(code: '+92', label: 'Pakistan (+92)', iso2: 'PK'),
  CountryCodeEntry(code: '+880', label: 'Bangladesh (+880)', iso2: 'BD'),
  CountryCodeEntry(code: '+56', label: 'Chile (+56)', iso2: 'CL'),
  CountryCodeEntry(code: '+51', label: 'Peru (+51)', iso2: 'PE'),
  CountryCodeEntry(code: '+40', label: 'Romania (+40)', iso2: 'RO'),
  CountryCodeEntry(code: '+352', label: 'Luxembourg (+352)', iso2: 'LU'),
  CountryCodeEntry(code: '+354', label: 'Iceland (+354)', iso2: 'IS'),
  CountryCodeEntry(code: '+356', label: 'Malta (+356)', iso2: 'MT'),
  CountryCodeEntry(code: '+357', label: 'Cyprus (+357)', iso2: 'CY'),
  CountryCodeEntry(code: '+359', label: 'Bulgaria (+359)', iso2: 'BG'),
  CountryCodeEntry(code: '+385', label: 'Croatia (+385)', iso2: 'HR'),
  CountryCodeEntry(code: '+386', label: 'Slovenia (+386)', iso2: 'SI'),
  CountryCodeEntry(code: '+421', label: 'Slovakia (+421)', iso2: 'SK'),
  CountryCodeEntry(code: '+381', label: 'Serbia (+381)', iso2: 'RS'),
  CountryCodeEntry(code: '+375', label: 'Belarus (+375)', iso2: 'BY'),
];

const String defaultCountryCode = '+251';

/// Turn ISO 3166-1 alpha-2 (e.g. ET) into its flag emoji (🇪🇹).
String iso2ToFlag(String iso2) {
  if (iso2.length != 2) return '';
  return String.fromCharCodes(iso2.toUpperCase().codeUnits.map((c) => 0x1F1E6 - 65 + c));
}

/// The entry for [code], or null when the code is not in the list.
CountryCodeEntry? findCountryCode(String code) {
  for (final e in countryCodes) {
    if (e.code == code) return e;
  }
  return null;
}

/// Distinct dial codes, longest first, so "+251" is matched before "+25" or "+2".
final List<String> dialCodesLongestFirst = (countryCodes.map((e) => e.code).toSet().toList()
  ..sort((a, b) => b.length.compareTo(a.length)));
