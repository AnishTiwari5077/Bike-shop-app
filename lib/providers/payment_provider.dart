import 'package:bike_shop/service/stripe_service.dart';
import 'package:flutter/material.dart';

class PaymentProvider with ChangeNotifier {
  String? _stripeCustomerId;
  List<StripeCard> _cards = [];
  String? _defaultCardId;
  bool _isLoading = false;
  bool _isAddingCard = false; // ← prevents reset during active sheet
  String? _error;
  bool _initialized = false;

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

  Future<void> initialize({required String email, required String name}) async {
    if (_stripeCustomerId != null) {
      _initialized = true;
      await loadCards();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      debugPrint('PaymentProvider: creating customer for $email');
      final customerId = await StripeService.instance.createCustomer(
        email: email,
        name: name,
      );

      if (customerId != null) {
        _stripeCustomerId = customerId;
        _initialized = true;
        debugPrint('PaymentProvider: customer created → $customerId');
        await loadCards();
      } else {
        _error = 'Could not connect to payment service.';
        debugPrint('PaymentProvider: createCustomer returned null');
      }
    } catch (e) {
      _error = 'Payment service error: $e';
      debugPrint('PaymentProvider initialize error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCards() async {
    if (_stripeCustomerId == null) return;
    _setLoading(true);
    _error = null;

    try {
      _cards = await StripeService.instance.listCards(
        customerId: _stripeCustomerId!,
      );
      debugPrint('PaymentProvider: loaded ${_cards.length} cards');
      if (_cards.isNotEmpty && _defaultCardId == null) {
        _defaultCardId = _cards.first.id;
      }
    } catch (e) {
      debugPrint('PaymentProvider loadCards error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCard() async {
    if (_stripeCustomerId == null) {
      _error = 'Payment service not initialized.';
      notifyListeners();
      return false;
    }

    _isAddingCard = true;
    _setLoading(true);

    // Capture customerId locally — safe even if reset() is called
    final customerId = _stripeCustomerId!;

    try {
      debugPrint('PaymentProvider: opening Stripe card sheet');
      final paymentMethodId = await StripeService.instance.addCard(
        customerId: customerId,
      );

      // If reset was called while sheet was open, abort silently
      if (_stripeCustomerId == null) {
        debugPrint('PaymentProvider: reset during addCard — aborting');
        return false;
      }

      if (paymentMethodId != null) {
        debugPrint('PaymentProvider: card added → $paymentMethodId');
        await loadCards();
        _defaultCardId ??= paymentMethodId;
        return true;
      }

      debugPrint('PaymentProvider: addCard cancelled or failed');
      return false;
    } catch (e) {
      debugPrint('PaymentProvider addCard error: $e');
      return false;
    } finally {
      _isAddingCard = false;
      _setLoading(false);
    }
  }

  Future<bool> deleteCard(String paymentMethodId) async {
    try {
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
    } catch (e) {
      debugPrint('PaymentProvider deleteCard error: $e');
      return false;
    }
  }

  void setDefaultCard(String paymentMethodId) {
    _defaultCardId = paymentMethodId;
    notifyListeners();
  }

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
      debugPrint('PaymentProvider payForOrder error: $e');
      return PaymentResult.failure('Unexpected error. Please try again.');
    }
  }

  // Safe reset — waits if card sheet is open
  void reset() {
    if (_isAddingCard) {
      debugPrint('PaymentProvider: reset deferred — card sheet is open');
      // Just clear the customer so addCard aborts gracefully after sheet closes
      _stripeCustomerId = null;
      _initialized = false;
      return;
    }
    _stripeCustomerId = null;
    _cards = [];
    _defaultCardId = null;
    _isLoading = false;
    _error = null;
    _initialized = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String get uniqueId => DateTime.now().millisecondsSinceEpoch.toString();
}
