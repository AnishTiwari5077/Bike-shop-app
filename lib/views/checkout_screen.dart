import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/order_model.dart';
import 'package:bike_shop/viewmodels/auth_provider.dart';
import 'package:bike_shop/viewmodels/checkout_viewmodel.dart';
import 'package:bike_shop/viewmodels/notification_provider.dart';
import 'package:bike_shop/viewmodels/order_provider.dart';
import 'package:bike_shop/viewmodels/payment_provider.dart';
import 'package:bike_shop/views/add_card_screen.dart';
import 'package:bike_shop/views/order_screen.dart';
import 'package:bike_shop/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final Order order;
  const CheckoutScreen({super.key, required this.order});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedCardId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      setState(() => _selectedCardId = provider.defaultCardId);
    });
  }

  // ── Pay — delegates to CheckoutViewModel ─────────────────────────────────
  Future<void> _pay() async {
    if (_selectedCardId == null) {
      _showError('Please select a payment method.');
      return;
    }

    final ok = await context.read<CheckoutViewModel>().processPayment(
      order: widget.order,
      paymentMethodId: _selectedCardId!,
      paymentVM: context.read<PaymentProvider>(),
      orderVM: context.read<OrdersProvider>(),
      notificationVM: context.read<NotificationProvider>(),
      authVM: context.read<AuthProvider>(),
    );

    if (!mounted) return;
    if (ok) {
      _showSuccessSheet();
    } else {
      final err = context.read<CheckoutViewModel>().errorMessage;
      _showError(err ?? 'Payment failed. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSuccessSheet(
        order: widget.order,
        onDone: () {
          // Pop sheet + checkout, go to Orders
          Navigator.of(context)
            ..pop() // sheet
            ..pop() // checkout
            ..pushReplacement(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
        },
      ),
    );
  }

  // ── Add card using pure Flutter screen ───────────────────────────────────
  Future<void> _addCard(PaymentProvider provider) async {
    final authProvider = context.read<AuthProvider>();

    // Check sign-in first
    if (!authProvider.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Please sign in first to add a card.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // PaymentViewModel is now auto-initialized via ChangeNotifierProxyProvider
    // in main.dart, so no manual initialize() call is needed here.
    if (!provider.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to payment service.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navigate to the pure Flutter AddCardScreen
    final added = await AddCardScreen.show(context);
    if (!mounted) return;

    if (added == true) {
      // Reload cards and select the new one (new card becomes default in provider)
      await provider.loadCards();
      setState(() {
        _selectedCardId = provider.defaultCardId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Card added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clearError();
    }
    // null + no error = user cancelled, do nothing
  }

  Future<void> _deleteCard(PaymentProvider provider, String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Card?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This card will be permanently removed.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteCard(cardId);
      if (mounted && _selectedCardId == cardId) {
        setState(() => _selectedCardId = provider.defaultCardId);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final checkoutVM = context.watch<CheckoutViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: paymentProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding(context),
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.receipt_long_outlined,
                        title: 'Order Summary',
                      ),
                      const SizedBox(height: 12),
                      _OrderSummaryCard(order: widget.order),
                      const SizedBox(height: 28),

                      _SectionHeader(
                        icon: Icons.credit_card,
                        title: 'Payment Method',
                        trailing: paymentProvider.hasCards
                            ? TextButton.icon(
                                onPressed: () => _addCard(paymentProvider),
                                icon: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppTheme.accentBlue,
                                ),
                                label: const Text(
                                  'Add Card',
                                  style: TextStyle(color: AppTheme.accentBlue),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),

                      if (!paymentProvider.hasCards)
                        _EmptyCardsWidget(
                          onAddCard: () => _addCard(paymentProvider),
                        )
                      else
                        ...paymentProvider.cards.map(
                          (card) => _CardTile(
                            card: card,
                            isSelected: _selectedCardId == card.id,
                            onTap: () =>
                                setState(() => _selectedCardId = card.id),
                            onDelete: () =>
                                _deleteCard(paymentProvider, card.id),
                          ),
                        ),

                      const SizedBox(height: 28),

                      _SectionHeader(
                        icon: Icons.calculate_outlined,
                        title: 'Price Details',
                      ),
                      const SizedBox(height: 12),
                      _PriceBreakdown(order: widget.order),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _PayButton(
        amount: widget.order.totalAmount,
        isEnabled: _selectedCardId != null && !checkoutVM.isLoading,
        isLoading: checkoutVM.isLoading,
        onPay: _pay,
      ),
    );
  }
}

// ── Subwidgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final Order order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: order.items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item.product.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final StripeCard card;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppTheme.accentBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            _brandIcon(card.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Expires ${card.expiry}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandIcon(String brand) {
    final colors = {
      'visa': const Color(0xFF1A1F71),
      'mastercard': const Color(0xFFEB001B),
      'amex': const Color(0xFF007BC1),
    };
    final color = colors[brand.toLowerCase()] ?? AppTheme.accentBlue;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.credit_card, color: color, size: 22),
    );
  }
}

class _EmptyCardsWidget extends StatelessWidget {
  final VoidCallback onAddCard;
  const _EmptyCardsWidget({required this.onAddCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.credit_card_off_outlined,
            color: Colors.white30,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No saved cards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a card to complete your purchase',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddCard,
            icon: const Icon(Icons.add),
            label: const Text('Add Card'),
          ),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final Order order;
  const _PriceBreakdown({required this.order});

  @override
  Widget build(BuildContext context) {
    final subtotal = order.totalAmount;
    final tax = subtotal * 0.08;
    final total = subtotal + tax;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _row('Shipping', 'Free', valueColor: const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _row('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12, height: 1),
          ),
          _row(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            valueStyle: const TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              labelStyle ??
              const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style:
              valueStyle ??
              TextStyle(
                color: valueColor ?? Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  final double amount;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPay;
  const _PayButton({
    required this.amount,
    required this.isEnabled,
    required this.isLoading,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final tax = amount * 0.08;
    final total = amount + tax;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? onPay : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            disabledBackgroundColor: Colors.white12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing payment…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pay \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PaymentSuccessSheet extends StatelessWidget {
  final Order order;
  final VoidCallback onDone;
  const _PaymentSuccessSheet({required this.order, required this.onDone});

  @override
  Widget build(BuildContext context) {
    // FIX: Wrapped Column in SingleChildScrollView to prevent RenderFlex
    // overflow on smaller screens / when keyboard is visible.
    return Container(
      padding: EdgeInsets.fromLTRB(
        28,
        28,
        28,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${order.id.substring(0, 8)} is now complete.',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '\$${(order.totalAmount * 1.08).toStringAsFixed(2)} charged',
              style: const TextStyle(
                color: AppTheme.accentBlue,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.tag,
                    'Order ID',
                    '#${order.id.substring(0, 8)}',
                  ),
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Date',
                    _formatDate(DateTime.now()),
                  ),
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.local_shipping_outlined,
                    'Status',
                    'Delivered',
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text(
                  'View My Orders',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
