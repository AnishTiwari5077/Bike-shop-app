# Bike Shop App — MVVM Architecture Audit & Refactoring Prompt

> **Verdict:** The codebase is ~70% MVVM-compliant. The foundation is solid but several violations and incomplete patterns need to be resolved before the architecture is clean and maintainable.

---

## 1. What Is Already Done Well ✅

| Area | Status | Notes |
|---|---|---|
| `BaseViewModel` | ✅ Complete | Clean state machine: `idle / loading / success / error` |
| `ViewState` enum | ✅ Complete | Centralised in `lib/core/enums.dart` |
| `ThemeViewModel` | ✅ Complete | SharedPreferences persistence, toggle, system mode |
| `Responsive` helper | ✅ Complete | Breakpoints correct, `gridColumns`, `horizontalPadding`, `fontScale`, `value<T>` |
| `AdaptiveScaffold` | ✅ Complete | Mobile bottom nav / tablet+desktop rail |
| `ResponsiveLayout` | ✅ Complete | Clean wrapper with fallback chain |
| `ProductService` | ✅ Extracted | HTTP calls separated from ViewModel |
| `ProductGrid` | ✅ Responsive | Uses `Responsive.gridColumns`, `Responsive.value` |
| All ViewModels extend `BaseViewModel` | ✅ | Backward-compat aliases kept |
| `main.dart` wires `ThemeViewModel` | ✅ | `Consumer<ThemeViewModel>` wraps `MaterialApp` |

---

## 2. Architecture Violations & Issues ❌

### 2.1 Business Logic Inside Views (Critical)

**`lib/views/cart_screen.dart` — `_processCheckout()`**
```dart
// ❌ VIOLATION: Order creation and state mutation inside a StatefulWidget
Future<void> _processCheckout(BuildContext context) async {
  // Creates Order, calls ordersProvider.addOrder(), calls cartProvider.clearCart()
  // This is ViewModel/Service responsibility
}
```
**Fix:** Move to a `CheckoutViewModel` or extend `CartViewModel.checkout()`.

---

**`lib/views/checkout_screen.dart` — `_pay()`, `_addCard()`, `_deleteCard()`**
```dart
// ❌ VIOLATION: Payment orchestration, notification dispatch, and email
// sending are all inside the View
Future<void> _pay() async {
  final result = await paymentProvider.payForOrder(...);
  // Calls NotificationService directly
  // Calls NotificationViewModel directly
  // Sends email via NotificationService
}
```
**Fix:** Move orchestration to `PaymentViewModel.processPayment()`. The View should only call one method and react to `ViewState`.

---

**`lib/views/profile_screen.dart` — `_buildGoogleSignInButton()` onTap handler**
```dart
// ❌ VIOLATION: Post-login side-effects (initialising PaymentViewModel) in View
final success = await auth.signInWithGoogle();
if (success && mounted) {
  context.read<PaymentProvider>().initialize(...); // ← should be in AuthViewModel
}
```
**Fix:** `AuthViewModel.signInWithGoogle()` should emit an event or call a callback that triggers `PaymentViewModel.initialize()`. Or use a `ProxyProvider` / `ChangeNotifierProxyProvider` in `main.dart`.

---

### 2.2 Missing Services (HTTP calls still in ViewModels)

Only `ProductService` has been extracted. The rest call HTTP directly:

| ViewModel | Violation | Action |
|---|---|---|
| `CategoryViewModel` | `http.get` inside ViewModel | Extract to `CategoryService` |
| No `AuthService` split | `AuthService` exists but does Google Sign-In logic — OK, but has no unit-testable interface | Minor — acceptable as-is |

---

### 2.3 Hardcoded Colors Breaking Light Theme

Many screens still use hardcoded dark-mode constants instead of theme-aware values:

```dart
// ❌ WRONG — breaks light mode
style: TextStyle(color: Colors.white)
style: TextStyle(color: Colors.white54)
style: TextStyle(color: Colors.white70)
fillColor: Theme.of(context).cardColor  // OK
```

