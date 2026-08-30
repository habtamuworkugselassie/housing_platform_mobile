import 'package:flutter/material.dart';

/// Light brand theme, aligned with the web portal:
/// violet (#7C3AED) primary on light surfaces, dark text, gold accent.
class AppTheme {
  // Brand / accent (violet-600 family, matches web `primary`).
  static const Color primaryColor = Color(0xFF7C3AED); // violet-600
  static const Color primaryColorLight = Color(0xFFA78BFA); // violet-400
  static const Color primaryColorDark = Color(0xFF6D28D9); // violet-700

  /// Brand gold accent (web `gold`).
  static const Color gold = Color(0xFFD99F3F);

  // Backgrounds & surfaces (light).
  static const Color scaffoldBackgroundColor = Color(0xFFF7F7FB); // light violet-tinted
  static const Color surfaceColor = Color(0xFFFFFFFF); // white cards
  static const Color surfaceMuted = Color(0xFFF5F3FF); // violet-50 sections
  static const Color borderColor = Color(0xFFE5E7EB); // gray-200

  // Text colors.
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400
  static const Color textLight = Color(0xFFFFFFFF); // on primary / dark surfaces

  // Status colors.
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  /// Twitter-style blue for verified badge (#1DA1F2).
  static const Color verifiedBadgeBlue = Color(0xFF1DA1F2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColorDark,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),

      // Typography relying on default system font (San Francisco on Apple, Roboto on Android)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(
            color: textPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(
            color: textSecondary, fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(
            color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
      ),

      // Component Themes
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(((0.06) * 255).toInt()),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
    );
  }
}
