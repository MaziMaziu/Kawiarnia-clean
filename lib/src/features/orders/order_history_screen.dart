import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Błąd: Użytkownik nie jest zalogowany.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historia Twoich Zamówień')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Wystąpił błąd ładowania zamówień.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nie masz jeszcze żadnych zamówień.', textAlign: TextAlign.center),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final status = orderData['status'] as String? ?? 'Brak statusu';
              final createdAt = (orderData['createdAt'] as Timestamp).toDate();
              final totalPrice = (orderData['totalPrice'] as num).toDouble();
              final products = orderData['products'] as List<dynamic>? ?? [];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text('Zamówienie z ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}'),
                  subtitle: Text('Suma: ${totalPrice.toStringAsFixed(2)} zł'),
                  trailing: Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    side: BorderSide.none,
                  ),
                  children: products.map((product) {
                    final p = product as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.coffee_outlined, size: 20),
                      title: Text(p['name'] ?? 'Brak nazwy'),
                      trailing: Text('x ${p['quantity']}'),
                      dense: true,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
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
}
