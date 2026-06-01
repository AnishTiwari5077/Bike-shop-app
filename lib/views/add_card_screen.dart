import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/viewmodels/payment_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );
    return result ?? false;
  }

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length > 16) return;
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    _cardNumberController.value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }

  void _onExpiryChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 4) return;
    String formatted = cleaned;
    if (cleaned.length >= 2) {
      formatted = '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    }
    _expiryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PaymentProvider>();
    final success = await provider.addCardWithPlainDetails(
      cardNumber: _cardNumberController.text,
      expiry: _expiryController.text,
      cvc: _cvcController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Card added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onError,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(provider.error ?? 'Failed to add card.')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clearError();
    }
  }

  String? _validateCardNumber(String? value) {
    final cleaned = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Enter a valid card number';
    }
    if (!_luhnCheck(cleaned)) return 'Invalid card number';
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use MM/YY format';
    }
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    final now = DateTime.now();
    final expiryDate = DateTime(2000 + year, month);
    if (month < 1 || month > 12) return 'Invalid month';
    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    return null;
  }

  String? _validateCvc(String? value) {
    if (value == null || value.length < 3 || value.length > 4) {
      return 'CVC must be 3-4 digits';
    }
    return null;
  }

  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n = (n % 10) + 1;
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10) == 0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final isLoading = provider.isAddingCard;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Card'), elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppTheme.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your card details are encrypted and sent directly to Stripe. We never store them.',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Card Number',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16 * Responsive.fontScale(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cardNumberController,
                    onChanged: _onCardNumberChanged,
                    validator: _validateCardNumber,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '1234 5678 9012 3456',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      prefixIcon: Icon(
                        Icons.credit_card,
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry (MM/YY)',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _expiryController,
                              onChanged: _onExpiryChanged,
                              validator: _validateExpiry,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CVC',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cvcController,
                              validator: _validateCvc,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: '123',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.38,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Accepted Cards',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.54),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _brandBadge('VISA', const Color(0xFF1A1F71)),
                      const SizedBox(width: 10),
                      _brandBadge('MC', const Color(0xFFEB001B)),
                      const SizedBox(width: 10),
                      _brandBadge('AMEX', const Color(0xFF007BC1)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        disabledBackgroundColor: colorScheme.onSurface
                            .withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_card,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Save Card',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.54,
                        ),
                        side: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.24),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == const Color(0xFFEB001B) ? Colors.redAccent : color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
