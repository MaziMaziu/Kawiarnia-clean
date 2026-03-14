import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kawiarnia/src/features/achievements/models/achievement.dart';
import 'package:kawiarnia/src/features/achievements/services/achievements_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementsService _service = AchievementsService();
  AchievementType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Osiągnięcia'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header ze statystykami
          _buildStatsHeader(theme),
          
          // Filtry
          _buildFilterChips(theme),
          
          // Lista osiągnięć
          Expanded(
            child: StreamBuilder<List<UserAchievementProgress>>(
              stream: _service.getUserProgress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userProgress = snapshot.data ?? [];
                final progressMap = {
                  for (var p in userProgress) p.achievementId: p
                };

                var achievements = AchievementsService.predefinedAchievements;
                
                // Filtrowanie
                if (_selectedFilter != null) {
                  achievements = achievements
                      .where((a) => a.type == _selectedFilter)
                      .toList();
                }

                // Sortowanie: odblokowane na końcu
                achievements.sort((a, b) {
                  final aUnlocked = progressMap[a.id]?.isUnlocked ?? false;
                  final bUnlocked = progressMap[b.id]?.isUnlocked ?? false;
                  if (aUnlocked == bUnlocked) return 0;
                  return aUnlocked ? 1 : -1;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final progress = progressMap[achievement.id];
                    
                    return _AchievementCard(
                      achievement: achievement,
                      progress: progress,
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    return StreamBuilder<List<UserAchievementProgress>>(
      stream: _service.getUserProgress(),
      builder: (context, snapshot) {
        final userProgress = snapshot.data ?? [];
        final unlockedCount = userProgress.where((p) => p.isUnlocked).length;
        final totalCount = AchievementsService.predefinedAchievements.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                Icons.emoji_events_rounded,
                '$unlockedCount/$totalCount',
                'Odblokowane',
              ),
              _buildStatItem(
                theme,
                Icons.trending_up_rounded,
                '${((unlockedCount / totalCount) * 100).toStringAsFixed(0)}%',
                'Postęp',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, null, 'Wszystkie', Icons.grid_view_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(theme, AchievementType.orders, 'Zamówienia', Icons.shopping_bag_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(theme, AchievementType.variety, 'Różnorodność', Icons.explore_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(theme, AchievementType.time, 'Czas', Icons.access_time_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(theme, AchievementType.loyalty, 'Lojalność', Icons.favorite_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(theme, AchievementType.special, 'Specjalne', Icons.star_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, AchievementType? type, String label, IconData icon) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : theme.colorScheme.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? type : null;
        });
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserAchievementProgress? progress;

  const _AchievementCard({
    required this.achievement,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = progress?.isUnlocked ?? false;
    final currentValue = progress?.currentValue ?? 0;
    final progressValue = progress?.getProgress(achievement.targetValue) ?? 0.0;

    return Card(
      elevation: isUnlocked ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    achievement.color.withOpacity(0.1),
                    theme.colorScheme.surface,
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Ikona osiągnięcia
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? achievement.color.withOpacity(0.2)
                          : theme.colorScheme.onSurface.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked ? achievement.color : theme.colorScheme.onSurface.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      achievement.icon,
                      size: 32,
                      color: isUnlocked ? achievement.color : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Nazwa i opis
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                achievement.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? theme.colorScheme.primary : null,
                                ),
                              ),
                            ),
                            _TierBadge(tier: achievement.tier),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 8,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$currentValue/${achievement.targetValue}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Punkty nagrody
                  if (isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 16, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            '+${achievement.pointsReward}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final AchievementTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getTierInfo();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _getTierInfo() {
    switch (tier) {
      case AchievementTier.bronze:
        return (const Color(0xFFCD7F32), 'BRĄZ');
      case AchievementTier.silver:
        return (const Color(0xFFC0C0C0), 'SREBRO');
      case AchievementTier.gold:
        return (const Color(0xFFFFD700), 'ZŁOTO');
      case AchievementTier.platinum:
        return (const Color(0xFFE5E4E2), 'PLATYNA');
    }
  }
}
