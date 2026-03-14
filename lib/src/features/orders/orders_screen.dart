import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String? _selectedStatusFilter = 'Oczekujące';

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (_selectedStatusFilter != null) {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }
    
    return query.snapshots();
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
            Icon(Icons.receipt_long_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Zamówienia'),
          ],
        ),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'Wszystkie'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Oczekujące', 'Oczekujące'),
                  const SizedBox(width: 8),
                  _buildFilterChip('W trakcie', 'W trakcie'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Gotowe', 'Gotowe'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Wydane', 'Wydane'),
                ],
              ),
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
                   if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
                     return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Błąd bazy danych. Firebase wymaga utworzenia nowego indeksu dla tego filtra.\n\nSprawdź konsolę `Run` w Android Studio, skopiuj z niej link i otwórz go w przeglądarce, aby utworzyć indeks.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const Center(child: Text('Wystąpił błąd ładowania zamówień.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Brak zamówień o statusie: "${_selectedStatusFilter ?? 'Wszystkie'}"'));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    final status = orderData['status'] as String? ?? 'Brak statusu';
                    final createdAt = (orderData['createdAt'] as Timestamp).toDate();
                    final userEmail = orderData['userEmail'] as String? ?? 'Anonim';

                    final orderNumber = order.id.substring(0, 8).toUpperCase();
                    final totalPrice = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(height: 2),
                              Text(
                                orderNumber,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '${totalPrice.toStringAsFixed(2)} zł',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Złożono: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}'),
                            if (orderData['tableNumber'] != null && orderData['tableNumber'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.table_bar, size: 16, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stolik: ${orderData['tableNumber']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: _getStatusColor(status).withOpacity(0.2),
                          side: BorderSide.none,
                        ),
                        children: [_buildOrderDetails(orderData, order.id, orderNumber)],
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

  Widget _buildOrderDetails(Map<String, dynamic> orderData, String orderId, String orderNumber) {
    final products = orderData['products'] as List<dynamic>? ?? [];
    final status = orderData['status'] as String? ?? 'Brak statusu';
    final totalPrice = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final tableNumber = orderData['tableNumber'] as String?;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'NUMER ZAMÓWIENIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderNumber,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 4,
                  ),
                ),
                if (tableNumber != null && tableNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_bar,
                          color: theme.colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'STOLIK: $tableNumber',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Do zapłaty: ${totalPrice.toStringAsFixed(2)} zł',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Produkty:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          ...products.map((product) {
            final p = product as Map<String, dynamic>;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.coffee_outlined, size: 20, color: Colors.brown),
              title: Text('${p['name'] ?? 'Brak nazwy'} (x${p['quantity']})'),
            );
          }).toList(),
          
          _buildPreferencesWidget(orderData),
          
          const Divider(height: 24),
          
          const Text('Zmień status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'Oczekujące', label: Text('Oczekuje'), icon: Icon(Icons.hourglass_empty)),
                ButtonSegment<String>(value: 'W trakcie', label: Text('W trakcie'), icon: Icon(Icons.construction)),
                ButtonSegment<String>(value: 'Gotowe', label: Text('Gotowe'), icon: Icon(Icons.check_circle_outline)),
                ButtonSegment<String>(value: 'Wydane', label: Text('Wydane'), icon: Icon(Icons.delivery_dining)),
              ],
              selected: <String>{status},
              onSelectionChanged: (Set<String> newSelection) {
                  _updateOrderStatus(orderId, newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesWidget(Map<String, dynamic> orderData) {
    final preferences = <String, String>{};
    if (orderData['lactoseFree'] == true) preferences['Mleko bez laktozy'] = '🥛';
    if (orderData['oatMilk'] == true) preferences['Mleko owsiane'] = '🌾';
    if (orderData['withSyrup'] == true) preferences['Słodki syrop'] = '🍯';
    if (orderData['noSugar'] == true) preferences['Bez cukru'] = '🚫';

    if (preferences.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferencje:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: preferences.entries.map((entry) {
              return Chip(
                avatar: Text(entry.value, style: const TextStyle(fontSize: 16)),
                label: Text(entry.key),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.brown.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'W trakcie': return Colors.orange.shade700;
      case 'Gotowe': return Colors.green.shade700;
      case 'Wydane': return Colors.blueGrey.shade700;
      case 'Oczekujące': return Colors.blue.shade700;
      default: return Colors.grey;
    }
  }

  Widget _buildFilterChip(String? status, String label) {
    final isSelected = _selectedStatusFilter == status;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      avatar: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
