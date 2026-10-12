import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/models/user_profile_model.dart';
import 'package:housing_platform_mobile/core/network/api_exceptions.dart';
import 'package:housing_platform_mobile/core/providers/auth_provider.dart';
import 'package:housing_platform_mobile/core/services/user_service.dart';
import 'package:housing_platform_mobile/features/profile/screens/password_screen.dart';
import 'package:housing_platform_mobile/features/profile/screens/payment_preferences_screen.dart';

class FakeUserService implements UserService {
  final calls = <Map<String, Object?>>[];
  Object? failWith;

  @override
  Future<UserProfile> changePassword({String? currentPassword, required String newPassword}) async {
    calls.add({'current': currentPassword, 'new': newPassword});
    if (failWith != null) throw failWith!;
    return profile(passwordSet: true);
  }

  @override
  Future<UserProfile> updatePaymentPreferences({String? method, String? phone}) async {
    calls.add({'method': method, 'phone': phone});
    return profile(method: method, phone: phone);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserProfile profile({bool? passwordSet, List<String> roles = const ['BUYER'], String? method, String? phone}) => UserProfile(
      id: 'u1',
      email: 'buyer@example.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      roles: roles,
      passwordSet: passwordSet,
      preferredPaymentMethod: method,
      paymentPhone: phone,
    );

Future<FakeUserService> pump(WidgetTester tester, Widget screen) async {
  final service = FakeUserService();
  await tester.pumpWidget(ProviderScope(
    overrides: [userServiceProvider.overrideWithValue(service)],
    child: MaterialApp(home: Builder(builder: (context) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
            child: const Text('open'),
          ),
        ),
      );
    })),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  test('profile JSON carries the password and payment fields', () {
    final p = UserProfile.fromJson({
      'id': 'u1',
      'email': 'b@x.et',
      'firstName': 'A',
      'lastName': 'B',
      'roles': ['BUYER'],
      'passwordSet': false,
      'preferredPaymentMethod': 'TELEBIRR',
      'paymentPhone': '+251911223344',
    });
    expect(p.passwordSet, isFalse);
    expect(p.needsCurrentPassword, isFalse);
    expect(p.preferredPaymentMethod, 'TELEBIRR');
    expect(p.paymentPhone, '+251911223344');
  });

  test('an unrecorded password state needs confirmation unless the account is buyer-only', () {
    expect(profile().needsCurrentPassword, isFalse);
    expect(profile(roles: ['REALTOR']).needsCurrentPassword, isTrue);
    expect(profile(passwordSet: true).needsCurrentPassword, isTrue);
  });

  testWidgets('a buyer without a password sets one without a current password', (tester) async {
    final service = await pump(tester, PasswordScreen(profile: profile(passwordSet: false)));
    expect(find.text('Set a password'), findsWidgets);
    expect(find.byKey(const Key('password-current')), findsNothing);
    expect(find.textContaining('buyer@example.com'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-new')), 'Secret123');
    await tester.enterText(find.byKey(const Key('password-confirm')), 'Secret123');
    await tester.ensureVisible(find.byKey(const Key('password-save')));
    await tester.tap(find.byKey(const Key('password-save')));
    await tester.pumpAndSettle();

    expect(service.calls.single, {'current': null, 'new': 'Secret123'});
    expect(find.byType(PasswordScreen), findsNothing);
  });

  testWidgets('changing a known password checks it locally and shows server errors', (tester) async {
    final service = await pump(tester, PasswordScreen(profile: profile(passwordSet: true)));
    expect(find.byKey(const Key('password-current')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-current')), 'Old12345');
    await tester.enterText(find.byKey(const Key('password-new')), 'weak');
    await tester.enterText(find.byKey(const Key('password-confirm')), 'weak');
    await tester.ensureVisible(find.byKey(const Key('password-save')));
    await tester.tap(find.byKey(const Key('password-save')));
    await tester.pump();
    expect(find.textContaining('At least 8 characters'), findsWidgets);
    expect(service.calls, isEmpty);

    service.failWith = const ApiException('Your current password is not correct');
    await tester.enterText(find.byKey(const Key('password-new')), 'Secret123');
    await tester.enterText(find.byKey(const Key('password-confirm')), 'Secret123');
    await tester.ensureVisible(find.byKey(const Key('password-save')));
    await tester.tap(find.byKey(const Key('password-save')));
    await tester.pumpAndSettle();
    expect(find.text('Your current password is not correct'), findsOneWidget);
    expect(service.calls.single['current'], 'Old12345');
  });

  testWidgets('payment preferences start from the saved ones and save the new choice', (tester) async {
    final service = await pump(
      tester,
      PaymentPreferencesScreen(profile: profile(method: 'CBE_BIRR', phone: '+251911223344')),
    );
    expect(find.text('+251911223344'), findsOneWidget);

    await tester.tap(find.byKey(const Key('method-TELEBIRR')));
    await tester.enterText(find.byKey(const Key('payment-phone')), ' 0922000000 ');
    await tester.ensureVisible(find.byKey(const Key('payment-save')));
    await tester.tap(find.byKey(const Key('payment-save')));
    await tester.pumpAndSettle();

    expect(service.calls.single, {'method': 'TELEBIRR', 'phone': '0922000000'});
  });

  testWidgets('the preference can be cleared', (tester) async {
    final service = await pump(tester, PaymentPreferencesScreen(profile: profile(method: 'MPESA')));
    await tester.tap(find.byKey(const Key('payment-clear')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('payment-save')));
    await tester.tap(find.byKey(const Key('payment-save')));
    await tester.pumpAndSettle();
    expect(service.calls.single, {'method': null, 'phone': null});
  });
}
