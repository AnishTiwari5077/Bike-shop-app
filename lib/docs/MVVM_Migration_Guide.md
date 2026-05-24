# Bike Shop App — MVVM + Responsive + Theme Mode Migration Guide

> **Strategy**: Incremental refactor — no big-bang rewrite. You keep your existing folder structure and migrate screen by screen.

---

## 1. New Folder Structure

```
lib/
├── config/
│   ├── api_config.dart          ✅ keep
│   ├── theme.dart               🔄 extend (add light theme + ThemeMode)
│   └── responsive.dart          🆕 NEW — breakpoints & helpers
│
├── core/
│   └── enums.dart               🆕 NEW — ViewState enum
│
├── models/                      ✅ keep all models as-is (they are already clean)
│
├── services/                    🔄 rename from service/ → services/
│   ├── auth_service.dart
│   ├── notification_service.dart
│   └── stripe_service.dart
│
├── viewmodels/                  🆕 NEW — one ViewModel per feature
│   ├── auth_viewmodel.dart      (replace auth_provider.dart)
│   ├── cart_viewmodel.dart      (replace cart_provider.dart)
│   ├── product_viewmodel.dart   (replace product_provider.dart)
│   ├── category_viewmodel.dart  (replace category_provider.dart)
│   ├── order_viewmodel.dart     (replace order_provider.dart)
│   ├── payment_viewmodel.dart   (replace payment_provider.dart)
│   ├── favorites_viewmodel.dart (replace favorite_provider.dart)
│   ├── address_viewmodel.dart   (replace address_provider.dart)
│   ├── notification_viewmodel.dart
│   └── theme_viewmodel.dart     🆕 NEW — manages ThemeMode
│
├── views/                       🔄 rename from screens/ → views/
│   ├── home/
│   │   ├── home_view.dart
│   │   └── widgets/
│   │       ├── home_content.dart
│   │       └── product_grid.dart
│   ├── cart/
│   │   └── cart_view.dart
│   ├── checkout/
│   │   └── checkout_view.dart
│   ├── orders/
│   │   ├── orders_view.dart
│   │   └── order_detail_view.dart
│   ├── profile/
│   │   └── profile_view.dart
│   ├── explore/
│   │   └── explore_view.dart
│   ├── auth/
│   │   └── login_view.dart
│   └── shared/                  🆕 NEW — responsive wrapper widgets
│       ├── responsive_layout.dart
│       └── adaptive_scaffold.dart
│
└── widgets/                     ✅ keep shared widgets here
    ├── grid_view_widget.dart
    ├── bike_promo.dart
    ├── custom_bottom_nav.dart
    ├── search_modal.dart
    └── stepped_row_icon.dart
```

---

## 2. Core Files to Create

### 2a. `lib/core/enums.dart`
```dart
enum ViewState { idle, loading, success, error }
```

### 2b. `lib/core/base_viewmodel.dart`
```dart
import 'package:flutter/material.dart';
import 'enums.dart';

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  void setState(ViewState state) {
    _state = state;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }

  void setLoading() => setState(ViewState.loading);
  void setIdle() => setState(ViewState.idle);
  void setSuccess() => setState(ViewState.success);
}
```

---

## 3. MVVM Pattern Explained for Your App

```
┌─────────────────────────────────────────────────────────┐
│                        VIEW                             │
│  (home_view.dart, cart_view.dart, etc.)                 │
│  • Only UI widgets                                      │
│  • Reads state via context.watch<ViewModel>()           │
│  • Calls viewmodel methods on user action               │
└───────────────────┬─────────────────────────────────────┘
                    │ watches / calls
┌───────────────────▼─────────────────────────────────────┐
│                     VIEWMODEL                           │
│  (ProductViewModel, CartViewModel, etc.)                │
│  • Extends BaseViewModel (ChangeNotifier)               │
│  • Holds state (ViewState + data)                       │
│  • Calls Service methods                                │
│  • No BuildContext, no Widget imports                   │
└───────────────────┬─────────────────────────────────────┘
                    │ calls
┌───────────────────▼─────────────────────────────────────┐
│                     SERVICE                             │
│  (StripeService, AuthService, NotificationService)      │
│  • Pure Dart — no Flutter imports                       │
│  • HTTP calls, Firebase, SharedPreferences              │
│  • Returns data / throws exceptions                     │
└─────────────────────────────────────────────────────────┘
```

