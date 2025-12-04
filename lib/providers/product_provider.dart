import 'package:bike_shop/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

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

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
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
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _products = _getDummyProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> _getDummyProducts() {
    return [
      Product(
        id: '1',
        title: 'PEUGEOT - LR01',
        subtitle: 'Road Bike',
        price: 1999.99,
        imageUrl: 'assets/images/bike.png',
        description:
            'A lightweight, high-performance road bike with steel frame and responsive geometry.',
        rating: 4.8,
        category: 'road',
        maxStock: 10,
      ),
      Product(
        id: '2',
        title: 'SMITH - Trade',
        subtitle: 'Road Helmet',
        price: 120.00,
        imageUrl: 'assets/images/bike.png',
        images: ['assets/images/bike.png', 'assets/images/bike.png'],
        description:
            'A durable road helmet with advanced airflow and impact protection for safety.',
        rating: 4.5,
        category: 'accessories',
        maxStock: 50,
      ),
      Product(
        id: '3',
        title: 'PILOT - Chromoly',
        subtitle: 'Mountain Bike',
        price: 2199.00,
        imageUrl: 'assets/images/bike.png',
        description:
            'Built for trails and tough terrain. Chromoly steel frame ensures durability and control.',
        rating: 4.9,
        category: 'mountain',
        maxStock: 8,
      ),
      Product(
        id: '4',
        title: 'TREK - FX 3',
        subtitle: 'Hybrid Bike',
        price: 849.99,
        imageUrl: 'assets/images/bike.png',
        description:
            'Perfect for commuting and fitness rides with lightweight aluminum frame.',
        rating: 4.6,
        category: 'bike',
        maxStock: 15,
      ),
      Product(
        id: '5',
        title: 'VOLT - E-Cruiser',
        subtitle: 'Electric Bike',
        price: 3299.00,
        imageUrl: 'assets/images/bike.png',
        description:
            'Powerful electric bike with 50-mile range and pedal assist technology.',
        rating: 4.7,
        category: 'electric',
        maxStock: 5,
      ),
      Product(
        id: '6',
        title: 'GIRO - Syntax',
        subtitle: 'Cycling Helmet',
        price: 199.99,
        imageUrl: 'assets/images/bike.png',
        description: 'Premium helmet with MIPS technology for enhanced safety.',
        rating: 4.8,
        category: 'accessories',
        maxStock: 30,
      ),
    ];
  }
}
