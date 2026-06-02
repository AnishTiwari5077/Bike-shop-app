// lib/views/category_product_screen.dart
// MVVM fix: all slug→category mapping removed from View.
// The View asks ProductViewModel for the filtered list — no business logic here.
// Removed all print() statements (View should not log business data).

import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String categorySlug;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductsProvider>();

    // Delegate all filtering logic to the ViewModel — pure MVVM.
    final categoryProducts = vm.productsForCategory(categorySlug);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: categoryProducts.isEmpty
          ? _buildEmpty(context, categoryName)
          : OrientationBuilder(
              builder: (context, orientation) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final pad = Responsive.horizontalPaddingFromConstraints(
                      constraints,
                    );

                    return GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: pad,
                        vertical: 16,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.gridColumnsFromConstraints(
                          constraints,
                          orientation,
                        ),
                        childAspectRatio: Responsive.valueFromConstraints(
                          constraints,
                          mobile: 0.75,
                          tablet: 0.78,
                          desktop: 0.80,
                          orientation: orientation,
                        ),
                        crossAxisSpacing: Responsive.valueFromConstraints(
                          constraints,
                          mobile: 12.0,
                          tablet: 16.0,
                          orientation: orientation,
                        ),
                        mainAxisSpacing: Responsive.valueFromConstraints(
                          constraints,
                          mobile: 12.0,
                          tablet: 16.0,
                          orientation: orientation,
                        ),
                      ),
                      itemCount: categoryProducts.length,
                      itemBuilder: (context, index) {
                        return _CategoryProductCard(
                          product: categoryProducts[index],
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No products in $name',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final Product product;

  const _CategoryProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return Container(
                      color: cs.onSurface.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: cs.onSurface.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: cs.onSurface.withValues(alpha: 0.54),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(
                Responsive.value(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14 * Responsive.fontScale(context),
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
                      fontSize: 16 * Responsive.fontScale(context),
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
