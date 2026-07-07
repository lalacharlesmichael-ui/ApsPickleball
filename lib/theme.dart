import 'package:flutter/material.dart';

class AppColors {
  static const Color green900 = Color(0xFF063B25);
  static const Color green800 = Color(0xFF0B5A36);
  static const Color green700 = Color(0xFF0F6F42);
  static const Color green600 = Color(0xFF168A4A);
  static const Color green100 = Color(0xFFDFF3E7);
  static const Color green50 = Color(0xFFF2FAF5);
  static const Color night = Color(0xFF061018);
  static const Color nightElevated = Color(0xFF111B24);
  static const Color nightCard = Color(0xFF1B2530);
  static const Color nightCardAlt = Color(0xFF25313B);
  static const Color neonGreen = Color(0xFF5BEA7E);
  static const Color mint = Color(0xFFA8F2BC);
  static const Color blush = Color(0xFFFFB7C8);
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
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceAlt: AppColors.green50,
    text: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    primary: AppColors.green600,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.green100,
    onPrimaryContainer: AppColors.green900,
    secondaryContainer: const Color(0xFFFFF3D0),
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.blue,
    onTertiary: AppColors.white,
    tertiaryContainer: const Color(0xFFDDEEFF),
    onTertiaryContainer: AppColors.ink,
    error: AppColors.red,
    onError: AppColors.white,
    errorContainer: const Color(0xFFFFE2DE),
    onErrorContainer: AppColors.red,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    canvas: AppColors.night,
    surface: AppColors.nightElevated,
    surfaceAlt: AppColors.nightCard,
    text: const Color(0xFFF1F7F3),
    muted: const Color(0xFFA7B4BE),
    line: const Color(0xFF263542),
    primary: AppColors.neonGreen,
    onPrimary: const Color(0xFF062014),
    primaryContainer: const Color(0xFF183825),
    onPrimaryContainer: const Color(0xFFD8FBE2),
    secondaryContainer: const Color(0xFF483715),
    onSecondaryContainer: const Color(0xFFFFE6A3),
    tertiary: const Color(0xFF83CAFF),
    onTertiary: const Color(0xFF071C2A),
    tertiaryContainer: const Color(0xFF12344E),
    onTertiaryContainer: const Color(0xFFDDEFFF),
    error: const Color(0xFFFF897D),
    onError: const Color(0xFF3A0804),
    errorContainer: const Color(0xFF541E18),
    onErrorContainer: const Color(0xFFFFDAD5),
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color brandText(BuildContext context) =>
      isDark(context) ? const Color(0xFFEAF8EE) : AppColors.green900;

  static Color brandAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFFBCEFCB) : AppColors.green700;

  static Color mutedText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color iconTileBackground(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color iconTileForeground(BuildContext context) =>
      isDark(context) ? const Color(0xFFBCEFCB) : AppColors.green700;

  static Color successContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color successOnContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;

  static Color? adaptiveSurfaceColor(BuildContext context, Color? color) {
    if (color == null || !isDark(context)) return color;
    if (color == AppColors.green50 || color == AppColors.green100) {
      return const Color(0xFF183825);
    }
    return color;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color surfaceAlt,
    required Color text,
    required Color muted,
    required Color line,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color secondaryContainer,
    required Color onSecondaryContainer,
    required Color tertiary,
    required Color onTertiary,
    required Color tertiaryContainer,
    required Color onTertiaryContainer,
    required Color error,
    required Color onError,
    required Color errorContainer,
    required Color onErrorContainer,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: AppColors.amber,
      onSecondary: AppColors.ink,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      outline: line,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: muted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Arial',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error),
        ),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
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
          foregroundColor: primary,
          minimumSize: const Size(0, 46),
          side: BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer,
        selectedColor: primary,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          color: onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        selectedIconTheme: IconThemeData(color: primary),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedIconTheme: IconThemeData(color: muted),
        unselectedLabelTextStyle: TextStyle(color: muted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
      dividerColor: line,
      iconTheme: IconThemeData(color: text),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        selectedColor: primary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: text,
        ),
      ),
    );
  }
}
