// lib/views/shared/adaptive_scaffold.dart
// ---------------------------------------------------------------------------
// AdaptiveScaffold — provides responsive navigation:
//   Mobile  → BottomNavigationBar (existing behaviour preserved)
//   Tablet  → NavigationRail (side navigation)
//   Desktop → NavigationRail with extended labels
//
// HOW TO ADOPT:
//   Replace the Scaffold + CustomBottomNavigationBar in main_screen.dart
//   with AdaptiveScaffold when you are ready to add tablet/desktop support.
//   The existing main_screen.dart is NOT modified here — this is additive.
//
// Usage example (when ready):
//   AdaptiveScaffold(
//     currentIndex: _currentIndex,
//     onDestinationSelected: (i) => setState(() => _currentIndex = i),
//     destinations: const [
//       AdaptiveDestination(icon: Icons.home, label: 'Home'),
//       AdaptiveDestination(icon: Icons.explore, label: 'Explore'),
//       AdaptiveDestination(icon: Icons.shopping_cart, label: 'Cart'),
//       AdaptiveDestination(icon: Icons.person, label: 'Profile'),
//     ],
//     body: _screens[_currentIndex],
//   )
// ---------------------------------------------------------------------------

import 'package:bike_shop/config/responsive.dart';
import 'package:flutter/material.dart';

/// Represents a single navigation destination used by [AdaptiveScaffold].
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

/// A scaffold that switches between [BottomNavigationBar] on mobile and
/// [NavigationRail] on tablet/desktop.
///
/// Drop-in replacement for the standard `Scaffold + BottomNavigationBar`
/// pattern, enabling tablet and desktop layouts with zero screen changes.
class AdaptiveScaffold extends StatelessWidget {
  /// The currently selected navigation index.
  final int currentIndex;

  /// Called when the user taps a navigation destination.
  final ValueChanged<int> onDestinationSelected;

  /// The list of navigation destinations (icons + labels).
  final List<AdaptiveDestination> destinations;

  /// The main content area.
  final Widget body;

  /// Optional app bar — only shown on mobile layout.
  final PreferredSizeWidget? appBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    if (isMobile) {
      // ── Mobile: bottom navigation bar (identical to existing behaviour) ───
      return Scaffold(
        appBar: appBar,
        body: body,
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

    // ── Tablet / Desktop: NavigationRail + body ───────────────────────────
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            // Show labels always on desktop, only on selected on tablet
            labelType: isDesktop
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
            extended: isDesktop,
            backgroundColor: theme.colorScheme.surface,
            selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
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
          // Vertical divider between rail and content
          const VerticalDivider(thickness: 1, width: 1),
          // Main content expands to fill remaining space
          Expanded(child: body),
        ],
      ),
    );
  }
}
