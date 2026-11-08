import 'package:flutter/material.dart';

/// Light brand theme, aligned with the web portal:
/// violet (#7C3AED) primary on light surfaces, dark text, gold accent.
class AppTheme {
  // Brand / accent (violet-600 family, matches web `primary`).
  static const Color primaryColor = Color(0xFF7C3AED); // violet-600
  static const Color primaryColorLight = Color(0xFFA78BFA); // violet-400
  static const Color primaryColorDark = Color(0xFF6D28D9); // violet-700

  /// Brand gold accent (web `gold-600`): borders, small marks on light surfaces.
  static const Color gold = Color(0xFFD99F3F);

  /// Gold call-to-action fill (web `gold-400`) and its hover/pressed step (`gold-300`).
  static const Color goldBright = Color(0xFFF4C977);
  static const Color goldLight = Color(0xFFF6D68F);
  static const Color goldText = Color(0xFF94631C); // gold-800, legible on gold-100/violet-50

  /// Deep violets of the public shell (web `primary-900` / `primary-950`): panels, splash,
  /// the floating nav. Everything dark in the app sits on this one scale.
  static const Color brandPanel = Color(0xFF4C1D95); // violet-900: raised panels
  static const Color brandDeep = Color(0xFF2E1065); // violet-950: shell chrome, nav, splash
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet100 = Color(0xFFEDE9FE);

  /// Corner radii shared with the web design: cards 20, panels 28, pills stadium.
  static const double radiusCard = 20;
  static const double radiusPanel = 28;
  static const double radiusInput = 14;

  /// The soft violet drop shadow cards and panels carry.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: brandDeep.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
  static List<BoxShadow> get panelShadow => [
        BoxShadow(
          color: brandDeep.withValues(alpha: 0.35),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
      ];

  /// Light card: white, 1px border, 20px corners, soft shadow.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      );

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
            color: textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.08),
        displayMedium: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
        headlineMedium: TextStyle(
            color: textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.08),
        headlineSmall: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
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
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: borderColor),
        ),
      ),

      // Buttons are pills, as on the web.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColorDark,
          backgroundColor: surfaceColor,
          side: const BorderSide(color: Color(0xFFC4B5FD), width: 1.5), // violet-300
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: borderColor)),
        backgroundColor: surfaceColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        side: const BorderSide(color: borderColor),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: StadiumBorder(),
        extendedTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPanel)),
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusPanel)),
        ),
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusInput)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error, width: 2),
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
