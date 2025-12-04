import 'package:bike_shop/models/order_model.dart';
import 'package:flutter/material.dart';

class OrdersProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  List<Order> get activeOrders => _orders
      .where(
        (order) => order.status != 'delivered' && order.status != 'cancelled',
      )
      .toList();

  List<Order> get completedOrders =>
      _orders.where((order) => order.status == 'delivered').toList();

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
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      // Create new order with updated status
      final oldOrder = _orders[orderIndex];
      _orders[orderIndex] = Order(
        id: oldOrder.id,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        orderDate: oldOrder.orderDate,
        status: newStatus,
        trackingNumber: oldOrder.trackingNumber,
      );
      notifyListeners();
    }
  }
}
