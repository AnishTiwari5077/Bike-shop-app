import 'package:bike_shop/models/cart_items.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get cartItems => _items.values.toList();
  int get itemCount =>
      _items.values.fold<int>(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  int get uniqueItemCount => _items.length;

  bool isInCart(String productId) => _items.containsKey(productId);
  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  void addToCart(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      final currentQuantity = _items[product.id]!.quantity;
      final newQuantity = currentQuantity + quantity;
      if (product.maxStock != null && newQuantity > product.maxStock!) {
        return;
      }
      _items[product.id]!.quantity = newQuantity;
    } else {
      if (product.maxStock != null && quantity > product.maxStock!) {
        quantity = product.maxStock!;
      }
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      final cartItem = _items[productId]!;
      if (cartItem.canIncreaseQuantity()) {
        cartItem.quantity++;
        notifyListeners();
      }
    }
  }

  void decreaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
        notifyListeners();
      } else {
        removeFromCart(productId);
      }
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeFromCart(productId);
      } else {
        final product = _items[productId]!.product;
        if (product.maxStock != null && quantity > product.maxStock!) {
          quantity = product.maxStock!;
        }
        _items[productId]!.quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  CartItem? getCartItem(String productId) => _items[productId];

  double getDiscount() {
    if (totalAmount > 100) {
      return totalAmount * 0.10;
    }
    return 0.0;
  }

  double get finalAmount => totalAmount - getDiscount();

  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'uniqueItems': uniqueItemCount,
      'subtotal': totalAmount,
      'discount': getDiscount(),
      'total': finalAmount,
    };
  }
}
