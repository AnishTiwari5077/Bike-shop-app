import 'dart:ui';

import 'package:bike_shop/config/router.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/viewmodels/address_viewmodel.dart';
import 'package:bike_shop/viewmodels/auth_viewmodel.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/category_viewmodel.dart';
import 'package:bike_shop/viewmodels/checkout_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorites_viewmodel.dart';
import 'package:bike_shop/viewmodels/notification_viewmodel.dart';
import 'package:bike_shop/viewmodels/order_viewmodel.dart';
import 'package:bike_shop/viewmodels/payment_viewmodel.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:bike_shop/services/notification_service.dart';
import 'package:bike_shop/viewmodels/theme_viewmodel.dart';
import 'package:bike_shop/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

// ─── Background handler ───────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background message received: ${message.messageId}');

  // ── CRITICAL FIX ──────────────────────────────────────────────────────────
  // Only manually show a notification for pure DATA messages
  // (message.notification == null means no notification payload).
  //
  // If your server sends a notification payload (which yours does — e.g. the
  // payment success push), FCM + the OS will show it automatically.
  // Calling localNotifications.show() on top of that causes DUPLICATE notifications.
  //
  // So: if message has a notification payload → do nothing, OS handles it.
  //     if message is data-only → show it manually below.
  // ─────────────────────────────────────────────────────────────────────────
  if (message.data.isNotEmpty && message.notification == null) {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );
    await localNotifications.initialize(settings: initSettings);

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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'bike_shop_payments',
          'Payment Notifications',
          channelDescription: 'Notifications for payment and order updates',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final int id = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    await localNotifications.show(
      id: id,
      title: message.data['title'] ?? 'Bike Shop Update',
      body: message.data['body'] ?? '',
      notificationDetails: details,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ─── Image cache limit (prevents memory issues) ───────────────────────────
  PaintingBinding.instance.imageCache.maximumSize = 20;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20; // 10 MB

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Must be registered before any other FCM calls
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Notifications and FCM might throw JS errors on Web if missing service workers
    await NotificationService.instance.initialize();
  }

  Stripe.publishableKey =
      'pk_test_51SXvBHHKrFDpSpIkVxuXl5nyLySIPsmOBh6EOuy8Ih2xXqdFY3KdaSy0ga75PTjAEpG3wQtaGfKZFnyLr0WOwFD5002qz17NV2';
  if (!kIsWeb) {
    await Stripe.instance.applySettings();
  }

  runApp(const BikeShopApp());
}

class BikeShopApp extends StatelessWidget {
  const BikeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
        ChangeNotifierProvider(create: (_) => AddressViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, PaymentViewModel>(
          create: (_) => PaymentViewModel(),
          update: (_, auth, payment) {
            if (payment != null) {
              if (auth.isSignedIn) {
                if (!payment.isInitialized) {
                  payment.initialize(email: auth.email, name: auth.displayName);
                }
              } else {
                if (payment.isInitialized) {
                  payment.reset();
                }
              }
            }
            return payment!;
          },
        ),
        ChangeNotifierProxyProvider<PaymentViewModel, OrderViewModel>(
          create: (_) => OrderViewModel(),
          update: (_, paymentVM, orderVM) {
            if (orderVM != null) {
              final customerId = paymentVM.stripeCustomerId;
              if (customerId != null) {
                // Start monitoring connectivity for auto-recovery
                orderVM.startConnectivityMonitor(customerId);
              } else {
                orderVM.stopConnectivityMonitor();
              }
            }
            return orderVM!;
          },
        ),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProxyProvider4<
          AuthViewModel,
          PaymentViewModel,
          OrderViewModel,
          NotificationViewModel,
          CheckoutViewModel
        >(
          create: (_) => CheckoutViewModel(),
          update: (_, auth, payment, order, notif, checkout) =>
              checkout!..update(auth, payment, order, notif),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryViewModel()..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel()..loadProducts(),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp.router(
            title: 'Bike Shop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeViewModel.themeMode,
            routerConfig: appRouter,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
          );
        },
      ),
    );
  }
}
