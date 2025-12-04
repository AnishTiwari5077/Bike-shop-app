import 'package:bike_shop/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  bool canIncreaseQuantity() {
    if (product.maxStock == null) return true;
    return quantity < product.maxStock!;
  }
}
