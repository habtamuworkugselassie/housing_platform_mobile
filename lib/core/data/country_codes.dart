/// Country calling codes for phone inputs (aligned with frontend).
class CountryCodeEntry {
  final String code;
  final String label;
  final String iso2;

  const CountryCodeEntry({required this.code, required this.label, required this.iso2});
}

const List<CountryCodeEntry> countryCodes = [
  CountryCodeEntry(code: '+251', label: 'Ethiopia (+251)', iso2: 'ET'),
  CountryCodeEntry(code: '+1', label: 'USA/Canada (+1)', iso2: 'US'),
  CountryCodeEntry(code: '+44', label: 'UK (+44)', iso2: 'GB'),
  CountryCodeEntry(code: '+91', label: 'India (+91)', iso2: 'IN'),
  CountryCodeEntry(code: '+254', label: 'Kenya (+254)', iso2: 'KE'),
  CountryCodeEntry(code: '+234', label: 'Nigeria (+234)', iso2: 'NG'),
  CountryCodeEntry(code: '+27', label: 'South Africa (+27)', iso2: 'ZA'),
  CountryCodeEntry(code: '+971', label: 'UAE (+971)', iso2: 'AE'),
  CountryCodeEntry(code: '+966', label: 'Saudi Arabia (+966)', iso2: 'SA'),
  CountryCodeEntry(code: '+20', label: 'Egypt (+20)', iso2: 'EG'),
  CountryCodeEntry(code: '+255', label: 'Tanzania (+255)', iso2: 'TZ'),
  CountryCodeEntry(code: '+256', label: 'Uganda (+256)', iso2: 'UG'),
  CountryCodeEntry(code: '+233', label: 'Ghana (+233)', iso2: 'GH'),
  CountryCodeEntry(code: '+86', label: 'China (+86)', iso2: 'CN'),
  CountryCodeEntry(code: '+81', label: 'Japan (+81)', iso2: 'JP'),
  CountryCodeEntry(code: '+49', label: 'Germany (+49)', iso2: 'DE'),
  CountryCodeEntry(code: '+33', label: 'France (+33)', iso2: 'FR'),
  CountryCodeEntry(code: '+61', label: 'Australia (+61)', iso2: 'AU'),
];

const String defaultCountryCode = '+251';
