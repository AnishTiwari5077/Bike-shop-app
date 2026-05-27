import 'dart:convert';
import 'package:bike_shop/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const String _baseUrl = ApiConfig.baseUrl;

  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  // ── Create Stripe Customer ───────────────────────────────────────────────
  Future<String?> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/create-customer'),
            headers: _headers,
            body: jsonEncode({'email': email, 'name': name}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return data['customerId'] as String;
      debugPrint('createCustomer error: ${data['error']}');
      return null;
    } catch (e) {
      debugPrint('createCustomer exception: $e');
      return null;
    }
  }

  // ── Create a Stripe token from raw card details ──────────────────────────
  Future<String?> createTokenFromCard({
    required String number,
    required int expMonth,
    required int expYear,
    required String cvc,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.stripe.com/v1/tokens'),
            headers: {
              'Authorization': 'Bearer ${Stripe.publishableKey}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'card[number]': number,
              'card[exp_month]': expMonth.toString(),
              'card[exp_year]': expYear.toString(),
              'card[cvc]': cvc,
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['id'] != null) {
        debugPrint('✅ Stripe token created: ${data['id']}');
        return data['id'] as String;
      }
      debugPrint('❌ Stripe token error: ${data['error']['message']}');
      return null;
    } catch (e) {
      debugPrint('createTokenFromCard exception: $e');
      return null;
    }
  }

  // ── Attach a token to a customer ─────────────────────────────────────────
  Future<String?> attachTokenToCustomer({
    required String customerId,
    required String tokenId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/attach-token'),
            headers: _headers,
            body: jsonEncode({'customerId': customerId, 'tokenId': tokenId}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['paymentMethodId'] != null) {
        debugPrint('✅ Token attached → PM: ${data['paymentMethodId']}');
        return data['paymentMethodId'] as String;
      }
      debugPrint('❌ attachTokenToCustomer error: ${data['error']}');
      return null;
    } catch (e) {
      debugPrint('attachTokenToCustomer exception: $e');
      return null;
    }
  }

  // ── Attach PaymentMethod directly ────────────────────────────────────────
  Future<String?> attachCardToCustomer({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/attach-payment-method'),
            headers: _headers,
            body: jsonEncode({
              'customerId': customerId,
              'paymentMethodId': paymentMethodId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return paymentMethodId;
      debugPrint('attachCardToCustomer error: ${data['error']}');
      return null;
    } catch (e) {
      debugPrint('attachCardToCustomer exception: $e');
      return null;
    }
  }

  // ── List saved cards ──────────────────────────────────────────────────────
  Future<List<StripeCard>> listCards({required String customerId}) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/payments/payment-methods/$customerId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

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

  // ── Delete a saved card ───────────────────────────────────────────────────
  Future<bool> deleteCard({required String paymentMethodId}) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_baseUrl/payments/payment-methods/$paymentMethodId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteCard exception: $e');
      return false;
    }
  }

  // ── Pay for an order ──────────────────────────────────────────────────────
  // FIX 1: Added _processingOrderIds to track in-progress payments
  //         This prevents the same order from being submitted twice
  //         even if the user taps Pay very quickly multiple times.
  final Set<String> _processingOrderIds = {};

  Future<PaymentResult> payForOrder({
    required double amount,
    required String customerId,
    required String paymentMethodId,
    required String orderId,
    String currency = 'usd',
  }) async {
    // ── FIX 1: Prevent duplicate in-flight requests for the same order ──────
    if (_processingOrderIds.contains(orderId)) {
      debugPrint(
        '⚠️  Payment already in progress for order $orderId — ignoring duplicate tap',
      );
      return PaymentResult.failure('Payment already in progress. Please wait.');
    }

    _processingOrderIds.add(orderId);

    try {
      // ── FIX 2: Increased timeout — network drops shouldn't cause retries ──
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/create-payment-intent'),
            headers: _headers,
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'customerId': customerId,
              'paymentMethodId': paymentMethodId,
              'orderId': orderId, // backend uses this as idempotency key
            }),
          )
          .timeout(const Duration(seconds: 20)); // FIX 2: was 15s, now 20s

      final data = jsonDecode(res.body);

      // ── FIX 3: If backend says already paid, treat as success ─────────────
      if (res.statusCode == 400 &&
          (data['error'] as String?)?.contains('already been paid') == true) {
        debugPrint('ℹ️  Order $orderId already paid — returning success');
        return PaymentResult.success();
      }

      if (res.statusCode != 200) {
        return PaymentResult.failure(data['error'] ?? 'Backend error');
      }

      final clientSecret = data['clientSecret'] as String;

      // Confirm payment — handles 3DS automatically
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
      debugPrint('StripeException: $msg');
      return PaymentResult.failure(msg);
    } catch (e) {
      debugPrint('payForOrder exception: $e');
      return PaymentResult.failure('Unexpected error. Please try again.');
    } finally {
      // ── Always remove from processing set when done ─────────────────────
      _processingOrderIds.remove(orderId);
    }
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class StripeCard {
  final String id;
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
