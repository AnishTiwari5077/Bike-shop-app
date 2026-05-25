import 'package:flutter/material.dart';
import 'package:bike_shop/config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bike_scooter,
              size: 80,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Bike Shop App',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 Bike Shop',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
