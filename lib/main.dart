import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'features/marketplace/screens/root_screen.dart';

void main() {
  runApp(const HousingPlatformMobileApp());
}

class HousingPlatformMobileApp extends StatelessWidget {
  const HousingPlatformMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habte Real Estate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootScreen(),
    );
  }
}
