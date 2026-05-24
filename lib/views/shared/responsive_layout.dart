// lib/views/shared/responsive_layout.dart
// ---------------------------------------------------------------------------
// ResponsiveLayout — renders different widget trees based on screen width.
//
// Usage:
//   ResponsiveLayout(
//     mobile:  MobileProductGrid(),
//     tablet:  TabletProductGrid(),
//     desktop: DesktopProductGrid(),
//   )
//
// Only [mobile] is required. [tablet] falls back to [mobile] if omitted.
// [desktop] falls back to [tablet] (or [mobile]) if omitted.
// ---------------------------------------------------------------------------

import 'package:bike_shop/config/responsive.dart';
import 'package:flutter/material.dart';

/// A layout widget that renders a different child depending on device width.
///
/// Uses [Responsive] breakpoints:
///   - Mobile  (< 600px)  → renders [mobile]
///   - Tablet  (600–1200) → renders [tablet] ?? [mobile]
///   - Desktop (≥ 1200px) → renders [desktop] ?? [tablet] ?? [mobile]
class ResponsiveLayout extends StatelessWidget {
  /// Widget shown on mobile screens (required, used as fallback).
  final Widget mobile;

  /// Widget shown on tablet screens. Falls back to [mobile] if null.
  final Widget? tablet;

  /// Widget shown on desktop screens. Falls back to [tablet] or [mobile] if null.
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Builder variant of [ResponsiveLayout] for cases where the widget needs
/// access to [BuildContext] inside each branch.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Responsive.isMobile(context),
      Responsive.isTablet(context),
      Responsive.isDesktop(context),
    );
  }
}
