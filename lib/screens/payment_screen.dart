import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/payment_model.dart';
import 'package:bike_shop/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCard(context),
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Card', style: TextStyle(color: Colors.white)),
      ),
      body: provider.methods.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Saved cards
                const _SectionLabel('Saved Cards & Wallets'),
                const SizedBox(height: 12),
                ...provider.methods.map(
                  (m) => _PaymentCard(
                    method: m,
                    onDelete: () => _confirmDelete(context, provider, m),
                    onSetDefault: () => provider.setDefault(m.id),
                  ),
                ),
                const SizedBox(height: 28),
                // Digital wallets (static, non-functional — scaffold for future)
                const _SectionLabel('Other Options'),
                const SizedBox(height: 12),
                _DigitalWalletTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Cash on Delivery',
                  subtitle: 'Pay when you receive',
                  color: const Color(0xFF10B981),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cash on delivery selected')),
                  ),
                ),
                const SizedBox(height: 10),
                _DigitalWalletTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'eSewa / Khalti',
                  subtitle: 'Connect your digital wallet',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digital wallet coming soon')),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_off_outlined,
              size: 48,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No payment methods',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a card to checkout faster',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _openAddCard(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _openAddCard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCardSheet(),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PaymentProvider provider,
    PaymentMethod m,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Payment Method?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${m.label}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMethod(m.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _PaymentCard({
    required this.method,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: method.isDefault
            ? Border.all(color: AppTheme.accentBlue, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (method.cardHolder != null)
                        Text(
                          method.cardHolder!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (method.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
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
            if (method.expiryDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires ${method.expiryDate}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
            if (!method.isDefault) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onSetDefault,
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.accentBlue,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Set as default',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeIcon() {
    IconData icon;
    Color color;
    switch (method.type) {
      case PaymentType.card:
        icon = Icons.credit_card;
        color = _brandColor(method.cardBrand);
        break;
      case PaymentType.paypal:
        icon = Icons.account_balance_wallet_outlined;
        color = const Color(0xFF0070BA);
        break;
      case PaymentType.applePay:
        icon = Icons.phone_iphone;
        color = Colors.white70;
        break;
      case PaymentType.googlePay:
        icon = Icons.g_mobiledata;
        color = const Color(0xFF4285F4);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _brandColor(String? brand) {
    switch (brand) {
      case 'Visa':
        return const Color(0xFF1A1F71);
      case 'Mastercard':
        return const Color(0xFFEB001B);
      case 'Amex':
        return const Color(0xFF007BC1);
      default:
        return AppTheme.accentBlue;
    }
  }
}

class _DigitalWalletTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DigitalWalletTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Add Card Sheet ----

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _isDefault = false;
  bool _obscureCvv = true;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _detectBrand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'Amex';
    return 'Card';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PaymentProvider>();
    final last4 = _numberCtrl.text
        .replaceAll(' ', '')
        .substring((_numberCtrl.text.replaceAll(' ', '').length - 4));
    final brand = _detectBrand(_numberCtrl.text.trim());

    final method = PaymentMethod(
      id: provider.uniqueId,
      type: PaymentType.card,
      label: '$brand ending in $last4',
      cardNumber: last4,
      cardHolder: _nameCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim(),
      cardBrand: brand,
      isDefault: _isDefault,
    );

    provider.addMethod(method);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card added successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Add New Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Card preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CardPreview(
                number: _numberCtrl.text,
                name: _nameCtrl.text,
                expiry: _expiryCtrl.text,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCardField(
                        _numberCtrl,
                        'Card Number',
                        Icons.credit_card,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CardNumberFormatter(),
                          LengthLimitingTextInputFormatter(19),
                        ],
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(' ', '');
                          if (digits.length < 16) {
                            return 'Enter a valid 16-digit card number';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      _buildCardField(
                        _nameCtrl,
                        'Cardholder Name',
                        Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCardField(
                              _expiryCtrl,
                              'MM/YY',
                              Icons.calendar_month_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _ExpiryFormatter(),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              validator: (v) {
                                if (v == null || v.length < 5) {
                                  return 'Invalid expiry';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCardField(
                              _cvvCtrl,
                              'CVV',
                              Icons.lock_outline,
                              obscureText: _obscureCvv,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCvv
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureCvv = !_obscureCvv),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 3) {
                                  return 'Invalid CVV';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Set as default payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isDefault,
                              onChanged: (v) => setState(() => _isDefault = v),
                              activeColor: AppTheme.accentBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text(
                            'Add Card',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}

// ---- Card Preview Widget ----

class _CardPreview extends StatelessWidget {
  final String number;
  final String name;
  final String expiry;

  const _CardPreview({
    required this.number,
    required this.name,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    final displayNumber = number.isEmpty
        ? '**** **** **** ****'
        : number.padRight(19, '*').substring(0, 19);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accentBlue, AppTheme.accentBlue.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.wifi, color: Colors.white60, size: 28),
              const Icon(Icons.credit_card, color: Colors.white70, size: 28),
            ],
          ),
          Text(
            displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    name.isEmpty ? 'YOUR NAME' : name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    expiry.isEmpty ? 'MM/YY' : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Input Formatters ----

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    String text = digits;
    if (digits.length >= 2) {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
