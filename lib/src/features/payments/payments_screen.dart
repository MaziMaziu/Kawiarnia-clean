import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyUnpaid = true; // Domyślnie pokazuj nieopłacone

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSearchDialog() async {
    final searchController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 48),
        title: const Text('Wyszukaj zamówienie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wpisz numer zamówienia podany przez klienta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'np. A3B5C7D9',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = searchController.text.trim().toUpperCase();
                _showOnlyUnpaid = false;
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.search),
            label: const Text('Szukaj'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> _confirmPayment(String orderId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.payment, color: Colors.green, size: 48),
        title: const Text('Potwierdź płatność'),
        content: Text(
          'Czy klient zapłacił kwotę ${amount.toStringAsFixed(2)} zł gotówką?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check),
            label: const Text('Potwierdzam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'isPaid': true,
        'paidAt': Timestamp.now(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Płatność potwierdzona ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
            Icon(Icons.payment, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Płatności'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
            tooltip: 'Szukaj po numerze zamówienia',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searchQuery.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wyszukuję: $_searchQuery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _showOnlyUnpaid = true;
                            });
                          },
                          tooltip: 'Wyczyść',
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showOnlyUnpaid = !_showOnlyUnpaid;
                      if (_showOnlyUnpaid) _searchQuery = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _showOnlyUnpaid ? Colors.orange.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showOnlyUnpaid ? Colors.orange : theme.colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: _showOnlyUnpaid ? Colors.orange.shade700 : theme.colorScheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _showOnlyUnpaid ? '💰 Pokazuję tylko NIEOPŁACONE' : 'Pokaż tylko nieopłacone zamówienia',
                            style: TextStyle(
                              fontWeight: _showOnlyUnpaid ? FontWeight.bold : FontWeight.normal,
                              color: _showOnlyUnpaid ? Colors.orange.shade700 : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_showOnlyUnpaid)
                          Icon(Icons.check_circle, color: Colors.orange.shade700, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Wystąpił błąd ładowania zamówień.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Wszystkie zamówienia opłacone! 🎉',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                var orders = snapshot.data!.docs;
                
                // Filtrowanie po statusie płatności
                if (_showOnlyUnpaid) {
                  orders = orders.where((order) {
                    final orderData = order.data() as Map<String, dynamic>;
                    return orderData['isPaid'] != true;
                  }).toList();
                }
                
                // Filtrowanie po numerze zamówienia
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((order) {
                    final orderNumber = order.id.substring(0, 8).toUpperCase();
                    return orderNumber.contains(_searchQuery);
                  }).toList();
                }

                if (orders.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Nie znaleziono zamówienia\n"$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _showOnlyUnpaid = true;
                            });
                          },
                          icon: Icon(Icons.clear),
                          label: Text('Wyczyść wyszukiwanie'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    final orderNumber = order.id.substring(0, 8).toUpperCase();
                    final totalPrice = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;
                    final isPaid = orderData['isPaid'] == true;
                    final createdAt = (orderData['createdAt'] as Timestamp).toDate();
                    final tableNumber = orderData['tableNumber'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    orderNumber,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${totalPrice.toStringAsFixed(2)} zł',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      if (tableNumber != null)
                                        Text(
                                          '📍 Stolik: $tableNumber',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isPaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          'OPŁACONE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Złożono: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmPayment(order.id, totalPrice),
                                  icon: const Icon(Icons.check_circle, size: 24),
                                  label: Text(
                                    'POTWIERDŹ PŁATNOŚĆ ${totalPrice.toStringAsFixed(2)} ZŁ',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
