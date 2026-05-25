import 'dart:ui';

import 'package:bike_shop/models/order_model.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/category_product_screen.dart';
import 'package:bike_shop/views/checkout_screen.dart';
import 'package:bike_shop/views/main_screen.dart';
import 'package:bike_shop/views/notification_screen.dart';
import 'package:bike_shop/views/order_details_screen.dart';
import 'package:bike_shop/views/order_screen.dart';
import 'package:bike_shop/views/payment_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:bike_shop/views/address_screen.dart';
import 'package:bike_shop/views/wishlist_screen.dart';
import 'package:bike_shop/views/settings/notifications_settings_screen.dart';
import 'package:bike_shop/views/settings/privacy_security_screen.dart';
import 'package:bike_shop/views/settings/help_support_screen.dart';
import 'package:bike_shop/views/settings/about_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, _) => const MainScreen()),
    GoRoute(path: '/cart', builder: (context, _) => const CartScreen()),
    GoRoute(path: '/orders', builder: (context, _) => const OrdersScreen()),
    GoRoute(
      path: '/notifications',
      builder: (context, _) => const NotificationsScreen(),
    ),
    GoRoute(path: '/wishlist', builder: (context, _) => const WishListScreen()),
    GoRoute(path: '/addresses', builder: (context, _) => const AddressesScreen()),
    GoRoute(path: '/payment', builder: (context, _) => const PaymentMethodsScreen()),
    GoRoute(
      path: '/product',
      builder: (_, state) =>
          ProductDetailScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/category',
      builder: (_, state) {
        final args = state.extra as Map<String, String>;
        return CategoryProductsScreen(
          categorySlug: args['slug']!,
          categoryName: args['name']!,
        );
      },
    ),
    GoRoute(
      path: '/order-detail',
      builder: (_, state) => OrderDetailScreen(order: state.extra as Order),
    ),
    GoRoute(
      path: '/checkout',
      builder: (_, state) {
        final args = state.extra as Map<String, dynamic>;
        return CheckoutScreen(
          order: args['order'] as Order,
          onPaymentComplete: args['onPaymentComplete'] as VoidCallback?,
        );
      },
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, _) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, _) => const PrivacySecurityScreen(),
    ),
    GoRoute(
      path: '/settings/support',
      builder: (context, _) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (context, _) => const AboutScreen(),
    ),
  ],
);

