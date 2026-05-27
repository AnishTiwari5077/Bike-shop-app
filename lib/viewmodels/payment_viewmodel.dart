// lib/viewmodels/payment_viewmodel.dart
// ---------------------------------------------------------------------------
// PaymentViewModel — migrated from PaymentProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/payment_viewmodel.dart'
//
// Changes from original:
//   - payForOrder() now accepts customerName, customerEmail, items and passes
//     them through to StripeService so MongoDB gets the full order document.
// ---------------------------------------------------------------------------

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel managing Stripe customer, saved payment cards, and order payments.
///
/// Consumed by PaymentScreen, AddCardScreen, CheckoutScreen.
class PaymentViewModel extends BaseViewModel {
  String? _stripeCustomerId;
  List<StripeCard> _cards = [];
  String? _defaultCardId;
  bool _isAddingCard = false;
  bool _initialized = false;

  static const String _keyCustomerId = 'stripe_customer_id';
  static const String _keyDefaultCardId = 'stripe_default_card';

  PaymentViewModel();

  // ── Getters ───────────────────────────────────────────────────────────────

  String? get stripeCustomerId => _stripeCustomerId;
  List<StripeCard> get cards => [..._cards];
  String? get defaultCardId => _defaultCardId;
  StripeCard? get defaultCard => _cards.isEmpty
      ? null
      : _cards.firstWhere(
          (c) => c.id == _defaultCardId,
          orElse: () => _cards.first,
        );

  /// Backward-compatible alias for [errorMessage] from BaseViewModel.
  String? get error => errorMessage;
  bool get hasCards => _cards.isNotEmpty;
  bool get isInitialized => _initialized;
  bool get isAddingCard => _isAddingCard;

  // ── Persistence (only customer ID + default card ID) ─────────────────────

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

  // ── Initialization (called after login to create customer if needed) ──────

  Future<void> initialize({required String email, required String name}) async {
    if (_initialized) return;
    _initialized = true;

    setLoading();

    await _loadSavedData();

    // If we already have a customer ID (from storage), just refresh cards
    if (_stripeCustomerId != null) {
      await loadCards();
      setSuccess();
      return;
    }

    try {
      debugPrint('PaymentViewModel: creating Stripe customer for $email');
      final customerId = await StripeService.instance.createCustomer(
        email: email,
        name: name,
      );

      if (customerId != null) {
        _stripeCustomerId = customerId;
        await _saveCustomerId();
        debugPrint('✅ New customer created → $customerId');
        await loadCards();
        setSuccess();
      } else {
        setError('Could not connect to payment service.');
      }
    } catch (e) {
      setError('Payment service error: $e');
    }
  }

  // ── Load cards from Stripe (always fresh) ─────────────────────────────────

  Future<void> loadCards() async {
    if (_stripeCustomerId == null) return;
    setLoading();

    try {
      _cards = await StripeService.instance.listCards(
        customerId: _stripeCustomerId!,
      );
      debugPrint('✅ Loaded ${_cards.length} cards from Stripe');
      if (_cards.isNotEmpty && _defaultCardId == null) {
        _defaultCardId = _cards.first.id;
        await _saveDefaultCardId();
      }
      setSuccess();
    } catch (e) {
      debugPrint('❌ loadCards error: $e');
      setIdle(); // Don't show error for background refresh
    }
  }

  // ── Add card ──────────────────────────────────────────────────────────────

  bool checkCanAddCard(bool isSignedIn) {
    if (!isSignedIn) {
      setError('Please sign in first to add a card.');
      return false;
    }
    if (!_initialized) {
      setError('Could not connect to payment service.');
      return false;
    }
    return true;
  }

  Future<bool> addCardWithPlainDetails({
    required String cardNumber,
    required String expiry,
    required String cvc,
  }) async {
    if (_stripeCustomerId == null) {
      setError('Payment service not initialized.');
      return false;
    }

    final expiryParts = expiry.split('/');
    if (expiryParts.length != 2) {
      setError('Invalid expiry format. Use MM/YY.');
      return false;
    }
    final expMonth = int.parse(expiryParts[0]);
    final expYear = int.parse(expiryParts[1]);

    _isAddingCard = true;
    setLoading();

    try {
      final tokenId = await StripeService.instance.createTokenFromCard(
        number: cardNumber.replaceAll(RegExp(r'\s+'), ''),
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
      );
      if (tokenId == null) {
        setError('Invalid card details.');
        _isAddingCard = false;
        return false;
      }

      final paymentMethodId = await StripeService.instance
          .attachTokenToCustomer(
            customerId: _stripeCustomerId!,
            tokenId: tokenId,
          );
      if (paymentMethodId == null) {
        setError('Failed to save card.');
        _isAddingCard = false;
        return false;
      }

      await loadCards();
      _defaultCardId ??= paymentMethodId;
      await _saveDefaultCardId();
      _isAddingCard = false;
      setSuccess();
      return true;
    } catch (e) {
      setError('Unexpected error: $e');
      _isAddingCard = false;
      return false;
    }
  }

  // ── Delete card ───────────────────────────────────────────────────────────

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

  // ── Set default card ──────────────────────────────────────────────────────

  void setDefaultCard(String paymentMethodId) {
    _defaultCardId = paymentMethodId;
    _saveDefaultCardId();
    notifyListeners();
  }

  // ── Pay for order ─────────────────────────────────────────────────────────
  // FIX: added customerName, customerEmail, items so the full order document
  // is saved to MongoDB (previously they were empty strings / empty array).

  Future<PaymentResult> payForOrder({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required List<Map<String, dynamic>> items,
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
        customerName: customerName,
        customerEmail: customerEmail,
        items: items,
      );
    } catch (e) {
      return PaymentResult.failure('Unexpected error. Please try again.');
    }
  }

  // ── Reset (logout) ────────────────────────────────────────────────────────

  void reset() {
    _stripeCustomerId = null;
    _cards = [];
    _defaultCardId = null;
    _isAddingCard = false;
    _initialized = false;
    _clearSavedData();
    setIdle();
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef PaymentProvider = PaymentViewModel;
