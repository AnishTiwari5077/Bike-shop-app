// lib/providers/product_provider.dart
// ---------------------------------------------------------------------------
// ProductViewModel — migrated from ProductsProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/product_provider.dart'
// All existing screens continue to import from this path without modification.
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - Uses base class setLoading() / setSuccess() / setError() / setIdle()
//   - Removes duplicate _isLoading/_error fields (managed by base class)
//   - Adds backward-compatible `error` getter alias for _errorMessage
// ---------------------------------------------------------------------------

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:bike_shop/services/product_service.dart';

/// ViewModel for product listing, search, filtering, and detail fetching.
///
/// Consumed by ExploreScreen, HomeScreen, ProductDetailsScreen, WishlistScreen.
/// Access via `context.watch<ProductViewModel>()` or `context.read<ProductViewModel>()`.
class ProductViewModel extends BaseViewModel {
  List<Product> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Product> get products => _products;

  /// Backward-compatible alias for [errorMessage] from BaseViewModel.
  String? get error => errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Client-side filter — used by ProductGrid, WishlistScreen, ExploreScreen.
  List<Product> get displayedProducts {
    return _products.where((product) {
      final matchesSearch =
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ── Load products from MongoDB via API ────────────────────────────────────
  Future<void> loadProducts() async {
    setLoading();

    try {
      _products = await ProductService.instance.fetchProducts();
      setSuccess();
      debugPrint('✅ Loaded ${_products.length} products');
    } catch (e) {
      setError('Could not connect to server. Please check your connection.');
      debugPrint('❌ loadProducts exception: $e');
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // ── Fetch a single product by Mongo ID ───────────────────────────────────
  Future<Product?> fetchProductById(String id) async {
    // Return from cache if already loaded
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {}

    // Otherwise fetch from API
    try {
      return await ProductService.instance.fetchById(id);
    } catch (e) {
      debugPrint('fetchProductById exception: $e');
    }
    return null;
  }

  /// Synchronous cache lookup — used where an async call isn't possible.
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
// Existing screens that reference `ProductsProvider` by name (not type-safe
// generic access) continue to compile. New code should use `ProductViewModel`.
typedef ProductsProvider = ProductViewModel;
