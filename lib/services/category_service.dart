// lib/services/category_service.dart
// ---------------------------------------------------------------------------
// CategoryService — HTTP layer for the /categories endpoint.
//
// Mirrors the structure of ProductService so all network calls are
// concentrated in the services/ layer, out of ViewModels.
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bike_shop/config/api_config.dart';
import 'package:bike_shop/models/category_model.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  Future<List<Category>> fetchCategories() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/categories'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      debugPrint('✅ CategoryService: loaded ${data.length} categories');
      return data.map((json) => Category.fromMap(json)).toList();
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }
}
