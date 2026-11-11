import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Meaning of an [AppBadge]. Each tone has one color and one meaning
/// (docs/DESIGN.md, "Cor semântica tem um significado só").
enum AppBadgeTone {
  /// Live match (`live`). Only on `background`/`surface`.
  live,

  /// Scheduled match, awaiting result (`pending`).
  pending,

  /// Finished / no state: neutral fill, `textPrimary` text.
  neutral,

  /// Hit, confirmed (`success`).
  success,

  /// Miss, error (`loss`).
  loss,

  /// Podium (`gold`).
  gold,
}

/// Small read-only pill: match status, prediction result, points.
///
/// - `AppBadge(label:, tone:)`: tonal (state color at `.14` fill and `.70`
///   border, text in the state color).
/// - `AppBadge.points(points)`: the points pill. Lima fill when
///   [highlighted], quiet `background` fill otherwise.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required String label, required this.tone})
    : _label = label,
      points = null,
      highlighted = false;

  /// Points pill: "12 pts".
  const AppBadge.points(int this.points, {super.key, this.highlighted = true})
    : _label = null,
      tone = AppBadgeTone.neutral;

  final String? _label;

  /// Set only by [AppBadge.points].
  final int? points;
  final AppBadgeTone tone;

  /// Only for [AppBadge.points]: lima fill (scored / winner).
  final bool highlighted;

  String get label => points == null ? _label! : '$points pts';

  @override
  Widget build(BuildContext context) {
    return points == null ? _buildTonal(context) : _buildPoints(context);
  }

  Widget _buildTonal(BuildContext context) {
    final t = context.tokens;
    final color = switch (tone) {
      AppBadgeTone.live => t.live,
      AppBadgeTone.pending => t.pending,
      AppBadgeTone.neutral => t.textSecondary,
      AppBadgeTone.success => t.success,
      AppBadgeTone.loss => t.loss,
      AppBadgeTone.gold => t.gold,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: t.stateFill(color),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: t.stateBorder(color)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.strong.copyWith(
          color: tone == AppBadgeTone.neutral ? t.textPrimary : color,
        ),
      ),
    );
  }

  Widget _buildPoints(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: highlighted ? t.brand : t.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.numeric.copyWith(
          color: highlighted ? t.onBrand : t.textSecondary,
        ),
      ),
    );
  }
}
