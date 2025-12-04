import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/providers/product_provider.dart';
import 'package:bike_shop/widgets/bike_promo.dart';
import 'package:bike_shop/widgets/product_grid.dart';
import 'package:bike_shop/widgets/stepped_row_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;

  @override
  void initState() {
    super.initState();
    _promoController.addListener(() {
      int page = _promoController.page?.round() ?? 0;
      if (page != _currentPromoPage) {
        setState(() => _currentPromoPage = page);
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();

    return RefreshIndicator(
      onRefresh: () => productsProvider.refreshProducts(),
      color: AppTheme.accentBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPromoCarousel(),
            const SizedBox(height: 12),
            _buildPromoIndicators(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Categories'),
            const SizedBox(height: 16),
            const SteppedIconRow(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              context,
              'Featured Products',
              subtitle: 'Check out our top picks',
            ),
            const SizedBox(height: 16),
            const ProductGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back! 👋',
            style: TextStyle(
              color: AppTheme.textPrimary.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find Your Dream Bike',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel() {
    final promos = [
      {
        'title': 'Summer Sale',
        'discount': '40% Off',
        'primaryColor': const Color(0xFF2C3448),
        'secondaryColor': const Color(0xFF0C1C2D),
      },
      {
        'title': 'New Arrivals',
        'discount': '25% Off',
        'primaryColor': const Color(0xFF2D1B3D),
        'secondaryColor': const Color(0xFF0F0A1A),
      },
    ];

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _promoController,
        itemCount: promos.length,
        itemBuilder: (context, index) {
          return BikePromo(
            title: promos[index]['title'] as String,
            discount: promos[index]['discount'] as String,
            primaryColor: promos[index]['primaryColor'] as Color,
            secondaryColor: promos[index]['secondaryColor'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildPromoIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        2,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPromoPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPromoPage == index
                ? AppTheme.accentBlue
                : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
