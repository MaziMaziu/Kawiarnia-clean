import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Punkty i Bony')),
      body: userId == null
          ? const Center(child: Text('Musisz być zalogowany, aby zobaczyć tę sekcję.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Nie znaleziono danych użytkownika.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final points = userData['points'] as int? ?? 0;
                final vouchers = userData['vouchers'] as int? ?? 0;

                // Co 10 punktów jest 1 bon
                final progress = points % 10 / 10.0;

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Twoje Bony', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_giftcard, size: 40, color: Colors.amber),
                          const SizedBox(width: 16),
                          Text('$vouchers', style: Theme.of(context).textTheme.displaySmall),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Text('Twoje Punkty', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                       Text('Zebrałeś $points z 10 punktów do następnego bonu', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