**Affected files:**
- `add_card_screen.dart` — all text styles hardcoded white
- `address_screen.dart` — all text styles hardcoded white
- `cart_screen.dart` — all text styles hardcoded white
- `checkout_screen.dart` — partial
- `explore_screen.dart` — partial
- `notification_screen.dart` — all white
- `order_screen.dart` — all white
- `order_details_screen.dart` — all white
- `payment_screen.dart` — all white
- `whilist_screen.dart` — all white

**Fix pattern:**
```dart
// ✅ CORRECT — works in both themes
Theme.of(context).colorScheme.onSurface           // replaces Colors.white
Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)  // replaces Colors.white70
Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54) // replaces Colors.white54
Theme.of(context).colorScheme.surface              // replaces AppTheme.cardBackground
Theme.of(context).scaffoldBackgroundColor          // replaces AppTheme.primaryBackground
```

---

### 2.4 Folder Naming Inconsistency

| Current | Standard MVVM | Action |
|---|---|---|
| `lib/viewmodels/cart_provider.dart` | `lib/viewmodels/cart_viewmodel.dart` | Rename files |
| `lib/viewmodels/auth_provider.dart` | `lib/viewmodels/auth_viewmodel.dart` | Rename files |
| All `*_provider.dart` in viewmodels/ | Should be `*_viewmodel.dart` | Rename all |
| `lib/views/whilist_screen.dart` | `lib/views/wishlist_screen.dart` | Fix typo |

The backward-compat `typedef` aliases (e.g. `typedef CartProvider = CartViewModel`) are fine to keep during migration.

---

### 2.5 `CategoryService` Is Missing

`CategoryViewModel` directly calls `http.get` — the only ViewModel that wasn't refactored:

```dart
// ❌ lib/viewmodels/category_provider.dart
final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/categories'))
```

**Fix:** Create `lib/services/category_service.dart` mirroring `ProductService`.

---

### 2.6 Responsive Gaps

| Location | Issue |
|---|---|
| `cart_screen.dart` | No responsive padding — hardcoded `EdgeInsets.all(16)` |
| `checkout_screen.dart` | No responsive padding — hardcoded `EdgeInsets.all(16)` |
| `order_screen.dart` | No responsive padding |
| `explore_screen.dart` | `GridView` uses hardcoded `crossAxisCount: 2` |
| `category_product_screen.dart` | `GridView` uses hardcoded `crossAxisCount: 2` |
| `notification_screen.dart` | No responsive padding |

**Fix pattern:**
```dart
padding: EdgeInsets.symmetric(
  horizontal: Responsive.horizontalPadding(context),
  vertical: 16,
),
```

---

### 2.7 `ProxyProvider` Not Used for Cross-ViewModel Dependencies

`ProfileScreen` manually calls `PaymentViewModel.initialize()` after sign-in. The correct MVVM approach is to declare the dependency in `main.dart`:

```dart
// ✅ Replace manual initialization with ProxyProvider in main.dart
ChangeNotifierProxyProvider<AuthViewModel, PaymentViewModel>(
  create: (_) => PaymentViewModel(),
  update: (_, auth, payment) {
    if (auth.isSignedIn && payment != null && !payment.isInitialized) {
      payment.initialize(email: auth.email, name: auth.displayName);
    }
    return payment!;
  },
),
```

---

### 2.8 `_isProcessingCheckout` State in `cart_screen.dart`

```dart
// ❌ Local bool duplicates what BaseViewModel.isLoading already provides
bool _isProcessingCheckout = false;
```

If checkout logic is moved to a ViewModel, this disappears automatically.

---

## 3. Complete Refactoring Prompt

Copy this prompt and give it to an AI coding assistant or use it as your sprint task list.

---

