import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MySubscriptionsScreen extends StatelessWidget {
  const MySubscriptionsScreen({super.key});

  Future<String> _getProductName(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      return doc.data()?['name'] ?? 'Nieznany produkt';
    } catch (e) {
      return 'Błąd ładowania nazwy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_membership_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Twoje Subskrypcje'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: theme.colorScheme.error.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Nie można załadować danych',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final subscriptions = userData['subscriptions'] as Map<String, dynamic>? ?? {};

          if (subscriptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_membership_outlined,
                      size: 100,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Brak aktywnych subskrypcji',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Możesz je kupić w menu, szukając ikony subskrypcji przy ulubionej kawie',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Sortowanie, aby subskrypcje z większą liczbą kaw były wyżej
          final sortedSubscriptions = subscriptions.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedSubscriptions.length,
            itemBuilder: (context, index) {
              final entry = sortedSubscriptions[index];
              final productId = entry.key;
              final remaining = entry.value as int;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.secondary.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_cafe_rounded,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getProductName(productId),
                          builder: (context, nameSnapshot) {
                            if (nameSnapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameSnapshot.data ?? 'Brak nazwy',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subskrypcja aktywna',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              remaining.toString(),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            Text(
                              'pozostało',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
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
