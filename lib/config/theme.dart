import 'package:flutter/material.dart';

class AppTheme {
  // ─── Shared Color Constants ────────────────────────────────────────────────
  // These are used by both themes and can be referenced from any screen.

  static const Color primaryBackground = Color(0xFF0A192F);
  static const Color secondaryBackground = Color(0xFF1E1E2E);
  static const Color cardBackground = Color(0xFF1E1E2E);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;

  // ─── Light theme color palette ────────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF0F4F8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF0A192F);
  static const Color _lightTextSecondary = Color(0xFF4A5568);
  static const Color _lightTextTertiary = Color(0xFF718096);

  // ─── Gradients ────────────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C3448), Color(0xFF0C1C2D)],
  );

  static LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentBlue.withValues(alpha: .7)],
  );

  // ─── Dark Theme (existing — unchanged) ────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentCyan,
        surface: secondaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: textTertiary),
      ),
    );
  }

  // ─── Light Theme (new) ────────────────────────────────────────────────────
  // Mirrors the structure of darkTheme with light-appropriate colors.
  // Preserves the same shape radii, button styles, and input styles.

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        secondary: accentCyan,
        surface: _lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        hintStyle: TextStyle(color: _lightTextTertiary),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _lightTextPrimary),
        bodyMedium: TextStyle(color: _lightTextSecondary),
        bodySmall: TextStyle(color: _lightTextTertiary),
        titleLarge: TextStyle(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

