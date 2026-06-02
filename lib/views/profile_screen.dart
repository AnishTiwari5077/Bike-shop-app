import 'package:bike_shop/viewmodels/auth_viewmodel.dart';
import 'package:bike_shop/viewmodels/cart_viewmodel.dart';
import 'package:bike_shop/viewmodels/favorites_viewmodel.dart';
import 'package:bike_shop/viewmodels/order_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/config/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bike_shop/viewmodels/theme_viewmodel.dart';

// Settings screens migrated to separate files inside views/settings/

// ============================================================================
// Main Profile Screen
// ============================================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesViewModel>();
    final orders = context.watch<OrdersProvider>();
    final auth = context.watch<AuthProvider>();
    final themeVM = context.watch<ThemeViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              // ── App Bar / Header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C3448), Color(0xFF0C1C2D)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        _buildAvatar(auth),
                        const SizedBox(height: 12),
                        Text(
                          auth.isSignedIn ? auth.displayName : 'Guest',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 22 * Responsive.fontScale(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (auth.isSignedIn)
                          Text(
                            auth.email,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        if (!auth.isSignedIn)
                          Text(
                            'Sign in to access all features',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.54,
                              ),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding(context),
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Google Sign-In / Sign-Out ─────────────────────────
                      if (!auth.isSignedIn)
                        _buildGoogleSignInButton(auth)
                      else
                        _buildSignedInBadge(auth),

                      const SizedBox(height: 24),

                      // ── Stats ─────────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_bag,
                              label: 'Orders',
                              value: orders.orders.length.toString(),
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite,
                              label: 'Wishlist',
                              value: favorites.favoriteCount.toString(),
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_cart,
                              label: 'Cart',
                              value: cart.uniqueItemCount.toString(),
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Account',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18 * Responsive.fontScale(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildMenuItem(
                        context,
                        icon: Icons.list_alt,
                        title: 'My Orders',
                        subtitle: 'Track your orders',
                        onTap: () => context.push('/orders'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.favorite_border,
                        title: 'Wishlist',
                        subtitle: 'Your favorite items',
                        onTap: () => context.push('/wishlist'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'Addresses',
                        subtitle: 'Manage delivery addresses',
                        onTap: () => context.push('/addresses'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.payment,
                        title: 'Payment Methods',
                        subtitle: 'Manage payment options',
                        onTap: () => context.push('/payment'),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18 * Responsive.fontScale(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Appearance tile
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          // FIX Issue 1: explicit splash/highlight so ink is visible
                          // on the card background, not invisible on transparent.
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                themeVM.isDark
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: AppTheme.accentBlue,
                              ),
                            ),
                            title: Text(
                              'Appearance',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              switch (themeVM.themeMode) {
                                ThemeMode.dark => 'Dark',
                                ThemeMode.light => 'Light',
                                ThemeMode.system => 'System',
                              },
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.54,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            trailing: DropdownButton<ThemeMode>(
                              value: themeVM.themeMode,
                              underline: const SizedBox(),
                              dropdownColor: Theme.of(context).cardColor,
                              style: TextStyle(color: colorScheme.onSurface),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.54,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(
                                    'Dark',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(
                                    'Light',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(
                                    'System',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (mode) {
                                if (mode != null) {
                                  themeVM.setThemeMode(mode);
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage notifications',
                        onTap: () => context.push('/settings/notifications'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Manage your privacy',
                        onTap: () => context.push('/settings/privacy'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help and support',
                        onTap: () => context.push('/settings/support'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'App version 1.0.0',
                        onTap: () => context.push('/settings/about'),
                      ),

                      const SizedBox(height: 24),

                      // ── Logout ───────────────────────────────────────────
                      if (auth.isSignedIn)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showLogoutDialog(context, auth),
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 100),
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

  Widget _buildAvatar(AuthProvider auth) {
    if (auth.isSignedIn && auth.photoUrl.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ClipOval(
          child: Image.network(
            auth.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
          ),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: 3,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildGoogleSignInButton(AuthProvider auth) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4285F4), // Google Blue
              Color(0xFF34A853), // Green
              Color(0xFFFBBC05), // Yellow
              Color(0xFFEA4335), // Red
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: auth.isLoading
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);

                  final success = await auth.signInWithGoogle();

                  if (!mounted) return;

                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Welcome, ${auth.displayName}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Sign-in cancelled or failed'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: auth.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Text(
                              "G",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInBadge(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signed in with Google',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  auth.email,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20 * Responsive.fontScale(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // FIX Issue 1: use cardColor so ListTile ink splashes are visible (not
    // transparent), matching the container background.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentBlue),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.54),
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onSurface.withValues(alpha: 0.54),
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // FIX Issue 5: capture messenger before async gap so
              // BuildContext is not used across an async boundary.
              final messenger = ScaffoldMessenger.of(context);
              await auth.signOut();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ── Google Logo Widget ────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s / 2, s / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawRect(
      Rect.fromLTWH(s / 2, 0, s / 2, s / 2),
      Paint()..color = const Color(0xFFEA4335),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, s / 2, s / 2, s / 2),
      Paint()..color = const Color(0xFFFBBC05),
    );
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2, s / 2, s / 2),
      Paint()..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
