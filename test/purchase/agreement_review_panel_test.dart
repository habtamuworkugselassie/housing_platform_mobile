import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/features/purchase/widgets/agreement_review_panel.dart';

/// Hosts the panel with local state so it behaves as it does inside the wizard.
class _Host extends StatefulWidget {
  final String content;
  final double maxHeight;
  const _Host({required this.content, this.maxHeight = 120});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool scrolled = false;
  bool accepted = false;
  String name = '';
  bool attempted = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            AgreementReviewPanel(
              title: 'Promise to Purchase Agreement',
              content: widget.content,
              version: 1,
              providerName: 'Dream Teams Trading PLC',
              scrolledToEnd: scrolled,
              accepted: accepted,
              signatoryName: name,
              attempted: attempted,
              maxHeight: widget.maxHeight,
              onScrolledToEnd: (v) => setState(() => scrolled = v),
              onAccepted: (v) => setState(() => accepted = v),
              onSignatoryName: (v) => setState(() => name = v),
            ),
            TextButton(onPressed: () => setState(() => attempted = true), child: const Text('attempt')),
          ]),
        ),
      ),
    );
  }
}

String longText() => List.generate(40, (i) => 'Clause ${i + 1}. The buyer promises things.').join('\n\n');

void main() {
  testWidgets('short texts count as read immediately', (tester) async {
    await tester.pumpWidget(const _Host(content: '# Short\n\nOne line.', maxHeight: 400));
    await tester.pumpAndSettle();
    expect(find.text('Read in full'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('agreement-signatory'))).enabled, isTrue);
  });

  testWidgets('long texts keep the signature disabled until scrolled to the end', (tester) async {
    await tester.pumpWidget(_Host(content: longText()));
    await tester.pumpAndSettle();
    expect(find.text('Scroll to read'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('agreement-signatory'))).enabled, isFalse);
    expect(tester.widget<CheckboxListTile>(find.byKey(const Key('agreement-accept'))).onChanged, isNull);

    await tester.tap(find.text('Jump to the end'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Read in full'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('agreement-signatory'))).enabled, isTrue);
  });

  testWidgets('validation appears only after an attempt, and input is forwarded', (tester) async {
    await tester.pumpWidget(const _Host(content: 'Short.', maxHeight: 400));
    await tester.pumpAndSettle();
    expect(find.text('You must accept the agreement to continue.'), findsNothing);
    await tester.tap(find.text('attempt'));
    await tester.pumpAndSettle();
    expect(find.text('You must accept the agreement to continue.'), findsOneWidget);
    expect(find.text('Enter your full name as your signature.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('agreement-signatory')), 'Abebe Kebede');
    await tester.tap(find.byKey(const Key('agreement-accept')));
    await tester.pumpAndSettle();
    expect(find.text('You must accept the agreement to continue.'), findsNothing);
    expect(find.text('Enter your full name as your signature.'), findsNothing);
  });
}
