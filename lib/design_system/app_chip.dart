import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Selectable pill (round, filter, tab). Selected = lima fill with
/// `onBrand` text; idle = `surfaceElevated` (docs/DESIGN.md, "Lima como
/// preenchimento").
///
/// For a read-only status use [AppBadge] instead.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;

  /// `null` makes the chip display-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadii.pill);

    final chip = AnimatedContainer(
      duration: AppDurations.fast,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: selected ? t.brand : t.surfaceElevated,
        borderRadius: radius,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: selected ? t.onBrand : null),
      ),
    );

    return Semantics(
      selected: selected,
      button: onTap != null,
      child: onTap == null
          ? chip
          : InkWell(borderRadius: radius, onTap: onTap, child: chip),
    );
  }
}
