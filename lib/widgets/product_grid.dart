import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/viewmodels/cart_provider.dart';
import 'package:bike_shop/viewmodels/favorite_provider.dart';
import 'package:bike_shop/viewmodels/product_provider.dart';
import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
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
    final favoritesProvider = context.watch<FavoritesProvider>();
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

    // ✅ FIX: Use MediaQuery to detect large text scaling and shrink the ratio
    // so the card always has enough vertical room regardless of font scale.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final mobileRatio = textScale > 1.1 ? 0.60 : 0.70;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          // ✅ FIX: ratio now adapts to the system text scale factor
          childAspectRatio: Responsive.value(
            context,
            mobile: mobileRatio,
            tablet: 0.72,
            desktop: 0.78,
          ),
          crossAxisSpacing: Responsive.value(
            context,
            mobile: 16.0,
            tablet: 20.0,
          ),
          mainAxisSpacing: Responsive.value(
            context,
            mobile: 16.0,
            tablet: 20.0,
          ),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
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
  }
}
