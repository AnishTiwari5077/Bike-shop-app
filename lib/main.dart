import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/viewmodels/address_provider.dart';
import 'package:bike_shop/viewmodels/auth_provider.dart';
import 'package:bike_shop/viewmodels/cart_provider.dart';
import 'package:bike_shop/viewmodels/category_provider.dart';
import 'package:bike_shop/viewmodels/checkout_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorite_provider.dart';
import 'package:bike_shop/viewmodels/notification_provider.dart';
import 'package:bike_shop/viewmodels/order_provider.dart';
import 'package:bike_shop/viewmodels/payment_provider.dart';
import 'package:bike_shop/viewmodels/product_provider.dart';
import 'package:bike_shop/views/main_screen.dart';
import 'package:bike_shop/services/notification_service.dart';
import 'package:bike_shop/viewmodels/theme_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

// ─── Lightweight background handler (does NOT re‑initialise NotificationService) ───
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Minimal Firebase initialisation (required for background isolate)
  await Firebase.initializeApp();

  // 2. Create a fresh local notifications plugin instance (lightweight)
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // 3. Initialise with basic settings (no callbacks needed)
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await localNotifications.initialize(settings: initSettings);

  // 4. Ensure Android channel exists (must match the main app channel)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'bike_shop_payments',
    'Payment Notifications',
    description: 'Notifications for payment and order updates',
    importance: Importance.high,
  );
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 5. Show the notification – ICON REMOVED to avoid resource not found error
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'bike_shop_payments',
    'Payment Notifications',
    channelDescription: 'Notifications for payment and order updates',
    importance: Importance.high,
    priority: Priority.high,
    // icon: 'ic_launcher', // <-- REMOVED – causes "resource not found"
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final int id = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  await localNotifications.show(
    id: id,
    title: message.notification?.title ?? 'Bike Shop',
    body: message.notification?.body ?? '',
    notificationDetails: details,
  );

  debugPrint('Background FCM message shown: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Image cache limit (prevents memory issues) ──────────────────────
  PaintingBinding.instance.imageCache.maximumSize = 20; // was 100
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      10 << 20; // 10MB, was 50MB

  await Firebase.initializeApp();

  // Register lightweight background handler (must be before any other FCM calls)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initialize();

  Stripe.publishableKey =
      'pk_test_51SXvBHHKrFDpSpIkVxuXl5nyLySIPsmOBh6EOuy8Ih2xXqdFY3KdaSy0ga75PTjAEpG3wQtaGfKZFnyLr0WOwFD5002qz17NV2';
  await Stripe.instance.applySettings();

  runApp(const BikeShopApp());
}

class BikeShopApp extends StatelessWidget {
  const BikeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ─── Theme (must be first so Consumer below can access it) ────────
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),

        // ─── Feature providers (existing — names updated to new ViewModel
        //     classes after Phase 3 migration; import paths unchanged) ─────
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProvider(create: (_) => AddressViewModel()),
        // ── PaymentViewModel auto-initializes when AuthViewModel signs in ───
        ChangeNotifierProxyProvider<AuthViewModel, PaymentViewModel>(
          create: (_) => PaymentViewModel(),
          update: (_, auth, payment) {
            if (auth.isSignedIn &&
                payment != null &&
                !payment.isInitialized) {
              payment.initialize(
                email: auth.email,
                name: auth.displayName,
              );
            }
            return payment!;
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => CheckoutViewModel()),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel()..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel()..loadProducts(),
        ),
      ],
      // ─── Consumer wraps MaterialApp so ThemeViewModel changes rebuild it ─
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            title: 'Bike Shop',
            debugShowCheckedModeBanner: false,
            // Light theme applied when ThemeMode.light or system prefers light
            theme: AppTheme.lightTheme,
            // Dark theme applied when ThemeMode.dark or system prefers dark
            darkTheme: AppTheme.darkTheme,
            // Controlled by ThemeViewModel (persisted via SharedPreferences)
            themeMode: themeViewModel.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
