// lib/widgets/search_model.dart
// FIXES:
//   - Driven fully by ProductsProvider (ProductViewModel)
//   - Local state and debouncing removed
//   - Recent searches populated from SharedPreferences via ProductsProvider

import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/models/product_model.dart';
import 'package:bike_shop/viewmodels/product_viewmodel.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Synchronise text controller with any existing query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductsProvider>();
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Reset search query on close so home screen product grid is not filtered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductsProvider>().setSearchQuery('');
      }
    });
    super.dispose();
  }

  void _performSearch(String query, ProductsProvider provider) {
    provider.setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search field row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search bikes, helmets, accessories...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('', productsProvider);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) =>
                        _performSearch(value, productsProvider),
                    onSubmitted: (value) {
                      productsProvider.addRecentSearch(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    productsProvider.setSearchQuery('');
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

          Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            height: 1,
          ),

          Expanded(child: _buildSearchContent(context, productsProvider)),
        ],
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, ProductsProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentBlue),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildRecentSearches(context, provider);
    }

    final results = provider.displayedProducts;

    if (results.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _buildSearchResultItem(context, results[index], provider),
    );
  }

  Widget _buildRecentSearches(BuildContext context, ProductsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentSearches = provider.recentSearches;

    if (recentSearches.isEmpty) {
      return Center(
        child: Text(
          'Type to search for products',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.38),
            fontSize: 15,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18 * Responsive.fontScale(context),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => provider.clearRecentSearches(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final term = recentSearches[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: colorScheme.onSurface.withValues(alpha: 0.54),
                ),
                title: Text(
                  term,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => provider.removeRecentSearch(term),
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    Icon(
                      Icons.north_west,
                      color: colorScheme.onSurface.withValues(alpha: 0.54),
                      size: 20,
                    ),
                  ],
                ),
                onTap: () {
                  _searchController.text = term;
                  _performSearch(term, provider);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    Product product,
    ProductsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        provider.addRecentSearch(product.title);
        Navigator.pop(context);
        context.push('/product', extra: product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 18 * Responsive.fontScale(context),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
    );
  }
}

void showSearchModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SearchModal(),
  );
}
