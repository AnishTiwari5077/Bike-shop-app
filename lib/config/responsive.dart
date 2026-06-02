// lib/config/responsive.dart
// ---------------------------------------------------------------------------
// Responsive — static helper for breakpoint-aware layout decisions.
//
// Usage in widgets:
//   int cols = Responsive.gridColumns(context);
//   double pad = Responsive.horizontalPadding(context);
//   double scale = Responsive.fontScale(context);
//
// Breakpoints (based on material.io guidelines):
//   mobile  : width < 600
//   tablet  : 600 ≤ width < 1200
//   desktop : width ≥ 1200
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Provides static utility methods for responsive layout decisions.
///
/// All methods accept a [BuildContext] and use [MediaQuery] to determine
/// the current screen width. No state is held — fully functional and safe
/// to call anywhere in the widget tree.
class Responsive {
  Responsive._(); // prevent instantiation

  // ─── Breakpoints ──────────────────────────────────────────────────────────

  /// Maximum width (exclusive) for a mobile layout.
  static const double mobileBreakpoint = 600;

  /// Maximum width (exclusive) for a tablet layout.
  static const double tabletBreakpoint = 1200;

  // ─── Breakpoint checks ────────────────────────────────────────────────────

  /// Returns `true` when the screen width is below [mobileBreakpoint] (< 600).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns `true` when the screen width is between [mobileBreakpoint] and
  /// [tabletBreakpoint] (600 ≤ width < 1200).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns `true` when the screen width is at or above [tabletBreakpoint]
  /// (width ≥ 1200).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  // ─── Layout helpers ───────────────────────────────────────────────────────

  /// Returns the recommended number of grid columns for the current device:
  /// - Mobile  → 2
  /// - Tablet  → 3
  /// - Desktop → 4
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2; // mobile default
  }

  /// Shorthand: value for [mobile], [tablet], [desktop]
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Returns the recommended horizontal padding for content areas:
  /// - Mobile  → 16.0
  /// - Tablet  → 32.0
  /// - Desktop → 64.0
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 64.0;
    if (isTablet(context)) return 32.0;
    return 16.0; // mobile default
  }

  /// Returns a font scale multiplier for the current device:
  /// - Mobile  → 1.0 (baseline)
  /// - Tablet  → 1.1
  /// - Desktop → 1.2
  static double fontScale(BuildContext context) {
    if (isDesktop(context)) return 1.2;
    if (isTablet(context)) return 1.1;
    return 1.0; // mobile default
  }

  /// Returns the full screen width minus [horizontalPadding] on each side.
  /// Useful for calculating content widths in padded layouts.
  static double contentWidth(BuildContext context) {
    final pad = horizontalPadding(context);
    return MediaQuery.sizeOf(context).width - pad * 2;
  }

  // ─── LayoutBuilder-compatible helpers ────────────────────────────────────
  // Use these inside a LayoutBuilder so the widget responds to its own
  // available width rather than the full screen width.
  // This is the correct pattern when content lives inside a constrained
  // parent (e.g. NavigationRail, Dialog, SidePanel).

  /// Resolves the number of grid columns from [BoxConstraints] and [Orientation].
  /// Use inside a [LayoutBuilder] instead of [gridColumns].
  static int gridColumnsFromConstraints(BoxConstraints constraints, [Orientation? orientation]) {
    if (constraints.maxWidth >= tabletBreakpoint) return 4;
    if (constraints.maxWidth >= mobileBreakpoint) return 3;
    return 2;
  }

  /// Resolves a typed value from [BoxConstraints] and [Orientation].
  /// Use inside a [LayoutBuilder] instead of [value].
  static T valueFromConstraints<T>(
    BoxConstraints constraints, {
    required T mobile,
    T? tablet,
    T? desktop,
    Orientation? orientation,
  }) {
    if (constraints.maxWidth >= tabletBreakpoint) return desktop ?? tablet ?? mobile;
    if (constraints.maxWidth >= mobileBreakpoint) return tablet ?? mobile;
    return mobile;
  }

  /// Resolves horizontal padding from [BoxConstraints].
  /// Use inside a [LayoutBuilder] instead of [horizontalPadding].
  static double horizontalPaddingFromConstraints(BoxConstraints constraints) {
    if (constraints.maxWidth >= tabletBreakpoint) return 64.0;
    if (constraints.maxWidth >= mobileBreakpoint) return 32.0;
    return 16.0;
  }
}