**Key rule**: ViewModels replace your Providers 1-to-1. The only difference is they extend `BaseViewModel` instead of raw `ChangeNotifier`, giving you free `isLoading` / `hasError` state.

---

## 4. Example: ProductViewModel (replaces product_provider.dart)

```dart
// lib/viewmodels/product_viewmodel.dart
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/services/product_service.dart'; // extract HTTP calls here

class ProductViewModel extends BaseViewModel {
  List<Product> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';

  List<Product> get products => _products;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<Product> get displayedProducts {
    return _products.where((p) {
      final matchesSearch =
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadProducts() async {
    setLoading();
    try {
      _products = await ProductService.instance.fetchProducts();
      setSuccess();
    } catch (e) {
      setError('Could not connect to server. Please check your connection.');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> refresh() => loadProducts();
}
```

### Extract HTTP to a Service

```dart
// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bike_shop/config/api_config.dart';
import 'package:bike_shop/models/product_model.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  Future<List<Product>> fetchProducts() async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/products'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['products'] as List)
          .map((j) => Product.fromMap(j))
          .toList();
    }
    throw Exception('Failed to load products: ${res.statusCode}');
  }

  Future<Product?> fetchById(String id) async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/products/$id'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return Product.fromMap(jsonDecode(res.body));
    return null;
  }
}
```

---

## 5. Theme Mode (Light / Dark / System)

### 5a. ThemeViewModel

```dart
// lib/viewmodels/theme_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  static const _key = 'theme_mode';

  ThemeMode get themeMode => _themeMode;
  bool get isDark =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggleDarkLight() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
```

### 5b. Extend AppTheme with Light Theme

```dart
// lib/config/theme.dart  — ADD these to your existing file

class AppTheme {
  // ── Dark colors (existing) ──────────────────────────────────────
  static const Color primaryBackgroundDark  = Color(0xFF0A192F);
  static const Color secondaryBackgroundDark = Color(0xFF1E1E2E);
  static const Color cardBackgroundDark     = Color(0xFF1E1E2E);

  // ── Light colors (NEW) ──────────────────────────────────────────
  static const Color primaryBackgroundLight  = Color(0xFFF0F4F8);
  static const Color secondaryBackgroundLight = Color(0xFFFFFFFF);
  static const Color cardBackgroundLight     = Color(0xFFFFFFFF);
  static const Color textPrimaryLight        = Color(0xFF1A202C);
  static const Color textSecondaryLight      = Color(0xFF4A5568);

  // ── Shared ──────────────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);

  static ThemeData get darkTheme => ThemeData(
    // ... your existing dark theme ...
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: primaryBackgroundLight,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentCyan,
      surface: secondaryBackgroundLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBackgroundLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: cardBackgroundLight,
      elevation: 2,
      shadowColor: Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE8EEF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
    ),
  );
}
```

### 5c. Wire ThemeViewModel into main.dart

```dart
// lib/main.dart — updated runApp section

runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      // ... rest of your providers (renamed to viewmodels)
    ],
    child: const BikeShopApp(),
  ),
);

class BikeShopApp extends StatelessWidget {
  const BikeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    return MaterialApp(
      title: 'Bike Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,          // NEW
      darkTheme: AppTheme.darkTheme,       // existing
      themeMode: themeVM.themeMode,        // NEW — driven by ViewModel
      home: const MainScreen(),
    );
  }
}
```

### 5d. Theme Toggle in Profile Screen

