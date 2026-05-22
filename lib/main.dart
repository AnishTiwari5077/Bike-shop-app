import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/providers/address_provider.dart';
import 'package:bike_shop/providers/auth_provider.dart';
import 'package:bike_shop/providers/cart_provider.dart';
import 'package:bike_shop/providers/favorite_provider.dart';
import 'package:bike_shop/providers/order_provider.dart';
import 'package:bike_shop/providers/payment_provider.dart';
import 'package:bike_shop/providers/product_provider.dart';
import 'package:bike_shop/screens/main_screen.dart';
import 'package:bike_shop/service/notification_service.dart';
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

  // 5. Show the notification
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'bike_shop_payments',
    'Payment Notifications',
    channelDescription: 'Notifications for payment and order updates',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_launcher',
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

  // ─── Image cache limit (prevents memory bloat) ───────────────────────
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductsProvider()..loadProducts(),
        ),
      ],
      child: MaterialApp(
        title: 'Bike Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
