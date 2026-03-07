import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'features/splash/screens/splash_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HousingPlatformMobileApp(),
    ),
  );
}

class HousingPlatformMobileApp extends ConsumerWidget {
  const HousingPlatformMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Real Estate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
