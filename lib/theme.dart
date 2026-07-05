import 'package:flutter/material.dart';

class AppColors {
  static const Color green900 = Color(0xFF063B25);
  static const Color green800 = Color(0xFF0B5A36);
  static const Color green700 = Color(0xFF0F6F42);
  static const Color green600 = Color(0xFF168A4A);
  static const Color green100 = Color(0xFFDFF3E7);
  static const Color green50 = Color(0xFFF2FAF5);
  static const Color ink = Color(0xFF14221B);
  static const Color muted = Color(0xFF62746B);
  static const Color line = Color(0xFFD9E8DF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF7FBF6);
  static const Color amber = Color(0xFFF4B63F);
  static const Color red = Color(0xFFD94A3A);
  static const Color blue = Color(0xFF2F80C0);
  static const Color gray = Color(0xFF87928D);

  static const Color white = surface;
  static const Color black = ink;
  static const Color successGreen = green600;
  static const Color errorRed = red;
  static const Color darkGray = muted;
  static const Color lightGray = canvas;
  static const Color borderGray = line;
}

class AppTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.green600,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.green100,
      onPrimaryContainer: AppColors.green900,
      secondary: AppColors.amber,
      onSecondary: AppColors.ink,
      secondaryContainer: Color(0xFFFFF3D0),
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.blue,
      onTertiary: AppColors.white,
      tertiaryContainer: Color(0xFFDDEEFF),
      onTertiaryContainer: AppColors.ink,
      error: AppColors.red,
      onError: AppColors.white,
      errorContainer: Color(0xFFFFE2DE),
      onErrorContainer: AppColors.red,
      outline: AppColors.line,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.green50,
      onSurfaceVariant: AppColors.muted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Arial',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.green600, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green700,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: AppColors.green600, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green700,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.green100,
        selectedColor: AppColors.green600,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.green600),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.green700,
          fontWeight: FontWeight.w800,
        ),
        unselectedIconTheme: IconThemeData(color: AppColors.muted),
        unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.green600,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.line,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
