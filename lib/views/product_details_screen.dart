// lib/views/product_details_screen.dart
// FIXES:
//   - VIEW CART SnackBar action: Navigator.pushReplacement → context.push('/cart')
//     so the back stack is preserved (user can return to product detail)
//   - Removed import of cart_screen.dart (decoupled via GoRouter)
//   - Quantity selector colours now use colorScheme so they're visible in light mode
//   - image indicator dots: Colors.white → colorScheme.onSurface for light mode
//   - Product images now use Image.network instead of Image.asset

import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorites_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesViewModel>();
    final isFavorite = favorites.isFavorite(widget.product.id);
    final images = widget.product.images ?? [widget.product.imageUrl];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return Container(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,

                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },

                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 100,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),

                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentImageIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.4,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () =>
                        favorites.toggleFavorite(widget.product.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.subtitle,
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.product.title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 28 * Responsive.fontScale(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (widget.product.rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),

                              const SizedBox(width: 4),

                              Text(
                                widget.product.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                '(${(widget.product.rating! * 324).toInt()} reviews)',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        Text(
                          'Description',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18 * Responsive.fontScale(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          widget.product.description,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildFeatures(context),

                        const SizedBox(height: 24),

                        _buildQuantitySelector(context),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomBar(context, cart),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18 * Responsive.fontScale(context),
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildFeatureItem(context, Icons.verified_user, 'Warranty', '2 Years'),

        _buildFeatureItem(
          context,
          Icons.local_shipping,
          'Free Shipping',
          'Available',
        ),

        _buildFeatureItem(
          context,
          Icons.support_agent,
          'Support',
          '24/7 Customer Service',
        ),

        if (widget.product.maxStock != null)
          _buildFeatureItem(
            context,
            Icons.inventory,
            'Stock',
            '${widget.product.maxStock} units available',
          ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentBlue, size: 20),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),

              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18 * Responsive.fontScale(context),
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove,
                  color: _quantity > 1
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.add,
                  color:
                      (widget.product.maxStock == null ||
                          _quantity < widget.product.maxStock!)
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                onPressed:
                    (widget.product.maxStock == null ||
                        _quantity < widget.product.maxStock!)
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Price',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '\$${(widget.product.price * _quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24 * Responsive.fontScale(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: () {
                cart.addToCart(widget.product, quantity: _quantity);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added $_quantity ${widget.product.title} to cart',
                    ),
                    action: SnackBarAction(
                      label: 'VIEW CART',
                      onPressed: () {
                        context.push('/cart');
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
