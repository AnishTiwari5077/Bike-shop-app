// screens/category_products_screen.dart
import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/product_model.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categorySlug;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  // Map display category to actual product category/ies
  List<String> _getProductCategories(String slug) {
    switch (slug) {
      case 'bikes':
        // Bikes should show ALL bike types: road, mountain, electric, hybrid
        return ['road', 'mountain', 'electric', 'hybrid'];
      case 'gear':
        return ['accessories'];
      case 'mountain':
        return ['mountain'];
      case 'road':
        return ['road'];
      case 'electric':
        return ['electric'];
      case 'hybrid':
        return ['hybrid'];
      case 'all':
        return []; // Empty means show all
      default:
        return [slug];
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();

    // Get the actual product categories for filtering
    final productCategories = _getProductCategories(categorySlug);

    // Filter products based on mapped categories
    final categoryProducts = productCategories.isEmpty
        ? productsProvider
              .products // Show all products for 'all' category
        : productsProvider.products
              .where((product) => productCategories.contains(product.category))
              .toList();

    // Debug output
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 CategoryProductsScreen:');
    print('   Display: $categoryName (slug: $categorySlug)');
    print('   Looking for categories: $productCategories');
    print('   Products found: ${categoryProducts.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: categoryProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products in $categoryName',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Looking for: ${productCategories.join(", ")}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 16,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.gridColumns(context),
                childAspectRatio: Responsive.value(
                  context,
                  mobile: 0.75,
                  tablet: 0.78,
                  desktop: 0.80,
                ),
                crossAxisSpacing: Responsive.value(
                  context,
                  mobile: 12.0,
                  tablet: 16.0,
                ),
                mainAxisSpacing: Responsive.value(
                  context,
                  mobile: 12.0,
                  tablet: 16.0,
                ),
              ),
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) =>
                  _CategoryProductCard(product: categoryProducts[index]),
            ),
    );
  }
}

// Product card widget – identical in style to your home screen grid
class _CategoryProductCard extends StatelessWidget {
  final Product product;

  const _CategoryProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/product', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.image_not_supported,
                      color: colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  ),
                ),
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
