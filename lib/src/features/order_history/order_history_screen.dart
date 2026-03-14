import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia Zamówień'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Wystąpił błąd podczas ładowania historii zamówień.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Brak historii zamówień.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              var totalPrice = (order['totalPrice'] as num).toDouble();
              var createdAt = (order['createdAt'] as Timestamp).toDate();
              var status = order['status'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                      'Zamówienie z ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}'),
                  subtitle: Text(
                      'Suma: ${totalPrice.toStringAsFixed(2)} zł | Status: $status'),
                  children: <Widget>[
                    ...(order['products'] as List<dynamic>).map((product) {
                      return ListTile(
                        title: Text(product['name'] ?? 'Brak nazwy'),
                        trailing: Text('Ilość: ${product['quantity']}'),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
