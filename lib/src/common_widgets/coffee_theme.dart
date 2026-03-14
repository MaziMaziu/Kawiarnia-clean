import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// === PALETA KOLORÓW KAWIARNI ===
class CoffeeColors {
  static const Color primary = Color(0xFF6F4E37); // Ciepły brąz kawy
  static const Color secondary = Color(0xFFD4A574); // Karmelowy odcień
  static const Color accent = Color(0xFFE8B55C); // Złoty akcent
  static const Color background = Color(0xFFFAF7F2); // Ciepłe, kremowe tło
  static const Color surface = Color(0xFFFFFFFF); // Białe powierzchnie
  static const Color darkBrown = Color(0xFF3E2723); // Ciemny brąz do tekstów
}

// === WSPÓLNE WIDGETY KAWIARNI ===

/// Nagłówek sekcji w stylu kawiarni
class CoffeeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const CoffeeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pusta zawartość z ikoną
class CoffeeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const CoffeeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 100,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Karta z gradientem
class CoffeeGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const CoffeeGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Ikona w okrągłym kontenerze
class CoffeeIconCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const CoffeeIconCircle({
    super.key,
    required this.icon,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(size / 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? theme.colorScheme.primary,
      ),
    );
  }
}
