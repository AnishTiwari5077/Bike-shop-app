import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:flutter/material.dart';

class GridViewWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String image;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? rating;
  final bool isNetworkImage;

  const GridViewWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.isFavorite = false,
    this.rating,
    this.isNetworkImage = false,
  });

  @override
  State<GridViewWidget> createState() => _GridViewWidgetState();
}

class _GridViewWidgetState extends State<GridViewWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          // ---------------- WHOLE COLUMN ----------------
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- IMAGE (Responsive Height) ----------------
              SizedBox(
                height: Responsive.value(
                  context,
                  mobile: 130.0,
                  tablet: 155.0,
                  desktop: 180.0,
                ),
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: widget.isNetworkImage
                          ? Image.network(
                              widget.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheHeight: 200,
                              cacheWidth: 200,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.error)),
                            )
                          : Image.asset(
                              widget.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheHeight: 200,
                              cacheWidth: 200,
                            ),
                    ),

                    // Favorite Button
                    if (widget.onFavorite != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onFavorite,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isFavorite
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.onSurface,
                              size: Responsive.value(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ---------------- CONTENT ----------------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(Responsive.value(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),

                      if (widget.rating != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.price,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16 * Responsive.fontScale(context),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          if (widget.onAddToCart != null)
                            GestureDetector(
                              onTap: widget.onAddToCart,
                              child: Container(
                                padding: EdgeInsets.all(Responsive.value(context, mobile: 7.0, tablet: 8.0, desktop: 9.0)),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: Responsive.value(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
