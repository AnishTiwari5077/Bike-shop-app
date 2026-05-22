import 'package:bike_shop/providers/auth_provider.dart';
import 'package:bike_shop/providers/cart_provider.dart';
import 'package:bike_shop/providers/favorite_provider.dart';
import 'package:bike_shop/providers/order_provider.dart';
import 'package:bike_shop/providers/payment_provider.dart';
import 'package:bike_shop/screens/address_screen.dart';
import 'package:bike_shop/screens/order_screen.dart';
import 'package:bike_shop/screens/payment_screen.dart';
import 'package:bike_shop/screens/whilist_screen.dart';
import 'package:flutter/material.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isSignedIn) {
        context.read<PaymentProvider>().initialize(
          email: authProvider.email,
          name: authProvider.displayName,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final orders = context.watch<OrdersProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // ── App Bar / Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryBackground,
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
                    // Avatar
                    _buildAvatar(auth),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      auth.isSignedIn ? auth.displayName : 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Email
                    if (auth.isSignedIn)
                      Text(
                        auth.email,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    if (!auth.isSignedIn)
                      const Text(
                        'Sign in to access all features',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Google Sign-In / Sign-Out ────────────────────────────
                  if (!auth.isSignedIn)
                    _buildGoogleSignInButton(auth)
                  else
                    _buildSignedInBadge(auth),

                  const SizedBox(height: 24),

                  // ── Stats ────────────────────────────────────────────────
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
                  const Text(
                    'Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMenuItem(
                    context,
                    icon: Icons.list_alt,
                    title: 'My Orders',
                    subtitle: 'Track your orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_border,
                    title: 'Wishlist',
                    subtitle: 'Your favorite items',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Addresses',
                    subtitle: 'Manage delivery addresses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressesScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    subtitle: 'Manage payment options',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notifications',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and support',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version 1.0.0',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // ── Logout ───────────────────────────────────────────────
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
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
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
            errorBuilder: (_, __, ___) => _defaultAvatar(),
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
        border: Border.all(color: Colors.white, width: 3),
        color: Colors.grey[700],
      ),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
    );
  }

  // ── Google Sign-In Button ─────────────────────────────────────────────────
  Widget _buildGoogleSignInButton(AuthProvider auth) {
    return GestureDetector(
      onTap: () async {
        final success = await auth.signInWithGoogle();
        if (success && mounted) {
          final paymentProvider = context.read<PaymentProvider>();
          paymentProvider.initialize(email: auth.email, name: auth.displayName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${auth.displayName}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled or failed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: auth.isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G logo (colored squares)
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Color(0xFF3C4043),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Signed-in badge ───────────────────────────────────────────────────────
  Widget _buildSignedInBadge(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
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
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog first

              // Reset payment before signing out
              context.read<PaymentProvider>().reset();
              await auth.signOut();

              // Use mounted check + root scaffold messenger
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              }
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

    // Blue (top-left)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s / 2, s / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
    // Red (top-right)
    canvas.drawRect(
      Rect.fromLTWH(s / 2, 0, s / 2, s / 2),
      Paint()..color = const Color(0xFFEA4335),
    );
    // Yellow (bottom-left)
    canvas.drawRect(
      Rect.fromLTWH(0, s / 2, s / 2, s / 2),
      Paint()..color = const Color(0xFFFBBC05),
    );
    // Green (bottom-right)
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2, s / 2, s / 2),
      Paint()..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
