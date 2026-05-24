Bike Shop MVVM & Routing Implementation Guide

Bike Shop app — MVVM fixes + routing migration
8 phases · step-by-step implementation reference

Phase 1 — Fix Critical Bugs First

Priority: Critical
Estimated Time: ~15 min

1. Circular navigation — empty cart pushes HomeScreen

File: lib/views/cart_screen.dart → _buildEmptyState()

Problem

The empty cart button pushes a new HomeScreen onto the stack.

This creates:

duplicate HomeScreen instances
broken back navigation
unnecessary stack growth
Before
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const HomeScreen()),
),
After — Option A

If CartScreen was pushed from MainScreen:

onPressed: () => Navigator.pop(context),
After — Option B

If CartScreen is shown as a tab:

// In MainScreen:
onGoHome: () => setState(() => _currentIndex = 0)

// Then in CartScreen:
onPressed: widget.onGoHome,
Important

Remove this import afterward:

import 'home_screen.dart';
2. pushReplacement destroys back stack in product details

File: lib/views/product_details_screen.dart → _buildBottomBar()

Problem

Using pushReplacement() removes ProductDetailScreen from the stack.

Users cannot return to the product page after viewing cart.

Before
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const CartScreen()),
);
After
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CartScreen()),
);
Phase 2 — Fix Hardcoded Colors.white* (Critical Screens)

Priority: High
Estimated Time: ~45 min

Theme Mapping Rules
Hardcoded Color	Replace With
Colors.white	colorScheme.onSurface
Colors.white70	.withValues(alpha: 0.7)
Colors.white60	.withValues(alpha: 0.6)
Colors.white54	.withValues(alpha: 0.54)
Colors.white30	.withValues(alpha: 0.3)
Colors.white12	.withValues(alpha: 0.12)
Colors.grey[850]	Theme.of(context).cardColor
1. search_model.dart — no colorScheme usage

File: lib/widgets/search_model.dart

Add this at the top of every build() method:

final colorScheme = Theme.of(context).colorScheme;
Replace All Occurrences
// BEFORE
style: const TextStyle(color: Colors.white)

// AFTER
style: TextStyle(color: colorScheme.onSurface)
// BEFORE
style: const TextStyle(color: Colors.white54)

// AFTER
style: TextStyle(
  color: colorScheme.onSurface.withValues(alpha: 0.54),
)
// BEFORE
color: Colors.white.withValues(alpha: .3)

// AFTER
color: colorScheme.onSurface.withValues(alpha: 0.3)
// BEFORE
fillColor: Theme.of(context).scaffoldBackgroundColor

// AFTER
fillColor: Theme.of(context).cardColor
2. checkout_screen.dart — private widgets still hardcoded

File: lib/views/checkout_screen.dart

_SectionHeader
// BEFORE
style: const TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.bold,
)

// AFTER
style: TextStyle(
  color: Theme.of(context).colorScheme.onSurface,
  fontSize: 18,
  fontWeight: FontWeight.bold,
)
_OrderSummaryCard
// BEFORE
style: const TextStyle(color: Colors.white)

// AFTER
style: TextStyle(
  color: Theme.of(context).colorScheme.onSurface,
)
// BEFORE
color: Colors.grey[850]

// AFTER
color: Theme.of(context).cardColor
_CardTile
// BEFORE
color: isSelected
    ? AppTheme.accentBlue
    : Colors.white12

// AFTER
color: isSelected
    ? AppTheme.accentBlue
    : colorScheme.onSurface.withValues(alpha: 0.12)
_PriceBreakdown
// BEFORE
labelStyle ?? const TextStyle(color: Colors.white70)

// AFTER
labelStyle ?? TextStyle(
  color: colorScheme.onSurface.withValues(alpha: 0.7),
)
_PaymentSuccessSheet
// BEFORE
style: const TextStyle(color: Colors.white)

// AFTER
style: TextStyle(color: colorScheme.onSurface)
3. grid_view_widget.dart — text invisible on light theme

File: lib/widgets/grid_view_widget.dart

// BEFORE
style: const TextStyle(color: Colors.white)

// AFTER
style: TextStyle(
  color: Theme.of(context).colorScheme.onSurface,
)
// BEFORE
color: widget.isFavorite ? Colors.red : Colors.white

// AFTER
color: widget.isFavorite
    ? Colors.red
    : Theme.of(context).colorScheme.onSurface
4. stepped_row_icon.dart — icons invisible

File: lib/widgets/stepped_row_icon.dart

// BEFORE
Colors.white.withValues(alpha: .1)

// AFTER
colorScheme.onSurface.withValues(alpha: 0.1)
// BEFORE
Colors.white70

// AFTER
colorScheme.onSurface.withValues(alpha: 0.7)
Phase 3 — Fix Remaining Colors.white* Usage

Priority: Medium
Estimated Time: ~20 min

1. explore_screen.dart

File: lib/views/explore_screen.dart

// BEFORE
labelColor: Colors.white,
unselectedLabelColor: Colors.white54,

// AFTER
labelColor: Theme.of(context).colorScheme.onSurface,
unselectedLabelColor:
    Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.54),
2. category_product_screen.dart

File: lib/views/category_product_screen.dart

// BEFORE
color: Colors.grey[850]

// AFTER
color: Theme.of(context).cardColor
3. home_content.dart — promo dots

File: lib/widgets/home_content.dart

