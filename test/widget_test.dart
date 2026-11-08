import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/theme/theme.dart';
import 'package:housing_platform_mobile/core/widgets/brand.dart';
import 'package:housing_platform_mobile/core/widgets/custom_bottom_nav.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: child));

  testWidgets('brand primitives render their copy', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [
      EyebrowPill('Ethio Build Connect Expo'),
      SectionHeader(eyebrow: 'Properties', title: 'Explore', subtitle: 'Browse every listing'),
      TierBadge('Exclusive', gold: true),
    ])));
    expect(find.text('ETHIO BUILD CONNECT EXPO'), findsOneWidget);
    expect(find.text('PROPERTIES'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Browse every listing'), findsOneWidget);
    expect(find.text('EXCLUSIVE'), findsOneWidget);
  });

  testWidgets('gold button fires and shows a spinner while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(GoldButton(label: 'Register', onPressed: () => taps++)));
    await tester.tap(find.text('Register'));
    expect(taps, 1);

    await tester.pumpWidget(wrap(GoldButton(label: 'Register', loading: true, onPressed: () => taps++)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Register'), findsNothing);
  });

  testWidgets('bottom nav shows four public tabs and two more when signed in', (tester) async {
    int? tapped;
    await tester.pumpWidget(wrap(CustomBottomNavBar(currentIndex: 0, isAuthenticated: false, onTap: (i) => tapped = i)));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    await tester.tap(find.text('Live'));
    expect(tapped, 3);

    await tester.pumpWidget(wrap(CustomBottomNavBar(currentIndex: 5, isAuthenticated: true, onTap: (i) => tapped = i)));
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('theme buttons are pills', (tester) async {
    await tester.pumpWidget(wrap(ElevatedButton(onPressed: () {}, child: const Text('Go'))));
    final style = tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style ??
        Theme.of(tester.element(find.byType(ElevatedButton))).elevatedButtonTheme.style!;
    expect(style.shape?.resolve({}), isA<StadiumBorder>());
  });
}
