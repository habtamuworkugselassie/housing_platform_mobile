import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_config.dart';
import '../widgets/brand.dart';

/// Sideload update check. The website's publish pipeline writes
/// `/downloads/version.json` next to the APK ({"version","build","url","notes"}); on
/// launch the app compares `build` with its own build number and, when newer, offers
/// the download page. "Later" snoozes that build for a day; a newer build asks again.
class AppUpdateInfo {
  final String version;
  final int build;
  final String url;
  final String? notes;
  const AppUpdateInfo({required this.version, required this.build, required this.url, this.notes});
}

class AppUpdateChecker {
  static const _snoozeKey = 'update_snoozed_build';
  static const _snoozeUntilKey = 'update_snoozed_until';

  static Uri get manifestUri => Uri.parse('${ApiConfig.baseOrigin}/downloads/version.json');

  /// Returns the published update when it is newer than the running build and not
  /// snoozed; null otherwise. Never throws: an offline launch simply skips the check.
  static Future<AppUpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final installed = flutterBuildNumber(int.tryParse(info.buildNumber) ?? 0);
      final res = await Dio().getUri(
        manifestUri,
        options: Options(responseType: ResponseType.plain, receiveTimeout: const Duration(seconds: 6), sendTimeout: const Duration(seconds: 6)),
      );
      final data = json.decode(res.data as String) as Map<String, dynamic>;
      final build = (data['build'] as num?)?.toInt() ?? 0;
      if (build <= installed) return null;
      final prefs = await SharedPreferences.getInstance();
      final snoozedBuild = prefs.getInt(_snoozeKey) ?? 0;
      final snoozedUntil = prefs.getInt(_snoozeUntilKey) ?? 0;
      if (snoozedBuild == build && DateTime.now().millisecondsSinceEpoch < snoozedUntil) return null;
      return AppUpdateInfo(
        version: (data['version'] ?? '').toString(),
        build: build,
        url: (data['url'] ?? '${ApiConfig.baseOrigin}/download.html').toString(),
        notes: data['notes']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> snooze(int build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_snoozeKey, build);
    await prefs.setInt(_snoozeUntilKey, DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
  }

  /// `flutter build apk --split-per-abi` offsets versionCode by ABI (1000 + n for
  /// armeabi-v7a, 2000 + n for arm64-v8a, 3000 + n for x86_64, 4000 + n for x86); strip it
  /// so the comparison is against the pubspec build number.
  static int flutterBuildNumber(int versionCode) => versionCode >= 1000 ? versionCode % 1000 : versionCode;
}

final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) => AppUpdateChecker.check());

/// Shows the update sheet once per launch when a newer build is published.
Future<void> maybeShowUpdateSheet(BuildContext context, AppUpdateInfo? update) async {
  if (update == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _UpdateSheet(update: update),
  );
}

class _UpdateSheet extends StatelessWidget {
  final AppUpdateInfo update;
  const _UpdateSheet({required this.update});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: BrandPanel(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EyebrowPill('Update available', onDark: true),
              const SizedBox(height: 14),
              Text(
                'Ethio Build Connect ${update.version}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                update.notes?.trim().isNotEmpty == true
                    ? update.notes!.trim()
                    : 'A newer version is ready. Download it from the website and install it over this one; your sign-in stays.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 20),
              GoldButton(
                label: 'Download update',
                icon: LucideIcons.download,
                expand: true,
                onPressed: () async {
                  final uri = Uri.parse(update.url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await AppUpdateChecker.snooze(update.build);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.8), minimumSize: const Size.fromHeight(44)),
                child: const Text('Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
