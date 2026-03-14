import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kawiarnia/src/features/achievements/models/achievement.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final service = AchievementsService();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Ranking'),
          ],
        ),
      ),
      body: StreamBuilder<List<UserStats>>(
        stream: service.getLeaderboard(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    size: 100,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ranking jest pusty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final leaderboard = snapshot.data!;
          final currentUserIndex = leaderboard.indexWhere(
            (u) => u.userId == currentUser?.uid,
          );

          return Column(
            children: [
              // Top 3 podium
              if (leaderboard.length >= 3) _buildPodium(theme, leaderboard),
              
              // Pozostali użytkownicy
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboard.length > 3 ? leaderboard.length - 3 : 0,
                  itemBuilder: (context, index) {
                    final rank = index + 4; // 4, 5, 6...
                    final user = leaderboard[index + 3];
                    final isCurrentUser = user.userId == currentUser?.uid;

                    return _LeaderboardCard(
                      rank: rank,
                      user: user,
                      isCurrentUser: isCurrentUser,
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                ),
              ),

              // Panel z pozycją bieżącego użytkownika
              if (currentUserIndex >= 3)
                _buildCurrentUserPanel(theme, currentUserIndex + 1, leaderboard[currentUserIndex]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(ThemeData theme, List<UserStats> leaderboard) {
    final first = leaderboard[0];
    final second = leaderboard.length > 1 ? leaderboard[1] : null;
    final third = leaderboard.length > 2 ? leaderboard[2] : null;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.tertiary.withOpacity(0.2),
            theme.colorScheme.background,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (second != null)
            _PodiumPosition(
              rank: 2,
              user: second,
              height: 100,
              color: const Color(0xFFC0C0C0),
              isCurrentUser: second.userId == currentUserId,
            ),
          const SizedBox(width: 8),
          // 1st place
          _PodiumPosition(
            rank: 1,
            user: first,
            height: 140,
            color: const Color(0xFFFFD700),
            isCurrentUser: first.userId == currentUserId,
          ),
          const SizedBox(width: 8),
          // 3rd place
          if (third != null)
            _PodiumPosition(
              rank: 3,
              user: third,
              height: 80,
              color: const Color(0xFFCD7F32),
              isCurrentUser: third.userId == currentUserId,
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserPanel(ThemeData theme, int rank, UserStats user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twoja pozycja',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  user.email,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${user.totalAchievements}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPosition extends StatelessWidget {
  final int rank;
  final UserStats user;
  final double height;
  final Color color;
  final bool isCurrentUser;

  const _PodiumPosition({
    required this.rank,
    required this.user,
    required this.height,
    required this.color,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Crown for 1st place
        if (rank == 1)
          Icon(
            Icons.emoji_events_rounded,
            color: color,
            size: 40,
          ).animate().scale(duration: 500.ms).shake(),
        const SizedBox(height: 8),
        
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser ? theme.colorScheme.primary : color,
              width: 3,
            ),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Text(
              user.email.substring(0, 1).toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Email (skrócony)
        SizedBox(
          width: 80,
          child: Text(
            user.email.split('@')[0],
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        
        // Achievements count
        Text(
          '${user.totalAchievements}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'osiągnięć',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        
        // Podium base
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final UserStats user;
  final bool isCurrentUser;

  const _LeaderboardCard({
    required this.rank,
    required this.user,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isCurrentUser ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser ? theme.colorScheme.primary.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.white : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniTierBadge(count: user.bronzeCount, tier: AchievementTier.bronze),
                      _MiniTierBadge(count: user.silverCount, tier: AchievementTier.silver),
                      _MiniTierBadge(count: user.goldCount, tier: AchievementTier.gold),
                      _MiniTierBadge(count: user.platinumCount, tier: AchievementTier.platinum),
                    ],
                  ),
                ],
              ),
            ),
            
            // Total achievements
            Column(
              children: [
                Text(
                  '${user.totalAchievements}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'osiągnięć',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTierBadge extends StatelessWidget {
  final int count;
  final AchievementTier tier;

  const _MiniTierBadge({required this.count, required this.tier});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final color = _getTierColor();
    
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }
}
