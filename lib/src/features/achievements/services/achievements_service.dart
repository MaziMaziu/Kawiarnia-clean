import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/achievements/models/achievement.dart';
import 'package:kawiarnia/src/features/achievements/widgets/achievement_notification.dart';

/// Serwis zarządzający osiągnięciami
class AchievementsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Predefiniowane osiągnięcia
  static final List<Achievement> predefinedAchievements = [
    // === ZAMÓWIENIA ===
    Achievement(
      id: 'first_order',
      name: 'Pierwsze kroki',
      description: 'Złóż swoje pierwsze zamówienie',
      icon: Icons.local_cafe_rounded,
      type: AchievementType.orders,
      tier: AchievementTier.bronze,
      targetValue: 1,
      pointsReward: 5,
      color: const Color(0xFFCD7F32),
    ),
    Achievement(
      id: 'orders_10',
      name: 'Stały bywalec',
      description: 'Złóż 10 zamówień',
      icon: Icons.emoji_events_rounded,
      type: AchievementType.orders,
      tier: AchievementTier.silver,
      targetValue: 10,
      pointsReward: 10,
      color: const Color(0xFFC0C0C0),
    ),
    Achievement(
      id: 'orders_50',
      name: 'Kawowy mistrz',
      description: 'Złóż 50 zamówień',
      icon: Icons.emoji_events_rounded,
      type: AchievementType.orders,
      tier: AchievementTier.gold,
      targetValue: 50,
      pointsReward: 25,
      color: const Color(0xFFFFD700),
    ),
    Achievement(
      id: 'orders_100',
      name: 'Legenda kawiarni',
      description: 'Złóż 100 zamówień',
      icon: Icons.emoji_events_rounded,
      type: AchievementType.orders,
      tier: AchievementTier.platinum,
      targetValue: 100,
      pointsReward: 50,
      color: const Color(0xFFE5E4E2),
    ),

    // === RÓŻNORODNOŚĆ ===
    Achievement(
      id: 'try_5_products',
      name: 'Eksplorator smaku',
      description: 'Spróbuj 5 różnych produktów',
      icon: Icons.explore_rounded,
      type: AchievementType.variety,
      tier: AchievementTier.bronze,
      targetValue: 5,
      pointsReward: 10,
      color: const Color(0xFFCD7F32),
    ),
    Achievement(
      id: 'try_all_coffees',
      name: 'Kawowy koneser',
      description: 'Spróbuj wszystkich dostępnych kaw',
      icon: Icons.local_cafe_rounded,
      type: AchievementType.variety,
      tier: AchievementTier.gold,
      targetValue: 10, // Zaktualizuj dynamicznie
      pointsReward: 30,
      color: const Color(0xFFFFD700),
    ),

    // === CZAS ZAMÓWIEŃ ===
    Achievement(
      id: 'early_bird',
      name: 'Wczesny ptak',
      description: 'Złóż 5 zamówień przed 8:00 rano',
      icon: Icons.wb_sunny_rounded,
      type: AchievementType.time,
      tier: AchievementTier.silver,
      targetValue: 5,
      pointsReward: 15,
      color: const Color(0xFFC0C0C0),
    ),
    Achievement(
      id: 'night_owl',
      name: 'Nocny marek',
      description: 'Złóż 5 zamówień po 20:00',
      icon: Icons.nightlight_rounded,
      type: AchievementType.time,
      tier: AchievementTier.silver,
      targetValue: 5,
      pointsReward: 15,
      color: const Color(0xFFC0C0C0),
    ),
    Achievement(
      id: 'weekend_warrior',
      name: 'Weekendowy relaks',
      description: 'Złóż 10 zamówień w weekendy',
      icon: Icons.weekend_rounded,
      type: AchievementType.time,
      tier: AchievementTier.gold,
      targetValue: 10,
      pointsReward: 20,
      color: const Color(0xFFFFD700),
    ),

    // === LOJALNOŚĆ ===
    Achievement(
      id: 'subscription_pro',
      name: 'Miłośnik subskrypcji',
      description: 'Kup 3 subskrypcje',
      icon: Icons.card_membership_rounded,
      type: AchievementType.loyalty,
      tier: AchievementTier.silver,
      targetValue: 3,
      pointsReward: 15,
      color: const Color(0xFFC0C0C0),
    ),
    Achievement(
      id: 'points_collector',
      name: 'Kolekcjoner punktów',
      description: 'Zbierz 50 punktów lojalnościowych',
      icon: Icons.star_rounded,
      type: AchievementType.loyalty,
      tier: AchievementTier.gold,
      targetValue: 50,
      pointsReward: 20,
      color: const Color(0xFFFFD700),
    ),
    Achievement(
      id: 'voucher_master',
      name: 'Mistrz bonów',
      description: 'Wymień punkty na 5 bonów',
      icon: Icons.redeem_rounded,
      type: AchievementType.loyalty,
      tier: AchievementTier.gold,
      targetValue: 5,
      pointsReward: 25,
      color: const Color(0xFFFFD700),
    ),

    // === SPECJALNE ===
    Achievement(
      id: 'speed_demon',
      name: 'Demon szybkości',
      description: 'Złóż zamówienie w mniej niż 30 sekund',
      icon: Icons.rocket_launch_rounded,
      type: AchievementType.special,
      tier: AchievementTier.platinum,
      targetValue: 1,
      pointsReward: 30,
      color: const Color(0xFFE5E4E2),
    ),
    Achievement(
      id: 'big_spender',
      name: 'Hojny klient',
      description: 'Złóż zamówienie o wartości powyżej 100 zł',
      icon: Icons.diamond_rounded,
      type: AchievementType.special,
      tier: AchievementTier.gold,
      targetValue: 1,
      pointsReward: 35,
      color: const Color(0xFFFFD700),
    ),
    Achievement(
      id: 'seven_day_streak',
      name: 'Tygodniowa passa',
      description: 'Zamów kawę 7 dni z rzędu',
      icon: Icons.local_fire_department_rounded,
      type: AchievementType.special,
      tier: AchievementTier.platinum,
      targetValue: 7,
      pointsReward: 40,
      color: const Color(0xFFE5E4E2),
    ),
  ];

  /// Sprawdź i zaktualizuj osiągnięcie
  Future<bool> checkAndUpdateAchievement(
    String achievementId,
    int incrementBy,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final achievement = predefinedAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => predefinedAchievements.first,
    );

    final progressRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .doc(achievementId);

    try {
      return await _db.runTransaction((transaction) async {
        final progressDoc = await transaction.get(progressRef);

        int currentValue = 0;
        bool isUnlocked = false;

        if (progressDoc.exists) {
          currentValue = progressDoc.data()?['currentValue'] ?? 0;
          isUnlocked = progressDoc.data()?['isUnlocked'] ?? false;
        }

        // Jeśli już odblokowane, nic nie rób
        if (isUnlocked) return false;

        // Zwiększ wartość
        currentValue += incrementBy;

        // Sprawdź czy osiągnięto cel
        if (currentValue >= achievement.targetValue) {
          isUnlocked = true;

          // Zaktualizuj progress
          transaction.set(progressRef, {
            'achievementId': achievementId,
            'currentValue': currentValue,
            'isUnlocked': true,
            'unlockedAt': FieldValue.serverTimestamp(),
          });

          // Dodaj punkty użytkownikowi
          final userRef = _db.collection('users').doc(user.uid);
          transaction.update(userRef, {
            'points': FieldValue.increment(achievement.pointsReward),
            'totalAchievements': FieldValue.increment(1),
            '${achievement.tier.name}Count': FieldValue.increment(1),
          });

          return true; // Osiągnięcie odblokowane!
        } else {
          // Zaktualizuj tylko progress
          transaction.set(progressRef, {
            'achievementId': achievementId,
            'currentValue': currentValue,
            'isUnlocked': false,
          });
          return false;
        }
      });
    } catch (e) {
      debugPrint('Error updating achievement: $e');
      return false;
    }
  }

  /// Pobierz progress użytkownika dla wszystkich osiągnięć
  Stream<List<UserAchievementProgress>> getUserProgress() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserAchievementProgress.fromMap(doc.data()))
          .toList();
    });
  }

  /// Pobierz statystyki użytkownika
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserStats.fromMap(userId, doc.data()!);
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return null;
    }
  }

  /// Pobierz top użytkowników (leaderboard)
  Stream<List<UserStats>> getLeaderboard({int limit = 50}) {
    return _db
        .collection('users')
        .orderBy('totalAchievements', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserStats.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Inicjalizuj statystyki użytkownika (wywołaj przy rejestracji)
  Future<void> initializeUserStats(String userId) async {
    await _db.collection('users').doc(userId).set({
      'totalAchievements': 0,
      'bronzeCount': 0,
      'silverCount': 0,
      'goldCount': 0,
      'platinumCount': 0,
    }, SetOptions(merge: true));
  }

  /// Sprawdź osiągnięcie i wyświetl powiadomienie jeśli zostało odblokowane
  Future<void> checkAndNotify(
    BuildContext context,
    String achievementId,
    int incrementBy,
  ) async {
    final wasUnlocked = await checkAndUpdateAchievement(achievementId, incrementBy);
    
    if (wasUnlocked && context.mounted) {
      final achievement = predefinedAchievements.firstWhere(
        (a) => a.id == achievementId,
      );
      
      AchievementUnlockedNotification.show(context, achievement);
    }
  }
}
