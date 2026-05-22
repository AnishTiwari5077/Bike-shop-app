import 'dart:convert';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _baseUrl = 'http://10.0.2.2:3000';

  // ─── Initialization (call this in main()) ──────────────────────────────
  Future<void> initialize() async {
    // 1. Request FCM permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Configure initialization settings for local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 3. Initialize the plugin with required 'settings' argument
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    // 4. Create Android notification channel (required for heads-up)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bike_shop_payments',
      'Payment Notifications',
      description: 'Notifications for payment and order updates',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 5. Handle FCM messages while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Optional: get and log the FCM token
    final String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  // ─── Local notification helpers ───────────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Called when user taps a notification while app is in foreground
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped (foreground): ${response.payload}');
    // Add navigation logic here (e.g., using a global navigator key)
  }

  // Called when user taps a notification while app is in background/terminated
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint('Notification tapped (background): ${response.payload}');
    // Handle background tap – you can send an isolate‑safe message
  }

  // ─── FCM foreground handler ──────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Bike Shop',
      body: message.notification?.body ?? '',
    );
  }

  // ─── Public methods (your original API) ──────────────────────────────
  Future<void> showPaymentSuccessNotification({
    required String orderId,
    required double amount,
  }) async {
    await _showLocalNotification(
      title: '✅ Payment Successful!',
      body:
          'Order #${orderId.substring(0, 8)} confirmed. \$${amount.toStringAsFixed(2)} charged.',
    );
  }

  Future<void> sendPaymentConfirmationEmail({
    required String email,
    required String name,
    required String orderId,
    required double amount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/send-payment-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'orderId': orderId,
          'amount': amount,
          'items': items,
        }),
      );
    } catch (e) {
      debugPrint('Email send error: $e');
    }
  }
}
