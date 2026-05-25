// lib/config/theme.dart
// ---------------------------------------------------------------------------
// AppTheme — light and dark theme definitions.
//
// LIGHT THEME FIX:
//   - cardColor / cardTheme: soft warm-white surface (#FFFFFF) with a gentle
//     grey shadow instead of the nearly-invisible 0.05-alpha overlay
//   - onSurface: near-black (#1A202C) instead of white-on-white
//   - ListTile tileColor: explicit cardColor so the Material splash is visible
//   - InputDecoration fillColor: light grey (#F7F8FA) for clear field contrast
//   - Removed Colors.white* usage from theme layer — screens use colorScheme
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AppTheme {
  // ─── Shared Brand Colors ──────────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);

  // ─── Dark palette (unchanged) ─────────────────────────────────────────────
  static const Color primaryBackground = Color(0xFF0A192F);
  static const Color secondaryBackground = Color(0xFF1E1E2E);
  static const Color cardBackground = Color(0xFF1E1E2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;

  // ─── Light palette ────────────────────────────────────────────────────────
  // Uses Material-3 tonal surface pattern:
  //   background → slightly warm off-white
  //   surface    → pure white cards
  //   onSurface  → near-black (#1A202C) for full WCAG AA contrast
  static const Color _lightBg = Color(0xFFF0F4F8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightInputFill = Color(0xFFF0F2F5);
  static const Color _lightOnSurface = Color(0xFF1A202C);
  static const Color _lightOnSurfaceMuted = Color(0xFF4A5568);
  static const Color _lightOnSurfaceTertiary = Color(0xFF718096);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C3448), Color(0xFF0C1C2D)],
  );

  static LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, Color(0xFF2563EB)],
  );

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentCyan,
        surface: secondaryBackground,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackground,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: cardBackground,
        iconColor: Colors.white70,
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
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12),
    );
  }

  // ─── Light Theme ──────────────────────────────────────────────────────────
  // KEY FIXES vs old version:
  //   1. cardTheme.color = #FFFFFF with subtle shadow (elevation 2)
  //   2. listTileTheme.tileColor = _lightCard so Material splash is visible
  //   3. inputDecorationTheme.fillColor = _lightInputFill (visible grey)
  //   4. colorScheme.onSurface = _lightOnSurface (near-black, high contrast)
  //   5. appBarTheme.foregroundColor = _lightOnSurface (icons readable)
  //   6. textTheme fully specified so Text() without explicit color works
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.light(
        primary: accentBlue,
        secondary: accentCyan,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        onPrimary: Colors.white,
        // Used by Card, Dialog, BottomSheet backgrounds
        surfaceContainerHighest: _lightCard,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBg,
        elevation: 0,
        centerTitle: false,
        foregroundColor: _lightOnSurface,
        titleTextStyle: TextStyle(
          color: _lightOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _lightOnSurface),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 0.5),
        ),
      ),
      // CRITICAL: tileColor must be set so Material over cardColor is visible
      listTileTheme: ListTileThemeData(
        tileColor: _lightCard,
        textColor: _lightOnSurface,
        iconColor: _lightOnSurfaceMuted,
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightOnSurfaceMuted,
          side: const BorderSide(color: _lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentBlue),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Slightly grey so the field is visually distinct from the white card
        fillColor: _lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        hintStyle: TextStyle(color: _lightOnSurfaceTertiary),
        labelStyle: TextStyle(color: _lightOnSurfaceMuted),
      ),
      dividerTheme: const DividerThemeData(color: _lightBorder),
      // Full textTheme: avoids invisible text when TextStyle(color:…) is omitted
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _lightOnSurface),
        bodyMedium: TextStyle(color: _lightOnSurfaceMuted),
        bodySmall: TextStyle(color: _lightOnSurfaceTertiary),
        labelLarge: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: _lightOnSurfaceMuted),
        labelSmall: TextStyle(color: _lightOnSurfaceTertiary),
      ),
      iconTheme: IconThemeData(color: _lightOnSurfaceMuted),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentBlue : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accentBlue.withValues(alpha: 0.4)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  // ─── Convenience: cardColor for the current theme ──────────────────────────
  // Usage: Theme.of(context).cardColor  →  white in light, dark-grey in dark
  // Note: ThemeData.cardColor is deprecated in M3 — use cardTheme.color instead.
  // Screens use: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface
}
