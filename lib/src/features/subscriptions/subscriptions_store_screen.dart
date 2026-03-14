import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';

// 1. PRZEBUDOWA NA STATEFULWIDGET
class SubscriptionsStoreScreen extends StatefulWidget {
  const SubscriptionsStoreScreen({super.key});

  @override
  State<SubscriptionsStoreScreen> createState() => _SubscriptionsStoreScreenState();
}

class _SubscriptionsStoreScreenState extends State<SubscriptionsStoreScreen> {

  // 2. MODYFIKACJA LOGIKI ZAKUPU (TERAZ PRZYJMUJE ARGUMENTY)
  Future<void> _buySubscription(BuildContext context, String productId, String productName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musisz być zalogowany, aby kupić subskrypcję.')),
      );
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          userRef,
          {
            'subscriptions': {
              productId: FieldValue.increment(5),
            }
          },
          SetOptions(merge: true),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kupiono subskrypcję na 5x $productName!')),
        );

        // Sprawdź osiągnięcie "Mistrz subskrypcji"
        final achievementsService = AchievementsService();
        await achievementsService.checkAndNotify(context, 'subscription_pro', 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wystąpił błąd podczas zakupu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kup Subskrypcję'),
      ),
      // 3. ZASTĄPIENIE STATYCZNEGO WIDOKU DYNAMICZNĄ LISTĄ
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isCoffee', isEqualTo: true)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Brak kaw dostępnych w subskrypcji.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId = product.id;
              final productData = product.data() as Map<String, dynamic>;
              final name = productData['name'] ?? 'Brak nazwy';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.local_cafe, color: Colors.brown),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Subskrypcja na 5 kaw'),
                  trailing: ElevatedButton(
                    child: const Text('Kup'),
                    onPressed: () => _buySubscription(context, productId, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