```dart
// Inside profile settings section — add this tile:
ListTile(
  leading: Icon(
    themeVM.isDark ? Icons.dark_mode : Icons.light_mode,
    color: AppTheme.accentBlue,
  ),
  title: const Text('Appearance'),
  subtitle: Text(switch (themeVM.themeMode) {
    ThemeMode.dark   => 'Dark',
    ThemeMode.light  => 'Light',
    ThemeMode.system => 'System',
  }),
  trailing: DropdownButton<ThemeMode>(
    value: themeVM.themeMode,
    underline: const SizedBox(),
    items: const [
      DropdownMenuItem(value: ThemeMode.dark,   child: Text('Dark')),
      DropdownMenuItem(value: ThemeMode.light,  child: Text('Light')),
      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
    ],
    onChanged: (mode) => themeVM.setThemeMode(mode!),
  ),
),
```

---

## 6. Responsive Design with LayoutBuilder + MediaQuery

### 6a. Responsive Helper

```dart
// lib/config/responsive.dart
import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileMax  = 600;
  static const double tabletMax  = 1024;

  static bool isMobile(BuildContext ctx)  => MediaQuery.sizeOf(ctx).width < mobileMax;
  static bool isTablet(BuildContext ctx)  => MediaQuery.sizeOf(ctx).width >= mobileMax
                                          && MediaQuery.sizeOf(ctx).width < tabletMax;
  static bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= tabletMax;

  /// Shorthand: value for [mobile], [tablet], [desktop]
  static T value<T>(BuildContext ctx, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w >= tabletMax) return desktop ?? tablet ?? mobile;
    if (w >= mobileMax) return tablet ?? mobile;
    return mobile;
  }

  /// Grid column count
  static int gridColumns(BuildContext ctx) =>
      value(ctx, mobile: 2, tablet: 3, desktop: 4);

  /// Horizontal padding
  static double horizontalPadding(BuildContext ctx) =>
      value(ctx, mobile: 16.0, tablet: 32.0, desktop: 64.0);

  /// Font scale multiplier
  static double fontScale(BuildContext ctx) =>
      value(ctx, mobile: 1.0, tablet: 1.1, desktop: 1.2);
}
```

### 6b. ResponsiveLayout widget

```dart
// lib/views/shared/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:bike_shop/config/responsive.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.tabletMax) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Responsive.mobileMax) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
```

### 6c. Responsive ProductGrid (replaces static 2-column grid)

```dart
// lib/widgets/product_grid.dart — updated itemBuilder section

GridView.builder(
  // ...
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: Responsive.gridColumns(context),  // 2 / 3 / 4
    childAspectRatio: Responsive.value(
      context,
      mobile: 0.7,
      tablet: 0.75,
      desktop: 0.8,
    ),
    crossAxisSpacing: Responsive.value(context, mobile: 16.0, tablet: 20.0),
    mainAxisSpacing: Responsive.value(context, mobile: 16.0, tablet: 20.0),
  ),
  // ...
)
```

### 6d. Responsive Home Layout (side nav on tablet+)

```dart
// lib/views/shared/adaptive_scaffold.dart
import 'package:flutter/material.dart';
import 'package:bike_shop/config/responsive.dart';

class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<NavigationDestination> destinations;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    // Tablet/Desktop: NavigationRail on the left
    if (Responsive.isTablet(context) || Responsive.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Mobile: Bottom navigation bar (existing)
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
```

---

## 7. How Views Consume ViewModels (MVVM View pattern)

```dart
// lib/views/home/home_view.dart  — minimal example
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:bike_shop/core/enums.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // READ-ONLY snapshot — no logic here
    final vm = context.watch<ProductViewModel>();

    return switch (vm.state) {
      ViewState.loading => const Center(child: CircularProgressIndicator()),
      ViewState.error   => Center(child: Text(vm.errorMessage ?? 'Error')),
      _                 => _HomeContent(vm: vm),
    };
  }
}

class _HomeContent extends StatelessWidget {
  final ProductViewModel vm;
  const _HomeContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    // All layout, no business logic
    return RefreshIndicator(
      onRefresh: () => context.read<ProductViewModel>().refresh(),
      child: const ProductGrid(),
    );
  }
}
```

