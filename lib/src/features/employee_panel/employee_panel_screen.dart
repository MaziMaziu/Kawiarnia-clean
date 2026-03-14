import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // DODANY IMPORT
import 'package:kawiarnia/src/features/authentication/login_screen.dart';
import 'package:kawiarnia/src/features/orders/orders_screen.dart';
import 'package:kawiarnia/src/features/payments/payments_screen.dart';
import 'package:kawiarnia/src/features/promotions/promotions_screen.dart';
import 'package:kawiarnia/src/features/statistics/statistics_screen.dart';

class _DashboardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardItem({required this.icon, required this.label, required this.onTap});
}

class EmployeePanelScreen extends StatelessWidget {
  const EmployeePanelScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
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
      _DashboardItem(
        icon: Icons.receipt_long_rounded,
        label: 'Zamówienia',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OrdersScreen())),
      ),
      _DashboardItem(
        icon: Icons.payment,
        label: 'Płatności',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PaymentsScreen())),
      ),
      _DashboardItem(
        icon: Icons.analytics_rounded,
        label: 'Statystyki',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StatisticsScreen())),
      ),
      _DashboardItem(
        icon: Icons.local_offer_rounded,
        label: 'Promocje',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PromotionsScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_rounded, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Panel Pracownika'),
          ],
        ),
        actions: [
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
          // Header
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
                  'Panel Zarządzania',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zarządzaj kawiarnią',
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
                childAspectRatio: 1.0,
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
