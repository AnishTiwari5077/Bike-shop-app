import 'package:bike_shop/models/payment_model.dart';
import 'package:flutter/material.dart';

class PaymentProvider with ChangeNotifier {
  final List<PaymentMethod> _methods = [
    PaymentMethod(
      id: '1',
      type: PaymentType.card,
      label: 'Visa ending in 4242',
      cardNumber: '4242',
      cardHolder: 'Anish Sharma',
      expiryDate: '12/26',
      cardBrand: 'Visa',
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      type: PaymentType.paypal,
      label: 'PayPal — anish@email.com',
      isDefault: false,
    ),
  ];

  List<PaymentMethod> get methods => [..._methods];

  PaymentMethod? get defaultMethod {
    try {
      return _methods.firstWhere((m) => m.isDefault);
    } catch (_) {
      return _methods.isEmpty ? null : _methods.first;
    }
  }

  void addMethod(PaymentMethod method) {
    if (method.isDefault) {
      _clearDefaults();
    }
    _methods.add(method);
    notifyListeners();
  }

  void deleteMethod(String id) {
    final wasDefault = _methods.firstWhere((m) => m.id == id).isDefault;
    _methods.removeWhere((m) => m.id == id);
    if (wasDefault && _methods.isNotEmpty) {
      _methods[0] = _methods[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void setDefault(String id) {
    _clearDefaults();
    final index = _methods.indexWhere((m) => m.id == id);
    if (index != -1) {
      _methods[index] = _methods[index].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void _clearDefaults() {
    for (int i = 0; i < _methods.length; i++) {
      if (_methods[i].isDefault) {
        _methods[i] = _methods[i].copyWith(isDefault: false);
      }
    }
  }

  String get uniqueId => DateTime.now().millisecondsSinceEpoch.toString();
}
