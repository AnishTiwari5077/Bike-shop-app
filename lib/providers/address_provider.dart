import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  static const String _storageKey = 'saved_addresses';

  AddressProvider() {
    _loadAddresses(); // Load saved addresses when provider is created
  }

  List<Address> get addresses => [..._addresses];

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isEmpty ? null : _addresses.first;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CRUD operations (auto‑save after each change)
  // ──────────────────────────────────────────────────────────────────────────

  void addAddress(Address address) {
    if (address.isDefault) {
      _clearAllDefaults();
    }
    _addresses.add(address);
    _saveAddresses();
    notifyListeners();
  }

  void updateAddress(Address updated) {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    if (updated.isDefault) {
      _clearAllDefaults();
    }
    _addresses[index] = updated;
    _saveAddresses();
    notifyListeners();
  }

  void deleteAddress(String id) {
    final wasDefault = _addresses.firstWhere((a) => a.id == id).isDefault;
    _addresses.removeWhere((a) => a.id == id);
    if (wasDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    _saveAddresses();
    notifyListeners();
  }

  void setDefault(String id) {
    _clearAllDefaults();
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index != -1) {
      _addresses[index] = _addresses[index].copyWith(isDefault: true);
    }
    _saveAddresses();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper methods
  // ──────────────────────────────────────────────────────────────────────────

  void _clearAllDefaults() {
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].isDefault) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
  }

  String get uniqueId => DateTime.now().millisecondsSinceEpoch.toString();

  // ──────────────────────────────────────────────────────────────────────────
  // SharedPreferences persistence
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      _addresses = []; // ✅ Start empty – no hardcoded addresses
      notifyListeners();
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _addresses = decoded
          .map((item) => Address.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _addresses = [];
    }
    notifyListeners();
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = _addresses
        .map((a) => a.toMap())
        .toList();
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  // ✅ Optional: clear all addresses (e.g., on logout)
  Future<void> clearAllAddresses() async {
    _addresses = [];
    await _saveAddresses();
    notifyListeners();
  }
}
