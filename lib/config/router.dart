// lib/config/router.dart
// ---------------------------------------------------------------------------
// GoRouter — centralised navigation configuration.
//
// All screens are reached via context.go() or context.push().
// No screen imports Navigator.push directly for routes defined here.
//
// Routes:
//   /          → MainScreen  (shell)
//   /cart      → CartScreen  (pushed on top of shell)
//   /orders    → OrdersScreen
//   /product   → ProductDetailScreen  (extra: Product)
// ---------------------------------------------------------------------------

import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/main_screen.dart';
import 'package:bike_shop/views/order_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/product',
      builder: (context, state) {
        final product = state.extra as Product;
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
