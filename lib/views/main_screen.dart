import 'package:bike_shop/views/cart_screen.dart';
import 'package:bike_shop/views/explore_screen.dart';
import 'package:bike_shop/views/home_screen.dart';
import 'package:bike_shop/views/profile_screen.dart';
import 'package:bike_shop/views/shared/adaptive_scaffold.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        AdaptiveDestination(icon: Icons.home, label: 'Home'),
        AdaptiveDestination(icon: Icons.explore, label: 'Explore'),
        AdaptiveDestination(icon: Icons.shopping_cart, label: 'Cart'),
        AdaptiveDestination(icon: Icons.person, label: 'Profile'),
      ],
      body: _screens[_currentIndex],
    );
  }
}
