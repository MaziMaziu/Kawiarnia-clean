import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  // ROZBUDOWANY STAN WIDOKU
  int _dailyOrderCount = 0;
  double _totalRevenueToday = 0.0;
  String _mostPopularProduct = '-';
  Map<String, int> _preferencesCount = {};

  @override
  void initState() {
    super.initState();
    _fetchDailyStats();
  }

  // ROZSZERZONA LOGIKA OBLICZENIOWA
  Future<void> _fetchDailyStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final query = FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startOfToday);

      final snapshot = await query.get();
      final orders = snapshot.docs;

      // Resetowanie statystyk
      double totalRevenue = 0;
      Map<String, int> productCounts = {};
      Map<String, int> prefsCount = {
        'Mleko bez laktozy': 0,
        'Mleko owsiane': 0,
        'Słodki syrop': 0,
        'Bez cukru': 0,
      };

      for (var order in orders) {
        final data = order.data();
        totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

        if (data['products'] is List) {
          for (var product in (data['products'] as List)) {
            final name = product['name'] as String?;
            if (name != null) {
              productCounts.update(name, (value) => value + 1, ifAbsent: () => 1);
            }
          }
        }

        if (data['lactoseFree'] == true) prefsCount.update('Mleko bez laktozy', (v) => v + 1);
        if (data['oatMilk'] == true) prefsCount.update('Mleko owsiane', (v) => v + 1);
        if (data['withSyrup'] == true) prefsCount.update('Słodki syrop', (v) => v + 1);
        if (data['noSugar'] == true) prefsCount.update('Bez cukru', (v) => v + 1);
      }

      String popularProduct = '-';
      if (productCounts.isNotEmpty) {
        popularProduct = productCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      if (mounted) {
        setState(() {
          _dailyOrderCount = orders.length;
          _totalRevenueToday = totalRevenue;
          _mostPopularProduct = popularProduct;
          _preferencesCount = prefsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania statystyk: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pl_PL', symbol: 'zł');
    final sortedPreferences = _preferencesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki Dnia'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDailyStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // DODANE NOWE WIDŻETY STATYSTYK
                  _buildStatCard(
                    icon: Icons.receipt_long,
                    title: 'Liczba zamówień',
                    value: _dailyOrderCount.toString(),
                  ),
                  _buildStatCard(
                    icon: Icons.attach_money,
                    title: 'Przychód',
                    value: currencyFormat.format(_totalRevenueToday),
                  ),
                  _buildStatCard(
                    icon: Icons.local_cafe,
                    title: 'Najpopularniejszy produkt',
                    value: _mostPopularProduct,
                    isSmall: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Preferencje klientów', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...sortedPreferences.map((pref) => ListTile(
                        title: Text(pref.key),
                        trailing: Text(pref.value.toString(), style: Theme.of(context).textTheme.titleLarge),
                      )),
                ],
              ),
      ),
    );
  }

  // Funkcja pomocnicza do budowania kart statystyk
  Widget _buildStatCard({required IconData icon, required String title, required String value, bool isSmall = false}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: isSmall ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
