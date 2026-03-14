import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isBuying = false;

  // Metoda do "zakupu" subskrypcji
  Future<void> _buySubscription() async {
    setState(() {
      _isBuying = true;
    });

    final user = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      // Dodajemy 10 kaw do konta użytkownika
      await userRef.update({'coffeesRemaining': FieldValue.increment(10)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dziękujemy! 10 kaw zostało dodanych do Twojego konta.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wystąpił błąd. Spróbuj ponownie.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoja Subskrypcja'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Nie można załadować danych o subskrypcji.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final coffeesRemaining = (userData['coffeesRemaining'] as num?)?.toInt() ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Pozostało kaw w subskrypcji', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(coffeesRemaining.toString(), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isBuying)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _buySubscription,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Kup subskrypcję na 10 kaw'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