```
You are refactoring a Flutter Bike Shop app from a partially-migrated MVVM
architecture to a clean, fully-compliant MVVM pattern. The codebase uses
Provider for state management and already has BaseViewModel, ViewState enum,
Responsive helper, AdaptiveScaffold, ThemeViewModel, and ProductService.

Complete the following tasks in order. Each task is independently shippable.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 — SERVICE EXTRACTION (1 hour)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 1.1 — Create lib/services/category_service.dart
  Mirror the structure of lib/services/product_service.dart.
  Move the http.get call from CategoryViewModel.loadCategories() into
  CategoryService.fetchCategories() which returns Future<List<Category>>.
  Update CategoryViewModel to call CategoryService.instance.fetchCategories().

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2 — CHECKOUT LOGIC (2 hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 2.1 — Create lib/viewmodels/checkout_viewmodel.dart

  class CheckoutViewModel extends BaseViewModel {
    // Orchestrates the full payment + order + notification flow
    // Injected via context.read in CheckoutScreen

    Future<bool> processPayment({
      required Order order,
      required String paymentMethodId,
      required PaymentViewModel paymentVM,
      required OrderViewModel orderVM,
      required NotificationViewModel notificationVM,
      required AuthViewModel authVM,
    }) async {
      setLoading();
      final result = await paymentVM.payForOrder(
        amount: order.totalAmount,
        orderId: order.id,
        paymentMethodId: paymentMethodId,
      );
      if (result.isSuccess) {
        orderVM.updateOrderStatus(order.id, 'delivered');
        notificationVM.addNotification('Payment Successful', '...');
        await NotificationService.instance.showPaymentSuccessNotification(...);
        if (authVM.isSignedIn) {
          await NotificationService.instance.sendPaymentConfirmationEmail(...);
        }
        setSuccess();
        return true;
      } else {
        setError(result.errorMessage ?? 'Payment failed');
        return false;
      }
    }
  }

TASK 2.2 — Refactor CheckoutScreen
  Remove _pay(), _isPaying bool, and all direct service/provider calls.
  Replace with:
    final checkoutVM = context.watch<CheckoutViewModel>();
    ElevatedButton onPressed: () async {
      final ok = await context.read<CheckoutViewModel>().processPayment(...);
      if (ok) _showSuccessSheet();
    }
  Add CheckoutViewModel to MultiProvider in main.dart.

TASK 2.3 — Refactor CartScreen._processCheckout()
  Move Order creation + addOrder() + clearCart() into CartViewModel.checkout():
    Future<Order> checkout() async {
      final order = Order(id: ..., items: cartItems, ...);
      // returns the Order so the view can navigate to OrdersScreen
      clearCart();
      return order;
    }
  CartScreen calls context.read<CartViewModel>().checkout() and navigates.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3 — CROSS-VIEWMODEL DEPENDENCY (30 min)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 3.1 — Use ChangeNotifierProxyProvider in main.dart
  Replace the manual payment initialization in ProfileScreen and
  CheckoutScreen with a ProxyProvider so PaymentViewModel auto-initializes
  whenever AuthViewModel.isSignedIn becomes true:

    ChangeNotifierProxyProvider<AuthViewModel, PaymentViewModel>(
      create: (_) => PaymentViewModel(),
      update: (_, auth, payment) {
        if (auth.isSignedIn && payment != null && !payment.isInitialized) {
          payment.initialize(email: auth.email, name: auth.displayName);
        }
        return payment!;
      },
    ),

  Remove all manual calls to PaymentViewModel.initialize() from ProfileScreen
  and CheckoutScreen._addCard().

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 4 — THEME-AWARE COLORS (2 hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 4.1 — Replace all hardcoded Colors.white* across every view file.
  Apply this mapping consistently:

  Colors.white         → Theme.of(context).colorScheme.onSurface
  Colors.white70       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
  Colors.white60       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
  Colors.white54       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)
  Colors.white38       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
  Colors.white30       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
  Colors.white24       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)
  Colors.white12       → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
  AppTheme.cardBackground   → Theme.of(context).cardColor
  AppTheme.primaryBackground → Theme.of(context).scaffoldBackgroundColor
  AppTheme.secondaryBackground → Theme.of(context).colorScheme.surface
  fillColor: Colors.grey[850] → Theme.of(context).cardColor

  DO NOT replace: AppTheme.accentBlue, AppTheme.accentCyan
  (these are shared brand colors, not theme-sensitive)

  Files to update (all in lib/views/ and lib/widgets/):
    add_card_screen.dart, address_screen.dart, cart_screen.dart,
    checkout_screen.dart, explore_screen.dart, notification_screen.dart,
    order_details_screen.dart, order_screen.dart, payment_screen.dart,
    whilist_screen.dart (also fix typo → wishlist_screen.dart),
    grid_view_widget.dart, bike_promo.dart, stepped_row_icon.dart

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 5 — RESPONSIVE PADDING (1 hour)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 5.1 — Apply Responsive.horizontalPadding() in all screen-level paddings.
  Replace every hardcoded padding: const EdgeInsets.all(16) or
  EdgeInsets.symmetric(horizontal: 16) with:
    EdgeInsets.symmetric(
      horizontal: Responsive.horizontalPadding(context),
      vertical: 16,
    )

TASK 5.2 — Fix hardcoded crossAxisCount in GridViews
  explore_screen.dart (DealsTab GridView):
    crossAxisCount: Responsive.gridColumns(context)
    childAspectRatio: Responsive.value(context, mobile: 0.75, tablet: 0.8)

  category_product_screen.dart:
    crossAxisCount: Responsive.gridColumns(context)
    childAspectRatio: Responsive.value(context, mobile: 0.75, tablet: 0.8)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 6 — FILE RENAMING (30 min)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 6.1 — Rename ViewModel files (keep typedef aliases for backward compat)
  lib/viewmodels/auth_provider.dart     → auth_viewmodel.dart
  lib/viewmodels/cart_provider.dart     → cart_viewmodel.dart
  lib/viewmodels/category_provider.dart → category_viewmodel.dart
  lib/viewmodels/favorite_provider.dart → favorites_viewmodel.dart
  lib/viewmodels/notification_provider.dart → notification_viewmodel.dart
  lib/viewmodels/order_provider.dart    → order_viewmodel.dart
  lib/viewmodels/payment_provider.dart  → payment_viewmodel.dart
  lib/viewmodels/address_provider.dart  → address_viewmodel.dart

TASK 6.2 — Fix typo in view file name
  lib/views/whilist_screen.dart → lib/views/wishlist_screen.dart
  Update all import references.

TASK 6.3 — Update main.dart imports to match new file names.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 7 — OPTIONAL ENHANCEMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK 7.1 — Add a repository layer (optional, for testability)
  For each service, create a matching abstract interface:
    abstract class IProductRepository {
      Future<List<Product>> fetchProducts();
      Future<Product?> fetchById(String id);
    }
  ProductService implements IProductRepository.
  ProductViewModel receives IProductRepository (constructor injection).
  This makes unit testing ViewModels possible without HTTP calls.

TASK 7.2 — Add unit tests (optional)
  lib/test/viewmodels/product_viewmodel_test.dart
  lib/test/viewmodels/cart_viewmodel_test.dart
  Use mocktail or mockito to mock service layer.
  Test state transitions: idle → loading → success / error.

TASK 7.3 — AppLocalizations / l10n (optional)
  All hardcoded English strings should move to ARB files for i18n readiness.
```

