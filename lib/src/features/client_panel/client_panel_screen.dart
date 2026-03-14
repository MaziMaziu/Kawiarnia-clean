import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kawiarnia/src/features/achievements/achievements_screen.dart';
import 'package:kawiarnia/src/features/achievements/leaderboard_screen.dart';
import 'package:kawiarnia/src/features/authentication/login_screen.dart';
import 'package:kawiarnia/src/features/cart/cart_provider.dart';
import 'package:kawiarnia/src/features/cart/cart_screen.dart';
import 'package:kawiarnia/src/features/menu/menu_screen.dart';
import 'package:kawiarnia/src/features/orders/order_history_screen.dart';
import 'package:kawiarnia/src/features/profile/profile_screen.dart';
import 'package:kawiarnia/src/features/subscriptions/my_subscriptions_screen.dart';
import 'package:kawiarnia/src/features/vouchers/vouchers_screen.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class _DashboardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardItem({required this.icon, required this.label, required this.onTap});
}

class ClientPanelScreen extends StatelessWidget {
  const ClientPanelScreen({super.key});

  void _goToMenu(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MenuScreen()));
  }

  void _goToOrderHistory(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
  }

  void _goToVouchers(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const VouchersScreen()));
  }

  void _goToSubscriptions(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MySubscriptionsScreen()));
  }

  void _goToProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  void _goToAchievements(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AchievementsScreen()));
  }

  void _goToLeaderboard(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Provider.of<CartProvider>(context, listen: false).clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<_DashboardItem> dashboardItems = [
      _DashboardItem(icon: Icons.local_cafe_rounded, label: 'Menu', onTap: () => _goToMenu(context)),
      _DashboardItem(icon: Icons.receipt_long_rounded, label: 'Zamówienia', onTap: () => _goToOrderHistory(context)),
      _DashboardItem(icon: Icons.card_membership_rounded, label: 'Subskrypcje', onTap: () => _goToSubscriptions(context)),
      _DashboardItem(icon: Icons.redeem_rounded, label: 'Kupony', onTap: () => _goToVouchers(context)),
      _DashboardItem(icon: Icons.emoji_events_rounded, label: 'Osiągnięcia', onTap: () => _goToAchievements(context)),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe_rounded, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Kawiarnia'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded), 
            tooltip: 'Mój Profil', 
            onPressed: () => _goToProfile(context),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, ch) => badges.Badge(
              badgeContent: Text(
                cart.itemCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              showBadge: cart.itemCount > 0,
              position: badges.BadgePosition.topEnd(top: 0, end: 3),
              badgeStyle: badges.BadgeStyle(
                badgeColor: theme.colorScheme.error,
              ),
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded), 
            tooltip: 'Wyloguj', 
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header z powitaniem
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.05),
                  theme.colorScheme.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Witaj!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Co dzisiaj zamówisz?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Grid z opcjami
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: dashboardItems.length,
              itemBuilder: (context, index) {
                final item = dashboardItems[index];
                return Card(
                  elevation: 3,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surface,
                            theme.colorScheme.secondary.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).scale(begin: const Offset(0.8, 0.8));
              },
            ),
          ),
        ],
      ),
    );
  }
}
