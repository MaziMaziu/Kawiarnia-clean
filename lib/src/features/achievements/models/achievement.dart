import 'package:flutter/material.dart';

/// Typ osiągnięcia
enum AchievementType {
  orders, // Związane z zamówieniami
  variety, // Próbowanie różnych produktów
  time, // Zamówienia o określonych porach
  loyalty, // Długoterminowe korzystanie
  social, // Interakcje społeczne
  special, // Specjalne wydarzenia
}

/// Poziom trudności osiągnięcia
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

/// Model osiągnięcia
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementType type;
  final AchievementTier tier;
  final int targetValue; // Wartość docelowa (np. 10 zamówień)
  final int pointsReward; // Nagroda w punktach
  final Color color;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.tier,
    required this.targetValue,
    required this.pointsReward,
    required this.color,
  });

  factory Achievement.fromMap(String id, Map<String, dynamic> map) {
    return Achievement(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _iconFromString(map['icon'] ?? 'star'),
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.special,
      ),
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      targetValue: map['targetValue'] ?? 1,
      pointsReward: map['pointsReward'] ?? 0,
      color: Color(map['color'] ?? 0xFF6F4E37),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': _iconToString(icon),
      'type': type.name,
      'tier': tier.name,
      'targetValue': targetValue,
      'pointsReward': pointsReward,
      'color': color.value,
    };
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'timer':
        return Icons.access_time_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      case 'sunrise':
        return Icons.wb_sunny_rounded;
      case 'moon':
        return Icons.nightlight_rounded;
      case 'weekend':
        return Icons.weekend_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.local_cafe_rounded) return 'coffee';
    if (icon == Icons.star_rounded) return 'star';
    if (icon == Icons.emoji_events_rounded) return 'trophy';
    if (icon == Icons.local_fire_department_rounded) return 'fire';
    if (icon == Icons.access_time_rounded) return 'timer';
    if (icon == Icons.favorite_rounded) return 'favorite';
    if (icon == Icons.explore_rounded) return 'explore';
    if (icon == Icons.rocket_launch_rounded) return 'rocket';
    if (icon == Icons.diamond_rounded) return 'diamond';
    if (icon == Icons.wb_sunny_rounded) return 'sunrise';
    if (icon == Icons.nightlight_rounded) return 'moon';
    if (icon == Icons.weekend_rounded) return 'weekend';
    if (icon == Icons.calendar_today_rounded) return 'calendar';
    return 'star';
  }
}

/// Progress użytkownika w osiągnięciu
class UserAchievementProgress {
  final String achievementId;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  UserAchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory UserAchievementProgress.fromMap(Map<String, dynamic> map) {
    return UserAchievementProgress(
      achievementId: map['achievementId'] ?? '',
      currentValue: map['currentValue'] ?? 0,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt,
    };
  }

  double getProgress(int targetValue) {
    if (isUnlocked) return 1.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }
}

/// Statystyki użytkownika dla leaderboard
class UserStats {
  final String userId;
  final String email;
  final int totalAchievements;
  final int totalPoints;
  final int bronzeCount;
  final int silverCount;
  final int goldCount;
  final int platinumCount;

  UserStats({
    required this.userId,
    required this.email,
    required this.totalAchievements,
    required this.totalPoints,
    required this.bronzeCount,
    required this.silverCount,
    required this.goldCount,
    required this.platinumCount,
  });

  factory UserStats.fromMap(String userId, Map<String, dynamic> map) {
    return UserStats(
      userId: userId,
      email: map['email'] ?? 'Unknown',
      totalAchievements: map['totalAchievements'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      bronzeCount: map['bronzeCount'] ?? 0,
      silverCount: map['silverCount'] ?? 0,
      goldCount: map['goldCount'] ?? 0,
      platinumCount: map['platinumCount'] ?? 0,
    );
  }
}
