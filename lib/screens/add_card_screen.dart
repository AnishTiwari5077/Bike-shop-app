import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/providers/payment_provider.dart';
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
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
    // Optional Luhn check
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

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Add New Card'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your card details are encrypted and sent directly to Stripe. We never store them.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Card number
              const Text(
                'Card Number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNumberController,
                onChanged: _onCardNumberChanged,
                validator: _validateCardNumber,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '1234 5678 9012 3456',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.credit_card,
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
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

              // Expiry & CVC row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry (MM/YY)',
                          style: TextStyle(
                            color: Colors.white,
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
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: AppTheme.cardBackground,
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
                        const Text(
                          'CVC',
                          style: TextStyle(
                            color: Colors.white,
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
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '123',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: AppTheme.cardBackground,
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

              // Accepted cards
              const Text(
                'Accepted Cards',
                style: TextStyle(color: Colors.white54, fontSize: 13),
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

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    disabledBackgroundColor: Colors.white12,
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
                            Icon(Icons.add_card, color: Colors.white, size: 20),
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

              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
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
    );
  }

  Widget _brandBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
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
