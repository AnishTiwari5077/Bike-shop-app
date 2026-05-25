import 'package:bike_shop/models/cart_items.dart';
import 'package:bike_shop/models/product_model.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get nameStr => name;
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status; // pending, processing, shipped, delivered, cancelled
  final String? trackingNumber;

  static const double taxRate = 0.08;
  double get taxAmount => totalAmount * taxRate;
  double get totalWithTax => totalAmount + taxAmount;

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
      'status': status.nameStr,
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
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      trackingNumber: map['trackingNumber'],
    );
  }
}
