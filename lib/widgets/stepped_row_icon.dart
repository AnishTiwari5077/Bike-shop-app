import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/viewmodels/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SteppedIconRow extends StatefulWidget {
  const SteppedIconRow({super.key});

  @override
  State<SteppedIconRow> createState() => _SteppedIconRowState();
}

class _SteppedIconRowState extends State<SteppedIconRow> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'label': 'All',
      'icon': Icons.grid_view_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'id': 'bike',
      'label': 'Bikes',
      'icon': Icons.directions_bike,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'electric',
      'label': 'Electric',
      'icon': Icons.electric_bike,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'mountain',
      'label': 'Mountain',
      'icon': Icons.pedal_bike,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'road',
      'label': 'Road',
      'icon': Icons.two_wheeler,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'accessories',
      'label': 'Gear',
      'icon': Icons.settings,
      'color': const Color(0xFFEC4899),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.value(context, mobile: 110.0, tablet: 120.0, desktop: 130.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category['id']);
                context.read<ProductsProvider>().setCategory(category['id']);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: Responsive.value(context, mobile: 70.0, tablet: 80.0, desktop: 90.0),
                    width: Responsive.value(context, mobile: 70.0, tablet: 80.0, desktop: 90.0),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                category['color'] as Color,
                                (category['color'] as Color).withValues(alpha: .7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (category['color'] as Color).withValues(alpha: .5)
                            : Colors.white.withValues(alpha: .1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (category['color'] as Color).withValues(alpha: 
                                  0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          category['icon'] as IconData,
                          size: Responsive.value(context, mobile: 32.0, tablet: 36.0, desktop: 40.0),
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: isSelected ? 13 : 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    child: Text(category['label'] as String),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