// BEFORE
color: _currentPromoPage == index
    ? AppTheme.accentBlue
    : Colors.white30

// AFTER
color: _currentPromoPage == index
    ? AppTheme.accentBlue
    : Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.3)
Phase 4 — Remove Redundant Payment initialize()

Priority: Medium
Estimated Time: ~10 min

payment_screen.dart — remove manual initialize()

File: lib/views/payment_screen.dart

Before
if (!provider.isInitialized) {
  await provider.initialize(
    email: authProvider.email,
    name: authProvider.displayName,
  );
}
After
if (!provider.isInitialized) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Payment service not ready. Please sign in first.',
      ),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
Reason

ChangeNotifierProxyProvider already initializes automatically.

The View should never manually initialize services.

This is an MVVM cleanup.

Phase 5 — Fix Post-Checkout Navigation Ownership

Priority: Medium
Estimated Time: ~20 min

1. Add callback to CheckoutScreen

File: lib/views/checkout_screen.dart

class CheckoutScreen extends StatefulWidget {
  final Order order;
  final VoidCallback? onPaymentComplete;

  const CheckoutScreen({
    super.key,
    required this.order,
    this.onPaymentComplete,
  });
}
Replace triple Navigator chain
// BEFORE
onDone: () {
  Navigator.of(context)
    ..pop()
    ..pop()
    ..pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OrdersScreen(),
      ),
    );
},
// AFTER
onDone: () {
  Navigator.of(context)
    ..pop()
    ..pop();

  widget.onPaymentComplete?.call();
},
2. order_screen.dart

File: lib/views/order_screen.dart

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CheckoutScreen(
      order: order,
      onPaymentComplete: () =>
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OrdersScreen(),
            ),
          ),
    ),
  ),
)
Phase 6 — Decouple product_grid.dart from Screens

Priority: MVVM Cleanup
Estimated Time: ~15 min

Remove screen imports from widgets

File: lib/widgets/product_grid.dart

Remove
import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
Use callbacks instead
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        ProductDetailScreen(product: product),
  ),
),
Temporary VIEW CART action
action: SnackBarAction(
  label: 'VIEW',
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CartScreen(),
    ),
  ),
),
Phase 7 — File Renames + Cleanup

Estimated Time: ~30 min

1. Rename whilist_screen.dart
mv lib/views/whilist_screen.dart \
   lib/views/wishlist_screen.dart
Update Import
// BEFORE
import 'package:bike_shop/views/whilist_screen.dart';

// AFTER
import 'package:bike_shop/views/wishlist_screen.dart';
2. Rename Providers → ViewModels
cd lib/viewmodels

mv auth_provider.dart auth_viewmodel.dart
mv cart_provider.dart cart_viewmodel.dart
mv category_provider.dart category_viewmodel.dart
mv favorite_provider.dart favorites_viewmodel.dart
mv notification_provider.dart notification_viewmodel.dart
mv order_provider.dart order_viewmodel.dart
mv payment_provider.dart payment_viewmodel.dart
mv address_provider.dart address_viewmodel.dart
3. Remove fake delay

File: lib/viewmodels/cart_provider.dart

Remove
await Future.delayed(
  const Duration(seconds: 2),
);
Phase 8 — Add GoRouter (Long-Term Architecture)

Estimated Time: ~2–3 hours

1. Add dependency

File: pubspec.yaml

dependencies:
  go_router: ^14.0.0
2. Create router.dart

File: lib/config/router.dart

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const MainScreen(),
    ),

    GoRoute(
      path: '/cart',
      builder: (_, __) => const CartScreen(),
    ),

    GoRoute(
      path: '/orders',
      builder: (_, __) => const OrdersScreen(),
    ),
  ],
);
3. Update main.dart
Before
return MaterialApp(
  home: const MainScreen(),
);
After
return MaterialApp.router(
  routerConfig: appRouter,
);
4. Replace Navigator.push calls
Before
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CartScreen(),
  ),
)
After
context.push('/cart')
Benefits of GoRouter
Removes screen imports from widgets
Centralizes navigation
Cleaner MVVM architecture
Enables deep linking
Better web support
Easier testing
Cleaner back stack handling
Final Recommended Order
Fix critical navigation bugs
Fix hardcoded theme colors
Remove View-level initialization logic
Decouple widgets from screens
Rename providers → viewmodels
Add GoRouter last
Final MVVM Verdict



 also i have exception like

  Exception caught by rendering library ═════════════════════════════════
A RenderFlex overflowed by 1.00 pixels on the bottom.
The relevant error-causing widget was:
    Column Column:file:///F:/flutter-bike-shop/bike_shop/lib/widgets/grid_view_widget.dart:119:26


and light theme mode does not show any text,card images etc


also i have issues 

════════ Exception caught by Flutter framework ═════════════════════════════════
ListTile background color or ink splashes may be invisible.
════════════════════════════════════════════════════════════════════════════════

════════ Exception caught by Flutter framework ═════════════════════════════════
ListTile background color or ink splashes may be invisible.
════════════════════════════════════════════════════════════════════════════════

Your project is currently:

Area	Status
State management	✅ Good
Provider usage	✅ Good
ViewModels	✅ Present
UI separation	⚠️ Partial
Navigation separation	❌ Weak
Theme architecture	⚠️ Incomplete
Overall MVVM quality	🟡 Intermediate