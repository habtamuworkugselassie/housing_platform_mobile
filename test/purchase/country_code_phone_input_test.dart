import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/features/auth/widgets/country_code_phone_input.dart';

class _Host extends StatefulWidget {
  final String initial;
  const _Host({this.initial = '+251'});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String code = widget.initial;
  final controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CountryCodePhoneInput(
            fieldKey: const Key('phone'),
            countryCode: code,
            onCountryCodeChanged: (v) => setState(() => code = v),
            phoneController: controller,
          ),
          Text('code=$code', key: const Key('current')),
        ]),
      ),
    );
  }
}

void main() {
  testWidgets('shows the flag and dial code of the selected country', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(find.text('🇪🇹'), findsOneWidget);
    expect(find.text('+251'), findsOneWidget);
  });

  testWidgets('opens a searchable picker and reports the chosen country', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.byKey(const Key('country-code-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('country-code-search')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('country-code-search')), 'kenya');
    await tester.pumpAndSettle();
    expect(find.text('Kenya (+254)'), findsOneWidget);
    expect(find.text('Ethiopia (+251)'), findsNothing);

    await tester.tap(find.byKey(const Key('country-option-KE')));
    await tester.pumpAndSettle();
    expect(find.text('code=+254'), findsOneWidget);
    expect(find.text('🇰🇪'), findsOneWidget);
  });

  testWidgets('searching by dial code works and an empty result says so', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.byKey(const Key('country-code-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-code-search')), '971');
    await tester.pumpAndSettle();
    expect(find.text('UAE (+971)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('country-code-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No countries match'), findsOneWidget);
  });

  testWidgets('falls back to Ethiopia when given a code that is not in the list', (tester) async {
    await tester.pumpWidget(const _Host(initial: '+999'));
    expect(find.text('+251'), findsOneWidget);
  });
}
