// lib/viewmodels/checkout_viewmodel.dart
// ---------------------------------------------------------------------------
// CheckoutViewModel — orchestrates the full payment + order + notification
// flow that was previously inside CheckoutScreen._pay().
//
// The View calls processPayment() and reacts only to ViewState.
// ---------------------------------------------------------------------------

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/order_model.dart';
import 'package:bike_shop/services/notification_service.dart';
import 'package:bike_shop/viewmodels/auth_viewmodel.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/notification_viewmodel.dart';
import 'package:bike_shop/viewmodels/order_viewmodel.dart';
import 'package:bike_shop/viewmodels/payment_viewmodel.dart';

/// ViewModel that orchestrates the checkout payment flow.
///
/// Consumed by CheckoutScreen. Removes business logic from the View.
class CheckoutViewModel extends BaseViewModel {
  AuthViewModel? _authVM;
  PaymentViewModel? _paymentVM;
  OrderViewModel? _orderVM;
  NotificationViewModel? _notificationVM;

  void update(
    AuthViewModel auth,
    PaymentViewModel payment,
    OrderViewModel order,
    NotificationViewModel notif,
  ) {
    _authVM = auth;
    _paymentVM = payment;
    _orderVM = order;
    _notificationVM = notif;
  }

  /// Orchestrates order creation and cart clearing.
  /// Spawns the domain [Order] object and persists it using [orderVM].
  Future<Order> createOrder(CartViewModel cart) async {
    setLoading();
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(cart.cartItems),
      totalAmount: cart.finalAmount,
      orderDate: DateTime.now(),
      status: OrderStatus.pending,
    );
    _orderVM!.addOrder(order);
    cart.clearCart();
    setSuccess();
    return order;
  }

  /// Processes payment for [order] using [paymentMethodId].
  ///
  /// Delegates to [paymentVM], then updates order status, fires notifications
  /// and sends the confirmation email when the payment succeeds.
  ///
  /// Returns `true` on success, `false` on failure.
  /// Sets [ViewState.error] with a message on failure so the View can react.
  Future<bool> processPayment({
    required Order order,
    required String paymentMethodId,
  }) async {
    setLoading();

    // ── OPTIMISTIC UPDATE ──────────────────────────────────────────────────
    // Immediately mark the order as delivered so the "Pay Now" button
    // disappears from the Orders screen. If the payment fails we revert.
    // This prevents double-pay when the user navigates back during a
    // long-running network call.
    _orderVM!.updateOrderStatus(order.id, OrderStatus.delivered);

    final result = await _paymentVM!.payForOrder(
      amount: order.totalAmount,
      orderId: order.id,
      paymentMethodId: paymentMethodId,
      customerName: _authVM!.displayName,
      customerEmail: _authVM!.email,
      items: order.items
          .map(
            (i) => {
              'productId': i.product.id,
              'title': i.product.title,
              'price': i.product.price,
              'quantity': i.quantity,
              // totalPrice = unit price × quantity; useful for receipts
              'totalPrice': i.totalPrice,
            },
          )
          .toList(),
    );

    if (result.isSuccess) {
      // Order is already marked delivered (optimistic update above).

      // ── Add to in-app notification list ─────────────────────────────────
      _notificationVM!.addNotification(
        'Payment Successful',
        'Order #${order.id.substring(0, 8)} — \$${order.totalAmount.toStringAsFixed(2)} charged.',
      );

      // ── Push notification ────────────────────────────────────────────────
      await NotificationService.instance.showPaymentSuccessNotification(
        orderId: order.id,
        amount: order.totalAmount,
      );

      // ── Email confirmation ───────────────────────────────────────────────
      if (_authVM!.isSignedIn) {
        await NotificationService.instance.sendPaymentConfirmationEmail(
          email: _authVM!.email,
          name: _authVM!.displayName,
          orderId: order.id,
          amount: order.totalAmount,
          items: order.items
              .map(
                (i) => {
                  'title': i.product.title,
                  'quantity': i.quantity,
                  'price': i.totalPrice,
                },
              )
              .toList(),
        );
      }

      setSuccess();
      return true;
    } else {
      // ── REVERT OPTIMISTIC UPDATE ─────────────────────────────────────────
      // Payment failed — put the order back to pending so the user can retry.
      _orderVM!.updateOrderStatus(order.id, OrderStatus.pending);
      setError(result.errorMessage ?? 'Payment failed. Please try again.');
      return false;
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef CheckoutProvider = CheckoutViewModel;
