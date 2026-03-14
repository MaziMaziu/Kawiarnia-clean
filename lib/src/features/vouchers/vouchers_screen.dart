import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  bool _isRedeeming = false;

  Future<void> _redeemVoucher(int currentPoints) async {
    if (currentPoints < 10) return;
    setState(() => _isRedeeming = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Odejmij punkty
        transaction.update(userRef, {'points': FieldValue.increment(-10)});
        // 2. Stwórz nowy dokument w kolekcji 'vouchers'
        final voucherRef = FirebaseFirestore.instance.collection('vouchers').doc();
        transaction.set(voucherRef, {
          'userId': user.uid,
          'userEmail': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'aktywny', // Możliwe statusy: aktywny, wykorzystany
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wygenerowano bon na darmową kawę!')));
        
        // Sprawdź osiągnięcia związane z kuponami
        final achievementsService = AchievementsService();
        await achievementsService.checkAndNotify(context, 'voucher_master', 1);
        await achievementsService.checkAndNotify(context, 'points_collector', 10);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wystąpił błąd. Spróbuj ponownie.')));
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
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
            Icon(Icons.redeem_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Kupony i Punkty'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sekcja z punktami
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));

              final points = (snapshot.data?.data() as Map<String, dynamic>?)?['points'] as int? ?? 0;
              final progress = points / 10.0;

              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 3,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.tertiary.withOpacity(0.15),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.stars_rounded,
                              size: 32,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Twoje punkty',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '$points / 10',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zbierz 10 punktów, aby wymienić je na bon',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_isRedeeming)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.redeem_rounded),
                          label: const Text('Wymień na bon'),
                          onPressed: (points < 10 || _isRedeeming) ? null : () => _redeemVoucher(points),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Sekcja z kuponami
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Twoje aktywne kupony',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vouchers')
                  .where('userId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'aktywny')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Brak aktywnych kuponów.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
                    return Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.onSecondaryContainer),
                        title: const Text('Bon na darmową kawę'),
                        subtitle: Text(createdAt != null ? 'Ważny od: ${DateFormat('dd.MM.yyyy').format(createdAt)}' : 'Brak daty'),
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
