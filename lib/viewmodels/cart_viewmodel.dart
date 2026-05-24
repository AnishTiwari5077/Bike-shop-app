// lib/providers/cart_viewmodel.dart
// ---------------------------------------------------------------------------
// CartViewModel — migrated from CartProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/cart_viewmodel.dart'
// All existing screens continue to import from this path without modification.
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - All cart logic, SharedPreferences persistence, and notifyListeners()
//     calls preserved exactly
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_items.dart';
import '../models/product_model.dart';
import 'package:flutter/material.dart';

/// ViewModel managing the shopping cart.
///
/// Persists cart items in SharedPreferences so they survive app restarts.
/// Consumed by CartScreen, CheckoutScreen, and any widget showing item count.
class CartViewModel extends BaseViewModel {
  final Map<String, CartItem> _items = {};
  static const String _storageKey = 'shopping_cart';

  CartViewModel() {
    _loadCart();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get cartItems => _items.values.toList();
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  int get uniqueItemCount => _items.length;

  bool isInCart(String productId) => _items.containsKey(productId);
  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  // ── Actions ───────────────────────────────────────────────────────────────

  void addToCart(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      final newQty = _items[product.id]!.quantity + quantity;
      if (product.maxStock != null && newQty > product.maxStock!) return;
      _items[product.id]!.quantity = newQty;
    } else {
      if (product.maxStock != null && quantity > product.maxStock!) {
        quantity = product.maxStock!;
      }
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final item = _items[productId];
    if (item != null && item.canIncreaseQuantity()) {
      item.quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    final item = _items[productId];
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
        _saveCart();
        notifyListeners();
      } else {
        removeFromCart(productId);
      }
    }
  }

  void updateQuantity(String productId, int quantity) {
    final item = _items[productId];
    if (item != null) {
      if (quantity <= 0) {
        removeFromCart(productId);
      } else {
        final max = item.product.maxStock;
        if (max != null && quantity > max) quantity = max;
        item.quantity = quantity;
        _saveCart();
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  CartItem? getCartItem(String productId) => _items[productId];

  double getDiscount() => totalAmount > 100 ? totalAmount * 0.10 : 0.0;
  double get finalAmount => totalAmount - getDiscount();

  Map<String, dynamic> getCartSummary() => {
    'itemCount': itemCount,
    'uniqueItems': uniqueItemCount,
    'subtotal': totalAmount,
    'discount': getDiscount(),
    'total': finalAmount,
  };

  /// Creates an [Order] from current cart items, clears the cart, and returns
  /// the Order. The caller is responsible for passing it to [OrderViewModel].
  ///
  /// Uses [BaseViewModel.isLoading] so the View can react without a local bool.
  Future<Order> checkout() async {
    setLoading();

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(cartItems),
      totalAmount: finalAmount,
      orderDate: DateTime.now(),
      status: 'pending',
    );

    clearCart();
    setSuccess();
    return order;
  }

  // ── SharedPreferences persistence ───────────────────────────────────────────────

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      for (var map in decoded) {
        final product = Product.fromMap(map['product']);
        final quantity = map['quantity'] as int;
        _items[product.id] = CartItem(product: product, quantity: quantity);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = [];
    for (var item in _items.values) {
      data.add({'product': item.product.toMap(), 'quantity': item.quantity});
    }
    await prefs.setString(_storageKey, jsonEncode(data));
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef CartProvider = CartViewModel;
