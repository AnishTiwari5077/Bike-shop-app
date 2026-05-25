import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/category_model.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/category_viewmodel.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';
import 'package:bike_shop/views/category_product_screen.dart';
import 'package:bike_shop/views/product_details_screen.dart';
import 'package:bike_shop/widgets/search_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearchModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.54),
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Deals'),
            Tab(text: 'New Arrivals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [CategoriesTab(), DealsTab(), NewArrivalsTab()],
      ),
    );
  }
}

// ==================== CATEGORIES TAB (FULLY FIXED) ====================
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().loadCategories();
    });
  }

  // Helper method to get product count for a category
  int _getProductCount(Category cat, List<Product> products) {
    switch (cat.slug) {
      case 'all':
        return products.length;
      case 'bikes':
        // Bikes count = all road + mountain + electric + hybrid
        return products
            .where(
              (p) =>
                  p.category == 'road' ||
                  p.category == 'mountain' ||
                  p.category == 'electric' ||
                  p.category == 'hybrid',
            )
            .length;
      case 'gear':
        return products.where((p) => p.category == 'accessories').length;
      default:
        return products.where((p) => p.category == cat.slug).length;
    }
  }

  // Helper method to get the actual product category slug for navigation
  String _getNavigationSlug(Category cat) {
    switch (cat.slug) {
      case 'bikes':
        return 'bikes'; // Will be handled by CategoryProductsScreen
      case 'gear':
        return 'gear'; // Will be handled by CategoryProductsScreen
      default:
        return cat.slug;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = context.watch<CategoryViewModel>();
    final productsProvider = context.watch<ProductsProvider>();

    if (categoryViewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentBlue),
      );
    }

    if (categoryViewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              categoryViewModel.error!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => categoryViewModel.loadCategories(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (categoryViewModel.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => categoryViewModel.loadCategories(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Filter categories to show (exclude new-arrival and deals from categories tab)
    final displayCategories = categoryViewModel.categories.where((cat) {
      return cat.slug != 'new-arrival' && cat.slug != 'deals';
    }).toList();

    return RefreshIndicator(
      onRefresh: () => categoryViewModel.loadCategories(),
      color: AppTheme.accentBlue,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 16,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final cat = displayCategories[index];
          final productCount = _getProductCount(cat, productsProvider.products);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildCategoryImage(cat),
                ),
              ),
              title: Text(
                cat.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '$productCount products',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.54),
                  fontSize: 13,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
                size: 16,
              ),
              onTap: () {
                final navigationSlug = _getNavigationSlug(cat);
                print('🖱️ Tapped: ${cat.name} -> slug: $navigationSlug');
                context.push(
                  '/category',
                  extra: {'slug': navigationSlug, 'name': cat.name},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryImage(Category cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return Image.network(
        cat.imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildIconFallback(cat);
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Failed to load image for ${cat.name}: $error');
          return _buildIconFallback(cat);
        },
      );
    }

    print('⚠️ No imageUrl for ${cat.name}, using fallback');
    return _buildIconFallback(cat);
  }

  Widget _buildIconFallback(Category cat) {
    final iconData = _getIconData(cat.icon);
    final color = _getColorFromHex(cat.color);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: Colors.white, size: 30),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'terrain':
        return Icons.terrain;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'build':
        return Icons.build;
      case 'bolt':
        return Icons.electric_bike;
      case 'apps':
        return Icons.apps;
      case 'pedal_bike':
        return Icons.pedal_bike;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('0xFF$hexColor'));
    }
    return AppTheme.accentBlue;
  }
}

// ==================== DEALS TAB ====================
class DealsTab extends StatelessWidget {
  const DealsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final deals = productsProvider.products
        .where((p) => p.isDeal == true)
        .toList();

    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No deals available',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flash Sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Up to 60% off',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '02:45:30',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hot Deals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final product = deals[index];
            return _buildDealCard(context, product);
          },
        ),
      ],
    );
  }

  Widget _buildDealCard(BuildContext context, Product product) {
    final discount = (20 + (product.id.hashCode % 40));
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/product', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
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
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                ),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${(product.price * 1.5).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.38,
                              ),
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-$discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEW ARRIVALS TAB ====================
class NewArrivalsTab extends StatelessWidget {
  const NewArrivalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final newProducts = productsProvider.products
        .where((p) => p.isNewArrival == true)
        .toList();

    if (newProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.new_releases_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No new arrivals',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      children: [
        const Text(
          'Just Added',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...newProducts.map((product) => _buildNewArrivalCard(context, product)),
      ],
    );
  }

  Widget _buildNewArrivalCard(BuildContext context, Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/product', extra: product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_shopping_cart,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  context.read<CartProvider>().addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.title} added to cart')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
