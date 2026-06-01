// lib/views/shared/adaptive_scaffold.dart
// ---------------------------------------------------------------------------
// AdaptiveScaffold — Responsive navigation (FIXED VERSION)
// Mobile  → BottomNavigationBar
// Tablet  → NavigationRail (compact)
// Desktop → NavigationRail (extended)
// ---------------------------------------------------------------------------

import 'package:bike_shop/config/responsive.dart';
import 'package:flutter/material.dart';

/// Navigation item model
class AdaptiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Responsive scaffold
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  }) : assert(
         destinations.length >= 2,
         'BottomNavigationBar requires at least 2 destinations.',
       );

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    // ───────────────────────── MOBILE ─────────────────────────
    if (isMobile) {
      return Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: body,
        ), // Prevents content bleeding into system bars
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.selectedIcon ?? d.icon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      );
    }

    // ───────────────────── TABLET + DESKTOP ─────────────────────
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,

              // ✅ FIXED: extended is only true when labelType is none
              extended: isDesktop,
              labelType: isDesktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType
                        .all, // Shows compact labels on tablet

              backgroundColor: theme.colorScheme.surface,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),

              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon ?? d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),

            const VerticalDivider(width: 1, thickness: 1),

            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
