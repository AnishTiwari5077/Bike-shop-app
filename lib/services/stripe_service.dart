import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bike_shop/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static String get _baseUrl => ApiConfig.baseUrl;

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

  // ── Mark order as paid directly ───────────────────────────────────────────
  // Called after payment is confirmed on the client side.
  // Ensures status is updated even when the Stripe webhook is delayed or
  // pointing to the wrong URL (e.g. during development).
  Future<void> _confirmOrderPaid(String orderId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/confirm-order'),
            headers: _headers,
            body: jsonEncode({'orderId': orderId}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        debugPrint('✅ Order $orderId confirmed as paid in MongoDB');
      } else {
        final data = jsonDecode(res.body);
        debugPrint('⚠️  confirmOrderPaid error: ${data['error']}');
      }
    } catch (e) {
      // Non-fatal: log and continue. Webhook will eventually update the status
      // once the correct URL is configured in the Stripe dashboard.
      debugPrint('⚠️  confirmOrderPaid exception (non-fatal): $e');
    }
  }

  // ── Pay for an order ──────────────────────────────────────────────────────
  final Set<String> _processingOrderIds = {};

  Future<PaymentResult> payForOrder({
    required double amount,
    required String customerId,
    required String paymentMethodId,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required List<Map<String, dynamic>> items,
    String currency = 'usd',
  }) async {
    // Prevent duplicate in-flight requests for the same order
    if (_processingOrderIds.contains(orderId)) {
      debugPrint(
        '⚠️  Payment already in progress for order $orderId — ignoring duplicate tap',
      );
      return PaymentResult.failure('Payment already in progress. Please wait.');
    }

    _processingOrderIds.add(orderId);

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/create-payment-intent'),
            headers: _headers,
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'customerId': customerId,
              'paymentMethodId': paymentMethodId,
              'orderId': orderId,
              'customerName': customerName,
              'customerEmail': customerEmail,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);

      // Backend says already paid → return already paid result
      if (res.statusCode == 400 &&
          (data['error'] as String?)?.contains('already been paid') == true) {
        debugPrint('ℹ️  Order $orderId already paid in MongoDB');
        return PaymentResult.alreadyPaid(
          'This order has already been paid. Please refresh your orders.',
        );
      }

      if (res.statusCode != 200) {
        return PaymentResult.failure(data['error'] ?? 'Backend error');
      }

      final clientSecret = data['clientSecret'] as String;

      try {
        // Confirm payment with Stripe SDK (handles 3DS automatically)
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: PaymentMethodParams.cardFromMethodId(
            paymentMethodData: PaymentMethodDataCardFromMethod(
              paymentMethodId: paymentMethodId,
            ),
          ),
        );
      } on StripeException catch (e) {
        final code = e.error.code;
        final msg = e.error.localizedMessage ?? '';

        // FIX: "PaymentIntent already succeeded" means the payment went through
        // on a previous attempt but the app crashed or lost connectivity before
        // _confirmOrderPaid was called. Stripe throws this error when you try
        // to confirm an already-succeeded PaymentIntent. Treat it as success
        // and fall through to _confirmOrderPaid so MongoDB is updated.
        final alreadySucceeded =
            code == FailureCode.Failed &&
            (msg.toLowerCase().contains('already succeeded') ||
                msg.toLowerCase().contains('previously confirmed'));

        if (!alreadySucceeded) {
          // FIX Issue 6: detect network-related Stripe exceptions and surface
          // a friendly message instead of the raw IOException dump.
          final isNetworkError =
              msg.toLowerCase().contains('ioexception') ||
              msg.toLowerCase().contains('failed to connect') ||
              msg.toLowerCase().contains('connection') ||
              msg.toLowerCase().contains('socketexception');

          final userMessage = isNetworkError
              ? 'Connection interrupted. Please check your internet and try again.'
              : (msg.isNotEmpty ? msg : 'Payment failed');

          debugPrint('StripeException: $msg');
          return PaymentResult.failure(userMessage);
        }

        debugPrint('ℹ️  PaymentIntent already succeeded for order $orderId');
        // Force MongoDB to sync right now
        await _confirmOrderPaid(orderId);

        return PaymentResult.alreadyPaid(
          'This order has already been paid. Please refresh your orders.',
        );
      }

      // Payment confirmed normally.
      // Update MongoDB status directly — don't rely solely on the webhook.
      await _confirmOrderPaid(orderId);

      return PaymentResult.success();
    } on SocketException {
      // FIX Issue 6: device has no network connectivity at all
      debugPrint('payForOrder: no internet (SocketException)');
      return PaymentResult.failure(
        'Connection interrupted. Please check your internet and try again.',
      );
    } on TimeoutException {
      // FIX Issue 6: request timed out (server unreachable)
      debugPrint('payForOrder: request timed out');
      return PaymentResult.failure(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('payForOrder exception: $e');
      return PaymentResult.failure('Unexpected error. Please try again.');
    } finally {
      _processingOrderIds.remove(orderId);
    }
  }

  // ── Recover pending orders after network reconnect ────────────────────────
  // Calls the backend recovery endpoint that checks Stripe for actual payment
  // status of all pending orders for the given customer.
  Future<List<String>> recoverPendingOrders(String customerId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/payments/recover-pending'),
            headers: _headers,
            body: jsonEncode({'customerId': customerId}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final recovered = (data['recovered'] as List)
            .map((r) => r['orderId'] as String)
            .toList();
        debugPrint('🔄 Backend recovered ${recovered.length} orders');
        return recovered;
      }
      debugPrint('⚠️  recoverPendingOrders status: ${res.statusCode}');
      return [];
    } catch (e) {
      debugPrint('⚠️  recoverPendingOrders exception: $e');
      return [];
    }
  }

  // ── Fetch all orders for a customer ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchCustomerOrders(
    String customerId,
  ) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/payments/orders/$customerId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('⚠️  fetchCustomerOrders exception: $e');
      return [];
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
  final bool isAlreadyPaid;
  final String? errorMessage;

  const PaymentResult._({
    required this.isSuccess,
    this.isAlreadyPaid = false,
    this.errorMessage,
  });

  factory PaymentResult.success() => const PaymentResult._(isSuccess: true);

  factory PaymentResult.alreadyPaid(String message) => PaymentResult._(
    isSuccess: false,
    isAlreadyPaid: true,
    errorMessage: message,
  );

  factory PaymentResult.failure(String message) =>
      PaymentResult._(isSuccess: false, errorMessage: message);
}
