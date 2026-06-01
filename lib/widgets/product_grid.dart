import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorites_viewmodel.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:go_router/go_router.dart';
import 'package:bike_shop/widgets/grid_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_shop/config/responsive.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final cartProvider = context.watch<CartProvider>();
    final favoritesProvider = context.watch<FavoritesViewModel>();
    final products = productsProvider.displayedProducts;

    if (productsProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(color: AppTheme.accentBlue),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.white30),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Uses available width (not full screen width).
        // Correct when this widget lives inside a NavigationRail body,
        // a Dialog, or any other constrained parent.
        final cols = Responsive.gridColumnsFromConstraints(constraints);
        final pad  = Responsive.horizontalPaddingFromConstraints(constraints);
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final mobileRatio = textScale > 1.1 ? 0.60 : 0.70;
        final aspectRatio = Responsive.valueFromConstraints<double>(
          constraints,
          mobile: mobileRatio,
          tablet: 0.72,
          desktop: 0.78,
        );
        final spacing = Responsive.valueFromConstraints<double>(
          constraints,
          mobile: 16.0,
          tablet: 20.0,
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GridViewWidget(
                title: product.title,
                subtitle: product.subtitle,
                price: '\$${product.price.toStringAsFixed(2)}',
                image: product.imageUrl,
                rating: product.rating,
                isFavorite: favoritesProvider.isFavorite(product.id),
                isNetworkImage: true,
                onTap: () {
                  context.push('/product', extra: product);
                },
                onAddToCart: () {
                  cartProvider.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.title} added to cart'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'VIEW',
                        onPressed: () {
                          context.push('/cart');
                        },
                      ),
                    ),
                  );
                },
                onFavorite: () {
                  favoritesProvider.toggleFavorite(product.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}
