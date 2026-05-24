// lib/providers/order_provider.dart
// ---------------------------------------------------------------------------
// OrderViewModel — migrated from OrdersProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/order_provider.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - All order logic, SharedPreferences persistence, notifyListeners() preserved
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

/// ViewModel managing order history with SharedPreferences persistence.
///
/// Consumed by OrderScreen, OrderDetailsScreen, and CheckoutScreen.
class OrderViewModel extends BaseViewModel {
  final List<Order> _orders = [];
  static const String _storageKey = 'orders';

  OrderViewModel() {
    _loadOrders();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Order> get orders => [..._orders];

  List<Order> get activeOrders => _orders.where((order) {
    final s = order.status.toLowerCase().trim();
    return s != 'delivered' && s != 'cancelled';
  }).toList();

  List<Order> get completedOrders => _orders
      .where((order) => order.status.toLowerCase().trim() == 'delivered')
      .toList();

  // ── Actions ───────────────────────────────────────────────────────────────

  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrders();
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
      _saveOrders();
      notifyListeners();
    }
  }

  // ── SharedPreferences persistence ─────────────────────────────────────────

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _orders.clear();
      for (var map in decoded) {
        _orders.add(Order.fromMap(map));
      }
      debugPrint('✅ Loaded ${_orders.length} orders');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = _orders
        .map((o) => o.toMap())
        .toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }
}

// ─── Backward-compatibility aliases ──────────────────────────────────────────
typedef OrdersProvider = OrderViewModel;
