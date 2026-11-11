import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Header at the top of a screen's content: optional lima eyebrow, the
/// screen title (`display`) and a supporting line.
///
/// Spacing below it is the caller's (usually `AppSpacing.xl`).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
  });

  final String title;

  /// Short context above the title (e.g. "Mata-mata"), in `brandOnSurface`.
  final String? eyebrow;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: text.labelLarge?.copyWith(
              color: context.tokens.brandOnSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(title, style: text.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle!, style: text.bodyMedium),
        ],
      ],
    );
  }
}

/// Title of a block inside a screen ("Sua posição", "Histórico", a day
/// label), with an optional leading icon and trailing widget.
///
/// Spacing below it is the caller's (usually `AppSpacing.md`).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;

  /// Icon data shown in `brandOnSurface` before the title.
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: context.tokens.brandOnSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(child: Text(title, style: style)),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
