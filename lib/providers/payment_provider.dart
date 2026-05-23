import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/stripe_service.dart';

class PaymentProvider with ChangeNotifier {
  String? _stripeCustomerId;
  List<StripeCard> _cards = [];
  String? _defaultCardId;
  bool _isLoading = false;
  bool _isAddingCard = false;
  String? _error;
  bool _initialized = false;

  static const String _keyCustomerId = 'stripe_customer_id';
  static const String _keyDefaultCardId = 'stripe_default_card';

  PaymentProvider() {
    _loadSavedData().then((_) {
      // If we have a customer ID, automatically load cards (no need to wait for initialize)
      if (_stripeCustomerId != null) {
        _initialized = true;
        loadCards();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────────────────
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
  bool get isInitialized => _initialized;
  bool get isAddingCard => _isAddingCard;

  // ──────────────────────────────────────────────────────────────────────────
  // Persistence (only customer ID + default card ID)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _stripeCustomerId = prefs.getString(_keyCustomerId);
    _defaultCardId = prefs.getString(_keyDefaultCardId);
    if (_stripeCustomerId != null) {
      debugPrint('✅ Loaded saved customer ID: $_stripeCustomerId');
    }
    notifyListeners();
  }

  Future<void> _saveCustomerId() async {
    if (_stripeCustomerId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomerId, _stripeCustomerId!);
  }

  Future<void> _saveDefaultCardId() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultCardId != null) {
      await prefs.setString(_keyDefaultCardId, _defaultCardId!);
    } else {
      await prefs.remove(_keyDefaultCardId);
    }
  }

  Future<void> _clearSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomerId);
    await prefs.remove(_keyDefaultCardId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization (called after login to create customer if needed)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> initialize({required String email, required String name}) async {
    // If we already have a customer ID (from storage), just refresh cards
    if (_stripeCustomerId != null) {
      _initialized = true;
      await loadCards(); // refresh card list from backend
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      debugPrint('PaymentProvider: creating Stripe customer for $email');
      final customerId = await StripeService.instance.createCustomer(
        email: email,
        name: name,
      );

      if (customerId != null) {
        _stripeCustomerId = customerId;
        _initialized = true;
        await _saveCustomerId();
        debugPrint('✅ New customer created → $customerId');
        await loadCards(); // fetch cards (likely empty)
      } else {
        _error = 'Could not connect to payment service.';
      }
    } catch (e) {
      _error = 'Payment service error: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Load cards from Stripe (always fresh)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> loadCards() async {
    if (_stripeCustomerId == null) return;
    _setLoading(true);
    _error = null;

    try {
      _cards = await StripeService.instance.listCards(
        customerId: _stripeCustomerId!,
      );
      debugPrint('✅ Loaded ${_cards.length} cards from Stripe');
      if (_cards.isNotEmpty && _defaultCardId == null) {
        _defaultCardId = _cards.first.id;
        await _saveDefaultCardId();
      }
    } catch (e) {
      debugPrint('❌ loadCards error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Add card
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> addCardWithPlainDetails({
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) async {
    if (_stripeCustomerId == null) {
      _error = 'Payment service not initialized.';
      notifyListeners();
      return false;
    }

    final expiryParts = expiry.split('/');
    if (expiryParts.length != 2) {
      _error = 'Invalid expiry format. Use MM/YY.';
      notifyListeners();
      return false;
    }
    final expMonth = int.parse(expiryParts[0]);
    final expYear = int.parse(expiryParts[1]);

    _isAddingCard = true;
    _setLoading(true);
    _error = null;

    try {
      final tokenId = await StripeService.instance.createTokenFromCard(
        number: cardNumber.replaceAll(RegExp(r'\s+'), ''),
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
      );
      if (tokenId == null) {
        _error = 'Invalid card details.';
        return false;
      }

      final paymentMethodId = await StripeService.instance
          .attachTokenToCustomer(
            customerId: _stripeCustomerId!,
            tokenId: tokenId,
          );
      if (paymentMethodId == null) {
        _error = 'Failed to save card.';
        return false;
      }

      await loadCards(); // refresh the card list
      _defaultCardId ??= paymentMethodId;
      await _saveDefaultCardId();
      return true;
    } catch (e) {
      _error = 'Unexpected error: $e';
      return false;
    } finally {
      _isAddingCard = false;
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Delete card
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> deleteCard(String paymentMethodId) async {
    try {
      final success = await StripeService.instance.deleteCard(
        paymentMethodId: paymentMethodId,
      );
      if (success) {
        _cards.removeWhere((c) => c.id == paymentMethodId);
        if (_defaultCardId == paymentMethodId) {
          _defaultCardId = _cards.isNotEmpty ? _cards.first.id : null;
          await _saveDefaultCardId();
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deleteCard error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Set default card
  // ──────────────────────────────────────────────────────────────────────────
  void setDefaultCard(String paymentMethodId) {
    _defaultCardId = paymentMethodId;
    _saveDefaultCardId();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Pay for order
  // ──────────────────────────────────────────────────────────────────────────
  Future<PaymentResult> payForOrder({
    required double amount,
    required String orderId,
    String? paymentMethodId,
  }) async {
    final pmId = paymentMethodId ?? _defaultCardId;
    if (_stripeCustomerId == null) {
      return PaymentResult.failure('Payment service not initialized.');
    }
    if (pmId == null) {
      return PaymentResult.failure('No payment method selected.');
    }
    try {
      return await StripeService.instance.payForOrder(
        amount: amount,
        customerId: _stripeCustomerId!,
        paymentMethodId: pmId,
        orderId: orderId,
      );
    } catch (e) {
      return PaymentResult.failure('Unexpected error. Please try again.');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Reset (logout)
  // ──────────────────────────────────────────────────────────────────────────
  void reset() {
    _stripeCustomerId = null;
    _cards = [];
    _defaultCardId = null;
    _isLoading = false;
    _error = null;
    _initialized = false;
    _clearSavedData();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
