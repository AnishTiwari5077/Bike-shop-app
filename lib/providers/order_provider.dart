import 'package:bike_shop/models/order_model.dart';
import 'package:flutter/material.dart';

class OrdersProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  // Active orders: not delivered or cancelled
  List<Order> get activeOrders => _orders.where((order) {
    final s = order.status.toLowerCase().trim();
    return s != 'delivered' && s != 'cancelled';
  }).toList();

  // Completed orders: delivered
  List<Order> get completedOrders => _orders
      .where((order) => order.status.toLowerCase().trim() == 'delivered')
      .toList();

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        id: oldOrder.id,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        orderDate: oldOrder.orderDate,
        status: newStatus.toLowerCase().trim(),
        trackingNumber: oldOrder.trackingNumber,
      );
      notifyListeners();
    }
  }
}
