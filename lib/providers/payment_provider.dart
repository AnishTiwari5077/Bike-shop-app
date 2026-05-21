import 'package:bike_shop/service/stripe_service.dart';

import 'package:flutter/material.dart';

/// Manages the user's Stripe customer ID and their saved cards.
/// Fetches real cards from Stripe via the backend.
class PaymentProvider with ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────
  String? _stripeCustomerId; // Persisted in SharedPreferences in production
  List<StripeCard> _cards = [];
  String? _defaultCardId;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  String? get stripeCustomerId => _stripeCustomerId;
  List<StripeCard> get cards => [..._cards];
  String? get defaultCardId => _defaultCardId;
  StripeCard? get defaultCard => _cards.isEmpty
      ? null
      : _cards.firstWhere(
          (c) => c.id == _defaultCardId,
          orElse: () => _cards.first,
        );
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCards => _cards.isNotEmpty;

  // ── Initialize (call once after user logs in) ────────────────────────────
  /// Creates a Stripe customer for the user if one doesn't exist yet.
  /// In production, store customerId in your database and restore it here.
  Future<void> initialize({required String email, required String name}) async {
    // In production: load customerId from SharedPreferences / your backend
    // For now we create a fresh one each session (dev only)
    if (_stripeCustomerId != null) {
      await loadCards();
      return;
    }

    _setLoading(true);
    final customerId = await StripeService.instance.createCustomer(
      email: email,
      name: name,
    );

    if (customerId != null) {
      _stripeCustomerId = customerId;
      await loadCards();
    } else {
      _error = 'Could not connect to payment service.';
    }
    _setLoading(false);
  }

  // ── Load cards from Stripe ───────────────────────────────────────────────
  Future<void> loadCards() async {
    if (_stripeCustomerId == null) return;
    _setLoading(true);
    _error = null;

    _cards = await StripeService.instance.listCards(
      customerId: _stripeCustomerId!,
    );

    if (_cards.isNotEmpty && _defaultCardId == null) {
      _defaultCardId = _cards.first.id;
    }

    _setLoading(false);
  }

  // ── Add a new card ───────────────────────────────────────────────────────
  Future<bool> addCard() async {
    if (_stripeCustomerId == null) return false;
    _setLoading(true);

    final paymentMethodId = await StripeService.instance.addCard(
      customerId: _stripeCustomerId!,
    );

    if (paymentMethodId != null) {
      await loadCards(); // Refresh list from Stripe
      _defaultCardId ??= paymentMethodId;
      _setLoading(false);
      return true;
    }

    _setLoading(false);
    return false;
  }

  // ── Delete a card ────────────────────────────────────────────────────────
  Future<bool> deleteCard(String paymentMethodId) async {
    final success = await StripeService.instance.deleteCard(
      paymentMethodId: paymentMethodId,
    );

    if (success) {
      _cards.removeWhere((c) => c.id == paymentMethodId);
      if (_defaultCardId == paymentMethodId) {
        _defaultCardId = _cards.isNotEmpty ? _cards.first.id : null;
      }
      notifyListeners();
    }
    return success;
  }

  // ── Set default card ─────────────────────────────────────────────────────
  void setDefaultCard(String paymentMethodId) {
    _defaultCardId = paymentMethodId;
    notifyListeners();
  }

  // ── Pay for an order ─────────────────────────────────────────────────────
  Future<PaymentResult> payForOrder({
    required double amount,
    required String orderId,
    String? paymentMethodId, // uses default if null
  }) async {
    final pmId = paymentMethodId ?? _defaultCardId;

    if (_stripeCustomerId == null || pmId == null) {
      return PaymentResult.failure('No payment method selected.');
    }

    return StripeService.instance.payForOrder(
      amount: amount,
      customerId: _stripeCustomerId!,
      paymentMethodId: pmId,
      orderId: orderId,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String get uniqueId => DateTime.now().millisecondsSinceEpoch.toString();
}
