import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

/// Central service for all Stripe operations.
/// All communication with your Node backend goes through here.
class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  // ── Change this to your backend URL ─────────────────────────────────────
  // For local development: 'http://10.0.2.2:3000'  (Android emulator)
  //                        'http://localhost:3000'  (iOS simulator)
  // For production: 'https://your-backend.com'
  // static const String _baseUrl = 'http://10.0.2.2:3000';
  static const String _baseUrl = 'http://192.168.1.6:3000';

  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  // ── Create Stripe Customer ───────────────────────────────────────────────
  Future<String?> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/create-customer'),
        headers: _headers,
        body: jsonEncode({'email': email, 'name': name}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return data['customerId'] as String;
      debugPrint('createCustomer error: ${data['error']}');
      return null;
    } catch (e) {
      debugPrint('createCustomer exception: $e');
      return null;
    }
  }

  // ── Add a new card (SetupIntent flow) ───────────────────────────────────
  /// Returns the Stripe paymentMethodId if successful, null otherwise.
  Future<String?> addCard({required String customerId}) async {
    try {
      // 1. Ask backend for a SetupIntent clientSecret
      final res = await http.post(
        Uri.parse('$_baseUrl/create-setup-intent'),
        headers: _headers,
        body: jsonEncode({'customerId': customerId}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode != 200) {
        debugPrint('create-setup-intent error: ${data['error']}');
        return null;
      }
      final clientSecret = data['clientSecret'] as String;

      // 2. Show Stripe's native card sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Bike Shop',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 3. Retrieve the PaymentMethod that was just attached
      //    (SetupIntent stores it on the customer automatically)
      final setupIntent = await Stripe.instance.retrieveSetupIntent(
        clientSecret,
      );
      return setupIntent.paymentMethodId;
    } on StripeException catch (e) {
      debugPrint('StripeException (addCard): ${e.error.localizedMessage}');
      return null;
    } catch (e) {
      debugPrint('addCard exception: $e');
      return null;
    }
  }

  // ── List saved cards for a customer ─────────────────────────────────────
  Future<List<StripeCard>> listCards({required String customerId}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/payment-methods/$customerId'),
        headers: _headers,
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return (data['cards'] as List)
            .map((c) => StripeCard.fromMap(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('listCards exception: $e');
      return [];
    }
  }

  // ── Delete a saved card ──────────────────────────────────────────────────
  Future<bool> deleteCard({required String paymentMethodId}) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/payment-methods/$paymentMethodId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteCard exception: $e');
      return false;
    }
  }

  // ── Pay for an order ─────────────────────────────────────────────────────
  /// Returns a [PaymentResult] with success/failure details.
  Future<PaymentResult> payForOrder({
    required double amount,
    required String customerId,
    required String paymentMethodId,
    required String orderId,
    String currency = 'usd',
  }) async {
    try {
      // 1. Create PaymentIntent on the backend
      final res = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'customerId': customerId,
          'paymentMethodId': paymentMethodId,
          'orderId': orderId,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode != 200) {
        return PaymentResult.failure(data['error'] ?? 'Backend error');
      }

      final clientSecret = data['clientSecret'] as String;

      // 2. Confirm the payment on the Flutter side (handles 3DS automatically)
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethodId,
          ),
        ),
      );

      return PaymentResult.success();
    } on StripeException catch (e) {
      final msg = e.error.localizedMessage ?? 'Payment failed';
      debugPrint('StripeException (pay): $msg');
      return PaymentResult.failure(msg);
    } catch (e) {
      debugPrint('payForOrder exception: $e');
      return PaymentResult.failure('Unexpected error. Please try again.');
    }
  }
}

// ── Data models ─────────────────────────────────────────────────────────────

class StripeCard {
  final String id; // Stripe paymentMethodId (pm_xxx)
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  const StripeCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory StripeCard.fromMap(Map<String, dynamic> map) {
    return StripeCard(
      id: map['id'] as String,
      brand: map['brand'] as String,
      last4: map['last4'] as String,
      expMonth: map['expMonth'] as int,
      expYear: map['expYear'] as int,
    );
  }

  String get displayName =>
      '${brand[0].toUpperCase()}${brand.substring(1)} •••• $last4';

  String get expiry =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}';
}

class PaymentResult {
  final bool isSuccess;
  final String? errorMessage;

  const PaymentResult._({required this.isSuccess, this.errorMessage});

  factory PaymentResult.success() => const PaymentResult._(isSuccess: true);

  factory PaymentResult.failure(String message) =>
      PaymentResult._(isSuccess: false, errorMessage: message);
}
