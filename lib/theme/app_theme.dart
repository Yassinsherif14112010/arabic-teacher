import 'package:flutter/material.dart';

/// App-wide color palette and theme definitions.
/// Mirrors the website's dark blue/purple aesthetic with Arabic RTL support.
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF3B82F6); // blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // blue-700
  static const Color primaryLight = Color(0xFF93C5FD); // blue-300

  // Accent
  static const Color purple = Color(0xFF8B5CF6);
  static const Color emerald = Color(0xFF10B981);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFEAB308);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0F172A); // slate-900
  static const Color darkCard = Color(0xFF1E293B); // slate-800
  static const Color darkBorder = Color(0xFF334155); // slate-700
  static const Color darkSidebar = Color(0xFF0D1526);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSidebar = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.purple,
        surface: AppColors.darkCard,
        onSurface: Colors.white,
        outline: AppColors.darkBorder,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      fontFamily: 'Cairo',
      textTheme: _textTheme(Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: _inputDecoration(
        fillColor: AppColors.darkBg,
        borderColor: AppColors.darkBorder,
        textColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBorder,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white70,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.purple,
        surface: AppColors.lightCard,
        onSurface: Color(0xFF0F172A),
        outline: AppColors.lightBorder,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      fontFamily: 'Cairo',
      textTheme: _textTheme(const Color(0xFF0F172A)),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCard,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      inputDecorationTheme: _inputDecoration(
        fillColor: AppColors.lightBg,
        borderColor: AppColors.lightBorder,
        textColor: const Color(0xFF0F172A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBorder,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: Color(0xFF334155),
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(Color base) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: base),
      displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: base),
      headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: base),
      headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: base),
      titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: base),
      titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: base),
      bodyLarge: TextStyle(
          fontFamily: 'Cairo', fontSize: 15, color: base),
      bodyMedium: TextStyle(
          fontFamily: 'Cairo', fontSize: 14, color: base),
      bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: base.withAlpha(153)),
      labelLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: base),
    );
  }

  static InputDecorationTheme _inputDecoration({
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
          fontFamily: 'Cairo', color: textColor.withAlpha(102), fontSize: 14),
      labelStyle: TextStyle(
          fontFamily: 'Cairo', color: textColor.withAlpha(153), fontSize: 14),
    );
  }
}
