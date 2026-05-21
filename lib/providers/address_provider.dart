import 'package:bike_shop/models/address_model.dart';
import 'package:flutter/material.dart';

class AddressProvider with ChangeNotifier {
  final List<Address> _addresses = [
    Address(
      id: '1',
      label: 'Home',
      fullName: 'Anish Sharma',
      phone: '+977 9841234567',
      street: '123 Durbar Marg',
      city: 'Kathmandu',
      state: 'Bagmati',
      postalCode: '44600',
      country: 'Nepal',
      isDefault: true,
    ),
    Address(
      id: '2',
      label: 'Work',
      fullName: 'Anish Sharma',
      phone: '+977 9851234567',
      street: '45 Lazimpat Road',
      city: 'Kathmandu',
      state: 'Bagmati',
      postalCode: '44603',
      country: 'Nepal',
      isDefault: false,
    ),
  ];

  List<Address> get addresses => [..._addresses];

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isEmpty ? null : _addresses.first;
    }
  }

  void addAddress(Address address) {
    if (address.isDefault) {
      _clearDefaults();
    }
    _addresses.add(address);
    notifyListeners();
  }

  void updateAddress(Address updated) {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    if (updated.isDefault) {
      _clearDefaults();
    }
    _addresses[index] = updated;
    notifyListeners();
  }

  void deleteAddress(String id) {
    final wasDefault = _addresses.firstWhere((a) => a.id == id).isDefault;
    _addresses.removeWhere((a) => a.id == id);
    if (wasDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void setDefault(String id) {
    _clearDefaults();
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      _addresses[index] = _addresses[index].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void _clearDefaults() {
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].isDefault) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
  }

  String get uniqueId => DateTime.now().millisecondsSinceEpoch.toString();
}
