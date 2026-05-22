import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../config/api_config.dart'; // we'll create this

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/categories'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((json) => Category.fromMap(json)).toList();
        debugPrint('✅ Loaded ${_categories.length} categories');
      } else {
        _error = 'Failed to load categories';
      }
    } catch (e) {
      _error = 'Could not connect to server';
      debugPrint('❌ loadCategories error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
