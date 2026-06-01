import 'dart:convert';
//import 'package:firebase_core/firebase_core.dart';
import 'package:bike_shop/config/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String get _baseUrl => ApiConfig.baseUrl;
  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    if (!kIsWeb) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
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
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    final String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'bike_shop_payments',
          'Payment Notifications',
          channelDescription: 'Notifications for payment and order updates',
          importance: Importance.high,
          priority: Priority.high,
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

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped (foreground): ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint('Notification tapped (background): ${response.payload}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Bike Shop',
      body: message.notification?.body ?? '',
    );
  }

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

  // ─── Email with full logging ─────────────────────────────────────────────
  Future<void> sendPaymentConfirmationEmail({
    required String email,
    required String name,
    required String orderId,
    required double amount,
    required List<Map<String, dynamic>> items,
  }) async {
    debugPrint(
      '📧 Sending payment confirmation email to: $email for order: $orderId, amount: \$${amount.toStringAsFixed(2)}',
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/email/send-payment-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'orderId': orderId,
          'amount': amount,
          'items': items,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ Email sent successfully to $email.');
      } else {
        debugPrint(
          '❌ Email send failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Email send error: $e. Ensure backend is running on $_baseUrl',
      );
    }
  }
}
