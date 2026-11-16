import 'package:flutter_test/flutter_test.dart';
import 'package:housing_platform_mobile/core/update/app_update.dart';

void main() {
  test('store builds (no SIDELOAD_UPDATES define) never offer an outside update', () async {
    expect(AppUpdateChecker.sideloadBuild, isFalse);
    expect(AppUpdateChecker.enabled, isFalse);
    // Returns before touching the network or platform channels.
    expect(await AppUpdateChecker.check(), isNull);
  });

  test('split-per-abi version codes compare as the pubspec build number', () {
    expect(AppUpdateChecker.flutterBuildNumber(2006), 6);
    expect(AppUpdateChecker.flutterBuildNumber(6), 6);
  });
}
