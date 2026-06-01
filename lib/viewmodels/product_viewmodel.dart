// lib/viewmodels/product_viewmodel.dart
// MVVM fix: category slug mapping belongs in the ViewModel, not the View.
// All screens call setCategory(slug) and read displayedProducts — no mapping
// logic anywhere in the widget tree.

import 'dart:async';
import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:bike_shop/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductViewModel extends BaseViewModel {
  List<Product> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  List<String> _recentSearches = [];
  Timer? _debounceTimer;

  static const String _recentSearchesKey = 'recent_searches';

  List<Product> get products => _products;
  String? get error => errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get recentSearches => [..._recentSearches];

  List<Product> get dealsProducts =>
      _products.where((p) => p.isDeal == true).toList();

  List<Product> get newArrivalsProducts =>
      _products.where((p) => p.isNewArrival == true).toList();

  ProductViewModel() {
    _loadRecentSearches();
  }

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

  /// Products filtered by category for specific screens (e.g. CategoryProductsScreen)
  List<Product> productsForCategory(String slug) {
    final cats = productCategoriesFor(slug);
    if (cats.isEmpty) return _products;
    return _products.where((p) => cats.contains(p.category)).toList();
  }

  /// Product count for a given slug — used by ExploreScreen categories tab.
  int productCountFor(String slug) {
    final cats = productCategoriesFor(slug);
    if (cats.isEmpty) return _products.length;
    return _products.where((p) => cats.contains(p.category)).length;
  }

  void setSearchQuery(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.isEmpty) {
      _searchQuery = '';
      setIdle();
      notifyListeners();
      return;
    }

    setLoading();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      setSuccess();
      notifyListeners();
    });
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

  // ── SharedPreferences Recent Searches ───────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_recentSearchesKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _recentSearches = decoded.map((e) => e.toString()).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentSearchesKey, jsonEncode(_recentSearches));
    } catch (e) {
      debugPrint('Error saving recent searches: $e');
    }
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    await _saveRecentSearches();
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    await _saveRecentSearches();
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _saveRecentSearches();
    notifyListeners();
  }
}

typedef ProductsProvider = ProductViewModel;
