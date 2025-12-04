import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/providers/cart_provider.dart';
import 'package:bike_shop/providers/favorite_provider.dart';
import 'package:bike_shop/providers/product_provider.dart';
import 'package:bike_shop/screens/cart_screen.dart';
import 'package:bike_shop/screens/product_details_screen.dart';
import 'package:bike_shop/widgets/grid_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.white30),
              SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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
