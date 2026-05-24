// lib/viewmodels/theme_viewmodel.dart
// ---------------------------------------------------------------------------
// ThemeViewModel — manages app-wide ThemeMode (light / dark / system).
//
// Persists the user's choice in SharedPreferences so it survives restarts.
// Consumed by MaterialApp via Consumer<ThemeViewModel>.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_shop/core/base_viewmodel.dart';

/// Manages [ThemeMode] selection and persists it across app restarts.
///
/// Consumed in [main.dart] via `Consumer<ThemeViewModel>` to wire:
///   `theme:`, `darkTheme:`, `themeMode:`
///
/// Screens can access toggle methods via `context.read<ThemeViewModel>()`.
class ThemeViewModel extends BaseViewModel {
  // ─── Constants ────────────────────────────────────────────────────────────

  static const String _prefKey = 'app_theme';

  static const String _valueDark = 'dark';
  static const String _valueLight = 'light';
  static const String _valueSystem = 'system';

  // ─── State ────────────────────────────────────────────────────────────────

  ThemeMode _themeMode = ThemeMode.dark; // default to dark (existing behaviour)

  // ─── Constructor ──────────────────────────────────────────────────────────

  ThemeViewModel() {
    _loadTheme();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// Current [ThemeMode] to be passed to [MaterialApp.themeMode].
  ThemeMode get themeMode => _themeMode;

  /// `true` when the effective theme is dark.
  ///
  /// Note: for [ThemeMode.system] this always returns `false` — the system
  /// controls the actual brightness. Use [themeMode] directly for system-aware
  /// checks inside widgets (via `MediaQuery.platformBrightnessOf`).
  bool get isDark => _themeMode == ThemeMode.dark;

  /// `true` when the effective theme is light.
  bool get isLight => _themeMode == ThemeMode.light;

  /// `true` when following the system preference.
  bool get isSystem => _themeMode == ThemeMode.system;

  // ─── Toggle / set methods ─────────────────────────────────────────────────

  /// Switch to [ThemeMode.dark].
  void setDark() => _applyTheme(ThemeMode.dark);

  /// Switch to [ThemeMode.light].
  void setLight() => _applyTheme(ThemeMode.light);

  /// Follow the system (OS-level) dark / light preference.
  void setSystem() => _applyTheme(ThemeMode.system);

  /// Set a specific [ThemeMode].
  void setThemeMode(ThemeMode mode) => _applyTheme(mode);

  /// Toggle between [ThemeMode.dark] and [ThemeMode.light].
  /// If currently [ThemeMode.system], switches to [ThemeMode.dark].
  void toggle() {
    _applyTheme(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  /// Apply a new [ThemeMode], notify listeners, and persist the choice.
  void _applyTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveTheme(mode);
  }

  /// Load the persisted theme choice from SharedPreferences.
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      _themeMode = _fromString(saved);
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeViewModel: failed to load saved theme — $e');
    }
  }

  /// Persist the current [ThemeMode] to SharedPreferences.
  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _toString(mode));
    } catch (e) {
      debugPrint('ThemeViewModel: failed to save theme — $e');
    }
  }

  // ─── Serialisation helpers ────────────────────────────────────────────────

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _valueLight;
      case ThemeMode.system:
        return _valueSystem;
      case ThemeMode.dark:
        return _valueDark;
    }
  }

  ThemeMode _fromString(String? value) {
    switch (value) {
      case _valueLight:
        return ThemeMode.light;
      case _valueSystem:
        return ThemeMode.system;
      case _valueDark:
      default:
        return ThemeMode.dark;
    }
  }
}
