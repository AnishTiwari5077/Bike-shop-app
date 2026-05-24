import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/explore_screen.dart';
import 'package:bike_shop/views/home_screen.dart';
import 'package:bike_shop/views/main_screen.dart';
import 'package:bike_shop/views/order_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:bike_shop/views/profile_screen.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainScreen()),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
    GoRoute(
      path: '/product',
      builder: (context, state) {
        final product = state.extra as Product;
        return ProductDetailScreen(product: product);
      },
    ),
  ],
);
