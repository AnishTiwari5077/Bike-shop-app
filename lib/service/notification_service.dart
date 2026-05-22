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

  // ─── Initialization ──────────────────────────────────────────────
  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const AndroidInitializationSettings
    androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ); // only used for the app icon in the notification drawer, not for the small icon
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

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

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    final String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  // ─── Local notification helper (ICON REMOVED) ───────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'bike_shop_payments',
      'Payment Notifications',
      channelDescription: 'Notifications for payment and order updates',
      importance: Importance.high,
      priority: Priority.high,
      // icon: 'ic_launcher', // <-- REMOVED – causes resource not found error
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
  }

  // Called when user taps a notification while app is in background/terminated
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint('Notification tapped (background): ${response.payload}');
  }

  // ─── FCM foreground handler ──────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Bike Shop',
      body: message.notification?.body ?? '',
    );
  }

  // ─── Public methods ──────────────────────────────────────────────
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
