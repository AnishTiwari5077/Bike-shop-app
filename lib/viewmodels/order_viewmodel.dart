// lib/providers/order_viewmodel.dart
// ---------------------------------------------------------------------------
// OrderViewModel — migrated from OrdersProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/order_viewmodel.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - All order logic, SharedPreferences persistence, notifyListeners() preserved
//   - Added connectivity monitoring + auto-recovery for pending orders
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/services/notification_service.dart';
import 'package:bike_shop/services/stripe_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

/// ViewModel managing order history with SharedPreferences persistence.
///
/// Consumed by OrderScreen, OrderDetailsScreen, and CheckoutScreen.
class OrderViewModel extends BaseViewModel {
  final List<Order> _orders = [];
  static const String _storageKey = 'orders';

  // ── Connectivity-based recovery ──────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _customerId;
  bool _isRecovering = false;

  OrderViewModel() {
    _loadOrders();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Order> get orders => [..._orders];

  List<Order> get activeOrders => _orders.where((order) {
    return order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled;
  }).toList();

  List<Order> get completedOrders =>
      _orders.where((order) => order.status == OrderStatus.delivered).toList();

  bool get hasPendingOrders =>
      _orders.any((o) => o.status == OrderStatus.pending);

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

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        id: oldOrder.id,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        orderDate: oldOrder.orderDate,
        status: newStatus,
        trackingNumber: oldOrder.trackingNumber,
      );
      _saveOrders();
      notifyListeners();
    }
  }

  // ── Connectivity monitoring ───────────────────────────────────────────────
  /// Start listening for connectivity changes. When the device comes back
  /// online, automatically try to recover any pending orders via the backend.
  void startConnectivityMonitor(String customerId) {
    _customerId = customerId;
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _customerId != null && hasPendingOrders) {
        recoverPendingOrders(_customerId!);
      }
    });
    debugPrint('📡 Connectivity monitor started for customer: $customerId');
  }

  /// Stop listening for connectivity changes (e.g. on logout).
  void stopConnectivityMonitor() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _customerId = null;
    debugPrint('📡 Connectivity monitor stopped');
  }

  // ── Recovery ──────────────────────────────────────────────────────────────
  /// Call the backend POST /payments/recover-pending to find orders that
  /// were charged by Stripe but stuck as pending in MongoDB.
  /// Updates local state + fires push notifications for each recovered order.
  Future<void> recoverPendingOrders(String customerId) async {
    if (_isRecovering) return; // Prevent concurrent recovery
    if (!hasPendingOrders) return; // Nothing to recover
    _isRecovering = true;

    try {
      final recoveredIds = await StripeService.instance.recoverPendingOrders(
        customerId,
      );

      for (final orderId in recoveredIds) {
        updateOrderStatus(orderId, OrderStatus.delivered);

        // Fire a local push notification for each recovered order
        final order = getOrderById(orderId);
        if (order != null) {
          await NotificationService.instance.showPaymentSuccessNotification(
            orderId: orderId,
            amount: order.totalWithTax,
          );
        }
      }

      if (recoveredIds.isNotEmpty) {
        debugPrint('🔄 Auto-recovered ${recoveredIds.length} pending orders');
      }
    } catch (e) {
      debugPrint('⚠️  recoverPendingOrders error: $e');
    } finally {
      _isRecovering = false;
    }
  }

  /// Manually sync orders on pull-to-refresh
  Future<void> refreshOrders(String customerId) async {
    try {
      // 1. Force backend to check Stripe for any stuck pending orders
      await StripeService.instance.recoverPendingOrders(customerId);

      // 2. Fetch the true state of ALL orders from the backend to sync our local state.
      // This catches orders that the webhook already marked as 'paid', but our app 
      // still thinks are 'pending'.
      final backendOrders = await StripeService.instance.fetchCustomerOrders(customerId);
      
      for (final bOrder in backendOrders) {
        final bOrderId = bOrder['orderId'] as String?;
        final bStatus = bOrder['status'] as String?;
        if (bOrderId == null || bStatus == null) continue;
        
        final localOrder = getOrderById(bOrderId);
        if (localOrder != null && localOrder.status == OrderStatus.pending) {
          if (bStatus == 'paid' || bStatus == 'delivered') {
            updateOrderStatus(bOrderId, OrderStatus.delivered);
          } else if (bStatus == 'failed' || bStatus == 'canceled') {
            updateOrderStatus(bOrderId, OrderStatus.cancelled);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️  refreshOrders error: $e');
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

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

// ─── Backward-compatibility aliases ──────────────────────────────────────────
typedef OrdersProvider = OrderViewModel;
