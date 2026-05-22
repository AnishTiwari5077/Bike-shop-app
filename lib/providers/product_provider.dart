import 'dart:convert';
import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // ── Must match StripeService._baseUrl ────────────────────────────────────
  // Android emulator  → 'http://10.0.2.2:3000'
  // iOS simulator     → 'http://localhost:3000'
  // Physical device   → 'http://<your-local-IP>:3000'
  //  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const String _baseUrl = 'http://192.168.1.6:3000';
  // static const String _baseUrl = 'http://10.0.2.2:3000';

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Client-side filter — used by ProductGrid, WishlistScreen, ExploreScreen
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/products');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> productsJson = data['products'] as List<dynamic>;

        _products = productsJson
            .map((json) => Product.fromMap(json as Map<String, dynamic>))
            .toList();

        _error = null;
        debugPrint('✅ Loaded ${_products.length} products from MongoDB');
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _error = body['error'] as String? ?? 'Failed to load products';
        debugPrint('❌ loadProducts HTTP error: $_error');
      }
    } catch (e) {
      _error = 'Could not connect to server. Please check your connection.';
      debugPrint('❌ loadProducts exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final res = await http
          .get(Uri.parse('$_baseUrl/products/$id'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return Product.fromMap(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchProductById exception: $e');
    }
    return null;
  }

  /// Synchronous cache lookup — used where an async call isn't possible
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