---

## 4. Priority Order (If Time-Constrained)

| Priority | Task | Impact |
|---|---|---|
| 🔴 P0 | Phase 4 — Fix hardcoded white colors | Light theme is broken without this |
| 🔴 P0 | Phase 2 — Move checkout logic to ViewModel | Biggest MVVM violation |
| 🟠 P1 | Phase 3 — ProxyProvider for auth→payment | Removes cross-view coupling |
| 🟠 P1 | Phase 1 — CategoryService extraction | Makes all ViewModels service-free |
| 🟡 P2 | Phase 5 — Responsive padding | Tablet/desktop experience |
| 🟡 P2 | Phase 5 — Fix hardcoded grid columns | Tablet/desktop experience |
| 🟢 P3 | Phase 6 — File renaming | Code hygiene |
| 🟢 P3 | Phase 7 — Repository interfaces + tests | Long-term maintainability |

---

## 5. Final Target Folder Structure

```
lib/
├── config/
│   ├── api_config.dart
│   ├── responsive.dart         ✅ done
│   └── theme.dart              ✅ done
│
├── core/
│   ├── base_viewmodel.dart     ✅ done
│   └── enums.dart              ✅ done
│
├── models/                     ✅ done — no changes needed
│
├── services/
│   ├── auth_service.dart       ✅ done
│   ├── category_service.dart   ❌ missing — create in Phase 1
│   ├── notification_service.dart ✅ done
│   ├── product_service.dart    ✅ done
│   └── stripe_service.dart     ✅ done
│
├── viewmodels/
│   ├── address_viewmodel.dart  🔄 rename from address_provider.dart
│   ├── auth_viewmodel.dart     🔄 rename
│   ├── cart_viewmodel.dart     🔄 rename + add checkout() method
│   ├── category_viewmodel.dart 🔄 rename + use CategoryService
│   ├── checkout_viewmodel.dart ❌ missing — create in Phase 2
│   ├── favorites_viewmodel.dart 🔄 rename
│   ├── notification_viewmodel.dart 🔄 rename
│   ├── order_viewmodel.dart    🔄 rename
│   ├── payment_viewmodel.dart  🔄 rename
│   ├── product_viewmodel.dart  ✅ done (already named correctly)
│   └── theme_viewmodel.dart    ✅ done
│
├── views/
│   ├── add_card_screen.dart    🔄 fix colors
│   ├── address_screen.dart     🔄 fix colors + padding
│   ├── cart_screen.dart        🔄 fix colors + extract checkout logic
│   ├── category_product_screen.dart  🔄 fix grid + padding
│   ├── checkout_screen.dart    🔄 fix colors + delegate to CheckoutViewModel
│   ├── explore_screen.dart     🔄 fix grid + colors + padding
│   ├── home_screen.dart        ✅ mostly fine
│   ├── main_screen.dart        ✅ done
│   ├── notification_screen.dart 🔄 fix colors
│   ├── order_details_screen.dart 🔄 fix colors
│   ├── order_screen.dart       🔄 fix colors
│   ├── payment_screen.dart     🔄 fix colors
│   ├── product_details_screen.dart ✅ mostly done (uses Theme.of)
│   ├── profile_screen.dart     🔄 remove manual payment init
│   ├── wishlist_screen.dart    🔄 rename (fix typo) + fix colors
│   └── shared/
│       ├── adaptive_scaffold.dart  ✅ done
│       └── responsive_layout.dart  ✅ done
│
└── widgets/
    ├── bike_promo.dart          ✅ fine (no hardcoded colors)
    ├── custom_bottom_nav.dart   ✅ fine
    ├── grid_view_widget.dart    🔄 fix Colors.white* references
    ├── home_content.dart        ✅ mostly done (uses Theme.of)
    ├── product_grid.dart        ✅ done (responsive)
    ├── search_model.dart        🔄 fix Colors.white* references
    └── stepped_row_icon.dart    ✅ mostly done (uses Theme.of)
```

---

## 6. Quick Reference — MVVM Rule Checklist

Use this for code review:

- [ ] Views contain **zero** business logic — only widget trees and `context.read()` calls
- [ ] ViewModels contain **zero** Flutter widget imports (`package:flutter/material.dart` is allowed for `ChangeNotifier` / `BuildContext`-free code only)
- [ ] Services contain **zero** ViewModel imports
- [ ] HTTP calls live only in Services, never in ViewModels or Views
- [ ] All colors use `Theme.of(context)` — no `Colors.white*` or `AppTheme.*Background` constants in views
- [ ] All screen-level paddings use `Responsive.horizontalPadding(context)`
- [ ] All `GridView` `crossAxisCount` values use `Responsive.gridColumns(context)`
- [ ] Cross-ViewModel dependencies declared in `main.dart` via `ProxyProvider`, not wired manually in Views

---

