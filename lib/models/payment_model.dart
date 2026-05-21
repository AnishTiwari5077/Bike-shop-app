enum PaymentType { card, paypal, applePay, googlePay }

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String label; // e.g. "Visa ending in 4242"
  final String? cardNumber; // last 4 digits only
  final String? cardHolder;
  final String? expiryDate; // MM/YY
  final String? cardBrand; // Visa, Mastercard, Amex
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.cardNumber,
    this.cardHolder,
    this.expiryDate,
    this.cardBrand,
    this.isDefault = false,
  });

  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? label,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cardBrand,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cardBrand: cardBrand ?? this.cardBrand,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
