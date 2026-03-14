import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/achievements/models/achievement.dart';

/// Widget wyświetlający powiadomienie o odblokowaniu osiągnięcia
class AchievementUnlockedNotification {
  static void show(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context);
    
    final overlayEntry = OverlayEntry(
      builder: (context) => _AchievementNotificationWidget(
        achievement: achievement,
        theme: theme,
      ),
    );

    overlay.insert(overlayEntry);

    // Usuń po 4 sekundach
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
}

class _AchievementNotificationWidget extends StatefulWidget {
  final Achievement achievement;
  final ThemeData theme;

  const _AchievementNotificationWidget({
    required this.achievement,
    required this.theme,
  });

  @override
  State<_AchievementNotificationWidget> createState() => _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState extends State<_AchievementNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();

    // Rozpocznij animację wyjścia po 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    widget.achievement.color.withOpacity(0.9),
                    widget.achievement.color,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.achievement.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Osiągnięcie odblokowane!',
                          style: widget.theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.achievement.name,
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.achievement.pointsReward} punktów',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
