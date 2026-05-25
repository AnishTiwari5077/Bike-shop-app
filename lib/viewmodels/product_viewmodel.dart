// lib/viewmodels/product_viewmodel.dart
// MVVM fix: category slug mapping belongs in the ViewModel, not the View.
// All screens call setCategory(slug) and read displayedProducts — no mapping
// logic anywhere in the widget tree.

import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:bike_shop/services/product_service.dart';

class ProductViewModel extends BaseViewModel {
  List<Product> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';

  List<Product> get products => _products;
  String? get error => errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Maps a UI category slug to the list of product category strings stored
  /// in the database.  Lives here (ViewModel) — never in a View.
  static List<String> productCategoriesFor(String slug) {
    switch (slug) {
      case 'all':
        return []; // empty = show all
      case 'bike':
      case 'bikes':
        // The home category row uses 'bike'; the explore screen may use 'bikes'.
        // Both mean: any pedal-powered vehicle.
        return ['road', 'mountain', 'hybrid'];
      case 'electric':
        return ['electric'];
      case 'mountain':
        return ['mountain'];
      case 'road':
        return ['road'];
      case 'hybrid':
        return ['hybrid'];
      case 'accessories':
      case 'gear':
        return ['accessories'];
      default:
        // Fallback: treat the slug itself as a category string.
        return [slug];
    }
  }

  /// Products visible on the home screen grid, filtered by search + category.
  List<Product> get displayedProducts {
    final cats = productCategoriesFor(_selectedCategory);
    return _products.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = cats.isEmpty || cats.contains(p.category);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Product count for a given slug — used by ExploreScreen categories tab.
  int productCountFor(String slug) {
    final cats = productCategoriesFor(slug);
    if (cats.isEmpty) return _products.length;
    return _products.where((p) => cats.contains(p.category)).length;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

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

  Future<void> refreshProducts() async => loadProducts();

  Future<Product?> fetchProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {}
    try {
      return await ProductService.instance.fetchById(id);
    } catch (e) {
      debugPrint('fetchProductById exception: $e');
    }
    return null;
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

typedef ProductsProvider = ProductViewModel;
