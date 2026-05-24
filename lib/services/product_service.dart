import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bike_shop/config/api_config.dart';
import 'package:bike_shop/models/product_model.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  Future<List<Product>> fetchProducts() async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/products'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['products'] as List)
          .map((j) => Product.fromMap(j))
          .toList();
    }
    throw Exception('Failed to load products: ${res.statusCode}');
  }

  Future<Product?> fetchById(String id) async {
    final res = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/products/$id'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return Product.fromMap(jsonDecode(res.body));
    return null;
  }
}
