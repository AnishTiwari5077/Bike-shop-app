// lib/providers/category_provider.dart
// ---------------------------------------------------------------------------
// CategoryViewModel — migrated from CategoryProvider to MVVM pattern.
//
// IMPORT PATH UNCHANGED: 'package:bike_shop/viewmodels/category_provider.dart'
//
// Changes from original:
//   - Extends BaseViewModel instead of using `with ChangeNotifier`
//   - Uses setLoading()/setSuccess()/setError() from base class
//   - HTTP logic and category model parsing preserved exactly
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:bike_shop/core/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../config/api_config.dart';

/// ViewModel for loading product categories from the backend API.
///
/// Consumed by HomeScreen, ExploreScreen for category filter chips.
class CategoryViewModel extends BaseViewModel {
  List<Category> _categories = [];

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Category> get categories => _categories;

  /// Backward-compatible alias for [errorMessage] from BaseViewModel.
  String? get error => errorMessage;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    setLoading();

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/categories'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((json) => Category.fromMap(json)).toList();
        debugPrint('✅ Loaded ${_categories.length} categories');
        setSuccess();
      } else {
        setError('Failed to load categories');
      }
    } catch (e) {
      setError('Could not connect to server');
      debugPrint('❌ loadCategories error: $e');
    }
  }
}

// ─── Backward-compatibility alias ────────────────────────────────────────────
typedef CategoryProvider = CategoryViewModel;
