import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/providers/purchase_provider.dart';
import 'package:housing_platform_mobile/features/purchase/widgets/purchase_form_steps.dart';

import 'purchase_form_notifier_test.dart' show FakePurchaseService;

/// Hosts the contact step against a real notifier so the phone round-trips through the form state.
class _Host extends ConsumerWidget {
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const _Host(this.notifier, {this.attempted = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: _Rebuilder(notifier: notifier, attempted: attempted),
        ),
      ),
    );
  }
}

class _Rebuilder extends StatefulWidget {
  final PurchaseFormNotifier notifier;
  final bool attempted;
  const _Rebuilder({required this.notifier, required this.attempted});
  @override
  State<_Rebuilder> createState() => _RebuilderState();
}

class _RebuilderState extends State<_Rebuilder> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) =>
      PurchaseContactStep(form: widget.notifier.state, notifier: widget.notifier, attempted: widget.attempted);
}

void main() {
  late PurchaseFormNotifier n;
  setUp(() => n = PurchaseFormNotifier(FakePurchaseService(), 'prop-1'));

  final phone = find.byKey(const Key('contact-phone'));
  final codeButton = find.byKey(const Key('country-code-button'));

  testWidgets('defaults to +251 and stores the national number as E.164', (tester) async {
    await tester.pumpWidget(_Host(n));
    expect(find.text('+251'), findsOneWidget);
    await tester.enterText(phone, '911 223 344');
    await tester.pump();
    expect(n.state.phone, '+251911223344');
    expect(n.state.contactErrors['phone'], isNull);
    expect(find.textContaining('Will be stored as +251 91 122 3344'), findsOneWidget);
  });

  testWidgets('drops the Ethiopian trunk 0', (tester) async {
    await tester.pumpWidget(_Host(n));
    await tester.enterText(phone, '0911223344');
    await tester.pump();
    expect(n.state.phone, '+251911223344');
  });

  testWidgets('switching the country re-prefixes the number', (tester) async {
    await tester.pumpWidget(_Host(n));
    await tester.enterText(phone, '4155551234');
    await tester.tap(codeButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-code-search')), 'usa');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-US')));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsOneWidget);
    expect(n.state.phone, '+14155551234');
  });

  testWidgets('pre-fills both controls from a stored international number', (tester) async {
    n.setPhone('+447911123456');
    await tester.pumpWidget(_Host(n));
    expect(find.text('+44'), findsOneWidget);
    expect(tester.widget<TextField>(find.descendant(of: phone, matching: find.byType(TextField))).controller!.text,
        '7911123456');
  });

  testWidgets('follows a later change to the stored number', (tester) async {
    await tester.pumpWidget(_Host(n));
    n.setPhone('+971501234567');
    await tester.pump();
    expect(find.text('+971'), findsOneWidget);
    expect(tester.widget<TextField>(find.descendant(of: phone, matching: find.byType(TextField))).controller!.text,
        '501234567');
  });

  testWidgets('re-selects the country when a full international number is pasted', (tester) async {
    await tester.pumpWidget(_Host(n));
    await tester.enterText(phone, '+1 415 555 1234');
    await tester.pump();
    expect(find.text('+1'), findsOneWidget);
    expect(tester.widget<TextField>(find.descendant(of: phone, matching: find.byType(TextField))).controller!.text,
        '4155551234');
    expect(n.state.phone, '+14155551234');
  });

  testWidgets('an empty number still shows the required error once attempted', (tester) async {
    await tester.pumpWidget(_Host(n, attempted: true));
    await tester.enterText(phone, '');
    await tester.pump();
    expect(n.state.phone, '');
    expect(find.text('Phone number is required.'), findsOneWidget);
  });
}
