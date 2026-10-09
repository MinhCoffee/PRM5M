import 'package:flutter/material.dart';

abstract final class AppColors {
  static const surface = Color(0xFFF8F9FF);
  static const surfaceLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceHigh = Color(0xFFDCE9FF);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF404751);
  static const outline = Color(0xFF717882);
  static const outlineVariant = Color(0xFFC0C7D3);
  static const primary = Color(0xFF0072BC);
  static const primaryDark = Color(0xFF005994);
  static const secondary = Color(0xFF35618D);
  static const tertiary = Color(0xFFBA4C00);
  static const orange = Color(0xFFF36F21);
  static const green = Color(0xFF6CB33F);
  static const error = Color(0xFFD93025);
  static const errorContainer = Color(0xFFFCE8E6);
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0F2FE),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1E4FF),
      onSecondaryContainer: Color(0xFF184974),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: Color(0xFF93000A),
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.surface,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 20, height: 1.4, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 14, height: 1.43, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, height: 1.47),
        bodyMedium: TextStyle(fontSize: 14, height: 1.43),
        bodySmall: TextStyle(fontSize: 13, height: 1.38),
        labelLarge: TextStyle(fontSize: 13, height: 1.23, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, height: 1.33, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 11, height: 1.27, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}