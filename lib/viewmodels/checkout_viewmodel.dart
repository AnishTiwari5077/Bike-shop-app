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
import 'package:bike_shop/viewmodels/auth_provider.dart';
import 'package:bike_shop/viewmodels/notification_provider.dart';
import 'package:bike_shop/viewmodels/order_provider.dart';
import 'package:bike_shop/viewmodels/payment_provider.dart';

/// ViewModel that orchestrates the checkout payment flow.
///
/// Consumed by CheckoutScreen. Removes business logic from the View.
class CheckoutViewModel extends BaseViewModel {
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
    required PaymentViewModel paymentVM,
    required OrderViewModel orderVM,
    required NotificationViewModel notificationVM,
    required AuthViewModel authVM,
  }) async {
    setLoading();

    final result = await paymentVM.payForOrder(
      amount: order.totalAmount,
      orderId: order.id,
      paymentMethodId: paymentMethodId,
    );

    if (result.isSuccess) {
      // ── Update order status ──────────────────────────────────────────────
      orderVM.updateOrderStatus(order.id, 'delivered');

      // ── Add to in-app notification list ─────────────────────────────────
      notificationVM.addNotification(
        'Payment Successful',
        'Order #${order.id.substring(0, 8)} — \$${(order.totalAmount * 1.08).toStringAsFixed(2)} charged.',
      );

      // ── Push notification ────────────────────────────────────────────────
      await NotificationService.instance.showPaymentSuccessNotification(
        orderId: order.id,
        amount: order.totalAmount * 1.08,
      );

      // ── Email confirmation ───────────────────────────────────────────────
      if (authVM.isSignedIn) {
        await NotificationService.instance.sendPaymentConfirmationEmail(
          email: authVM.email,
          name: authVM.displayName,
          orderId: order.id,
          amount: order.totalAmount * 1.08,
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
      setError(result.errorMessage ?? 'Payment failed. Please try again.');
      return false;
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef CheckoutProvider = CheckoutViewModel;