---

## 8. Migration Checklist (Step-by-Step)

Do these one at a time. Each step is independently shippable.

```
PHASE 1 — Foundation (1–2 hours)
  [ ] Create lib/core/enums.dart
  [ ] Create lib/core/base_viewmodel.dart
  [ ] Create lib/config/responsive.dart
  [ ] Add lightTheme to AppTheme
  [ ] Create ThemeViewModel
  [ ] Wire ThemeViewModel into main.dart (theme: / darkTheme: / themeMode:)
  [ ] Add theme toggle to ProfileScreen settings

PHASE 2 — ViewModels (2–3 hours)
  [ ] Create ProductViewModel (extract HTTP to ProductService)
  [ ] Create CartViewModel  (rename CartProvider → CartViewModel, extend BaseViewModel)
  [ ] Create OrderViewModel
  [ ] Create CategoryViewModel
  [ ] Create PaymentViewModel
  [ ] Create FavoritesViewModel
  [ ] Create AddressViewModel
  [ ] Create NotificationViewModel
  [ ] Create AuthViewModel
  [ ] Update main.dart providers list (rename imports)

PHASE 3 — Responsive (1–2 hours)
  [ ] Create lib/views/shared/responsive_layout.dart
  [ ] Create lib/views/shared/adaptive_scaffold.dart
  [ ] Update ProductGrid to use Responsive.gridColumns(context)
  [ ] Update MainScreen to use AdaptiveScaffold
  [ ] Update horizontal padding across screens using Responsive.horizontalPadding(context)
  [ ] Update font sizes using Responsive.fontScale(context) where needed

PHASE 4 — Folder rename (30 min)
  [ ] Rename screens/ → views/
  [ ] Rename service/ → services/
  [ ] Update all import paths (VS Code: Find & Replace  'screens/' → 'views/')
  [ ] Rename providers/ → viewmodels/ and update imports
```

---

## 9. Colors — Theme-Aware Usage

Replace all hardcoded `AppTheme.cardBackground` with `Theme.of(context)` equivalents so light/dark switch automatically:

| Your current constant         | Theme-aware equivalent                         |
|-------------------------------|------------------------------------------------|
| `AppTheme.primaryBackground`  | `Theme.of(ctx).scaffoldBackgroundColor`        |
| `AppTheme.cardBackground`     | `Theme.of(ctx).cardColor`                      |
| `AppTheme.secondaryBackground`| `Theme.of(ctx).colorScheme.surface`            |
| `AppTheme.textPrimary`        | `Theme.of(ctx).colorScheme.onSurface`          |
| `AppTheme.textSecondary`      | `Theme.of(ctx).colorScheme.onSurface.withOpacity(.7)` |
| `Colors.white`                | `Theme.of(ctx).colorScheme.onSurface`          |
| `Colors.white54`              | `Theme.of(ctx).colorScheme.onSurface.withOpacity(.54)` |

Keep `AppTheme.accentBlue` and `AppTheme.accentCyan` — they're shared between themes.

---

## 10. Quick Wins You Can Do Right Now (15 min each)

1. **Theme toggle**: Add `ThemeViewModel` + wire `MaterialApp` → instant light/dark toggle with zero other changes
2. **Responsive grid**: Replace the `crossAxisCount: 2` hardcode with `Responsive.gridColumns(context)` — tablets immediately show 3 columns
3. **Horizontal padding**: Wrap your screen body padding calls with `Responsive.horizontalPadding(context)` for all screens
4. **BaseViewModel**: Add `base_viewmodel.dart` and have your first one provider (e.g. `ProductProvider`) extend it → you get free loading/error state enum

---

*Each phase is independently deployable. You don't need to complete all phases before shipping.*
