import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppColors defines all palette constants for the dark gaming theme.
/// Dominant colors:
/// - Background: Deep cyber dark #080D12
/// - Card / Surface: Tech slate #111B24
/// - Primary: Neon Green #00E676
/// - Secondary: Electric Blue #00B0FF
/// - Error: Crimson Neon #FF5252
class AppColors {
  // Brand Neon Accent Colors
  static const Color primary = Color(0xFF00E676); // Neon Green
  static const Color primaryDark = Color(0xFF00B248);
  static const Color primaryLight = Color(0xFF66FFA6);

  static const Color secondary = Color(0xFF00B0FF); // Electric Blue
  static const Color secondaryDark = Color(0xFF0081CB);
  static const Color secondaryLight = Color(0xFF69E2FF);

  // Background and Surfaces
  static const Color background = Color(0xFF080D12); // Deep Space Dark
  static const Color surface = Color(0xFF111B24); // Card Navy Slate
  static const Color surfaceLight = Color(0xFF162330); // Elevated Slate
  static const Color surfaceLighter = Color(0xFF1E2D3D); // Hover / Highlight Slate
  static const Color card = Color(0xFF111B24);
  static const Color cardBackground = Color(0xFF111B24);
  static const Color cardBorder = Color(0xFF1E2D3D);
  static const Color divider = Color(0xFF1E2D3D);

  // Feedback and Status Colors
  static const Color error = Color(0xFFFF5252); // Red / Alert
  static const Color warning = Color(0xFFFFB300); // Amber / Caution
  static const Color success = Color(0xFF00E676); // Neon Green
  static const Color info = Color(0xFF00B0FF); // Electric Blue

  // Gaming Accents
  static const Color accentPurple = Color(0xFFB388FF);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color accentGold = Color(0xFFFFD700);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF607D8B);
  static const Color textDisabled = Color(0xFF455A64);

  // Convenient Aliases
  static const Color bgDark = Color(0xFF080D12);
  static const Color cardBg = Color(0xFF111B24);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E9E9E);

  // Glow Effects
  static List<BoxShadow> get neonGreenGlow => [
        BoxShadow(
          color: primary.withOpacity(0.35),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get electricBlueGlow => [
        BoxShadow(
          color: secondary.withOpacity(0.35),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get neonRedGlow => [
        BoxShadow(
          color: error.withOpacity(0.35),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];
}

/// AppTextStyles provides standardized text styles using Google Fonts:
/// - Orbitron for headers, titles, and cyber accents
/// - Rajdhani for body, metrics, tables, and buttons
class AppTextStyles {
  // Orbitron Headings (Cyber/Sci-Fi Gaming Feel)
  static TextStyle get headingLarge => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get headingMedium => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      );

  static TextStyle get headingSmall => GoogleFonts.orbitron(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      );

  // Rajdhani Modern Tech Typography
  static TextStyle get title => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get subtitle => GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.rajdhani(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.orbitron(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      );

  static TextStyle get caption => GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get currencyNumber => GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 0.5,
      );

  static TextStyle get statValue => GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );
}

/// AppTheme builds the ThemeData used throughout the application.
class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    final textTheme = GoogleFonts.rajdhaniTextTheme(base.textTheme).copyWith(
      displayLarge: AppTextStyles.headingLarge,
      displayMedium: AppTextStyles.headingMedium,
      displaySmall: AppTextStyles.headingSmall,
      headlineLarge: AppTextStyles.headingLarge.copyWith(fontSize: 22),
      headlineMedium: AppTextStyles.headingMedium,
      headlineSmall: AppTextStyles.headingSmall,
      titleLarge: AppTextStyles.headingSmall,
      titleMedium: AppTextStyles.title,
      titleSmall: AppTextStyles.subtitle,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.bodyMedium,
      labelSmall: AppTextStyles.caption,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      canvasColor: AppColors.surface,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingSmall.copyWith(
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          textStyle: AppTextStyles.button,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: AppTextStyles.button.copyWith(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        titleTextStyle: AppTextStyles.headingSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        disabledColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.2),
        secondarySelectedColor: AppColors.secondary.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: AppTextStyles.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.headingSmall.copyWith(fontSize: 13),
        unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceLight,
      ),
    );
  }
}
