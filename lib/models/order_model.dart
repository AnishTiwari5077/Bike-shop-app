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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'trackingNumber': trackingNumber,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, List<Product> products) {
    final items = (map['items'] as List).map((itemMap) {
      final product = products.firstWhere(
        (p) => p.id == itemMap['productId'],
        orElse: () => Product(
          id: itemMap['productId'],
          title: 'Unknown Product',
          subtitle: '',
          description: '',
          price: itemMap['price'],
          imageUrl: '',
          category: 'bike',
        ),
      );
      return CartItem(product: product, quantity: itemMap['quantity']);
    }).toList();

    return Order(
      id: map['id'],
      items: items,
      totalAmount: map['totalAmount'],
      orderDate: DateTime.parse(map['orderDate']),
      status: map['status'].toString().toLowerCase().trim(),
      trackingNumber: map['trackingNumber'],
    );
  }
}
