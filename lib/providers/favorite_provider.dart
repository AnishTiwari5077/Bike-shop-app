import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  Set<String> _favoriteIds = {};
  static const String _storageKey = 'favorites';
  bool _isLoading = true;

  FavoritesProvider() {
    _loadFavorites();
  }

  Set<String> get favoriteIds => {..._favoriteIds};
  int get favoriteCount => _favoriteIds.length;
  bool get isLoading => _isLoading;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    await _saveFavorites(); // ✅ now awaited
    notifyListeners();
  }

  Future<void> addFavorite(String productId) async {
    if (_favoriteIds.add(productId)) {
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String productId) async {
    if (_favoriteIds.remove(productId)) {
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> clearFavorites() async {
    if (_favoriteIds.isNotEmpty) {
      _favoriteIds.clear();
      await _saveFavorites();
      notifyListeners();
    }
  }

  // ─── SharedPreferences ──────────────────────────────────────────────
  Future<void> _loadFavorites() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _favoriteIds = decoded.map((id) => id.toString()).toSet();
        debugPrint('✅ Loaded ${_favoriteIds.length} favorites');
      } else {
        _favoriteIds = {};
        debugPrint('ℹ️ No saved favorites found');
      }
    } catch (e) {
      debugPrint('❌ Favorites load error: $e');
      _favoriteIds = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = _favoriteIds.toList();
      await prefs.setString(_storageKey, jsonEncode(list));
      debugPrint('💾 Saved ${list.length} favorites');
    } catch (e) {
      debugPrint('❌ Favorites save error: $e');
    }
  }
}
