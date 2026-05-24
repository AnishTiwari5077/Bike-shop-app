// lib/providers/favorites_viewmodel.dart
// ---------------------------------------------------------------------------
// FavoritesViewModel — migrated from FavoritesViewModel to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/favorites_viewmodel.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - Uses setLoading()/setSuccess()/setIdle() from base class
//   - All favorite toggle/add/remove/clear + SharedPreferences persistence preserved
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel managing the user's wishlist/favorites.
///
/// Persists favorite product IDs in SharedPreferences.
/// Consumed by WishListScreen, ProductDetailsScreen, ExploreScreen.
class FavoritesViewModel extends BaseViewModel {
  Set<String> _favoriteIds = {};
  static const String _storageKey = 'favorites';

  FavoritesViewModel() {
    _loadFavorites();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  Set<String> get favoriteIds => {..._favoriteIds};
  int get favoriteCount => _favoriteIds.length;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    await _saveFavorites();
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

  // ── SharedPreferences persistence ─────────────────────────────────────────

  Future<void> _loadFavorites() async {
    setLoading();
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
      setSuccess();
    } catch (e) {
      debugPrint('❌ Favorites load error: $e');
      _favoriteIds = {};
      setIdle();
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

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef FavoritesProvider = FavoritesViewModel;
