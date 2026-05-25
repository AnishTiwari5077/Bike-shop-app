// lib/views/wishlist_screen.dart
// Fixed: renamed from whilist_screen.dart (typo corrected)
// Fixed: theme-aware colors replacing hardcoded Colors.white*
// Fixed: responsive padding

import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorites_viewmodel.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WishListScreen extends StatelessWidget {
  const WishListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesViewModel>();
    final productsProvider = context.watch<ProductsProvider>();
    final cartProvider = context.watch<CartProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final favoriteProducts = productsProvider.products
        .where((product) => favorites.isFavorite(product.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (favoriteProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Clear Wishlist?',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    content: Text(
                      'Remove all items from wishlist?',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          favorites.clearFavorites();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: favoriteProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items you love',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.54),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 16,
              ),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
                return _buildWishlistItem(
                  context,
                  product,
                  favorites,
                  cartProvider,
                );
              },
            ),
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    Product product,
    FavoritesViewModel favorites,
    CartProvider cart,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => favorites.toggleFavorite(product.id),
      child: GestureDetector(
        onTap: () => context.push('/product', extra: product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Price section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${product.price}',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Add to Cart Button
              IconButton(
                icon: Icon(
                  Icons.shopping_cart_outlined,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  cart.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.title} added to cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Remove from favorites
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                onPressed: () => favorites.toggleFavorite(product.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
