import 'package:bike_shop/models/cart_items.dart';
import 'package:bike_shop/models/product_model.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status; // pending, processing, shipped, delivered, cancelled
  final String? trackingNumber;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.trackingNumber,
  });

  /// Converts the order to a Map for saving in SharedPreferences.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) {
        return {
          'productId': item.product.id,
          'title': item.product.title,
          'imageUrl': item.product.imageUrl,
          'price': item.product.price,
          'quantity': item.quantity,
        };
      }).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'trackingNumber': trackingNumber,
    };
  }

  /// Creates an Order from a Map (loaded from SharedPreferences).
  /// No external product list needed – we reconstruct a minimal Product object.
  factory Order.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List).map((itemMap) {
      // Recreate a Product with the stored data (enough for order history)
      final product = Product(
        id: itemMap['productId'],
        title: itemMap['title'] ?? 'Product',
        subtitle: '', // not stored, but you can add if needed
        description: '',
        price: (itemMap['price'] as num).toDouble(),
        imageUrl: itemMap['imageUrl'] ?? '',
        category: '',
        maxStock: null,
      );
      return CartItem(product: product, quantity: itemMap['quantity'] as int);
    }).toList();

    return Order(
      id: map['id'],
      items: itemsList,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      orderDate: DateTime.parse(map['orderDate']),
      status: map['status'].toString().toLowerCase().trim(),
      trackingNumber: map['trackingNumber'],
    );
  }
}
