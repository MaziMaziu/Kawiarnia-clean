import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  
  bool _isLoading = true;
  // DODANY NOWY KLUCZ DO MAPY PREFERENCJI
  Map<String, bool> _preferences = {
    'prefersLactoseFreeMilk': false,
    'prefersOatMilk': false,
    'prefersSyrup': false,
    'prefersNoSugar': false, 
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_userId == null) return;
    try {
      final doc = await _db.collection('users').doc(_userId).get();
      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() {
          // DODANA OBSŁUGA NOWEGO POLA
          _preferences['prefersLactoseFreeMilk'] = data?['prefersLactoseFreeMilk'] ?? false;
          _preferences['prefersOatMilk'] = data?['prefersOatMilk'] ?? false;
          _preferences['prefersSyrup'] = data?['prefersSyrup'] ?? false;
          _preferences['prefersNoSugar'] = data?['prefersNoSugar'] ?? false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    if (_userId == null) return;
    setState(() {
      _preferences[key] = value;
    });
    await _db.collection('users').doc(_userId).set({
      key: value,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Moje Preferencje'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Statystyki użytkownika
                _buildStatisticsSection(context),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Dostosuj swoje ulubione ustawienia kawy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPreferenceCard(
                  context,
                  title: 'Preferuję mleko bez laktozy',
                  icon: Icons.favorite_rounded,
                  value: _preferences['prefersLactoseFreeMilk']!,
                  onChanged: (val) => _updatePreference('prefersLactoseFreeMilk', val),
                ),
                _buildPreferenceCard(
                  context,
                  title: 'Preferuję mleko owsiane',
                  icon: Icons.eco_rounded,
                  value: _preferences['prefersOatMilk']!,
                  onChanged: (val) => _updatePreference('prefersOatMilk', val),
                ),
                _buildPreferenceCard(
                  context,
                  title: 'Preferuję słodki syrop',
                  icon: Icons.water_drop_rounded,
                  value: _preferences['prefersSyrup']!,
                  onChanged: (val) => _updatePreference('prefersSyrup', val),
                ),
                _buildPreferenceCard(
                  context,
                  title: 'Nie słodzę',
                  icon: Icons.block_rounded,
                  value: _preferences['prefersNoSugar']!,
                  onChanged: (val) => _updatePreference('prefersNoSugar', val),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('orders').where('userId', isEqualTo: _userId).snapshots(),
      builder: (context, ordersSnapshot) {
        if (!ordersSnapshot.hasData) {
          return const SizedBox();
        }

        final orders = ordersSnapshot.data!.docs;
        final totalOrders = orders.length;
        final totalSpent = orders.fold<double>(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + ((data['totalPrice'] as num?)?.toDouble() ?? 0.0);
        });

        // Znajdź najczęściej zamawiany produkt
        Map<String, int> productCounts = {};
        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final products = data['products'] as List<dynamic>? ?? [];
          for (var product in products) {
            final name = product['name'] as String? ?? '';
            productCounts[name] = (productCounts[name] ?? 0) + (product['quantity'] as int? ?? 1);
          }
        }
        
        String favoriteProduct = 'Brak';
        if (productCounts.isNotEmpty) {
          favoriteProduct = productCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Twoje Statystyki',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: 'Zamówienia',
                    value: totalOrders.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.attach_money_rounded,
                    label: 'Wydane',
                    value: '${totalSpent.toStringAsFixed(0)} zł',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.favorite_rounded,
              label: 'Ulubiony produkt',
              value: favoriteProduct,
              color: Colors.red,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: fullWidth ? TextAlign.start : TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}
