import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Background level of an [AppCard] (docs/DESIGN.md, "Sombras": elevation
/// comes from surface -> surfaceElevated, never from a shadow).
enum AppCardTone {
  /// Top-level card on the screen background: `surface` + `borderSubtle`.
  surface,

  /// Item inside a card, sheet or panel: `surfaceElevated`, no border.
  elevated,

  /// Item inside an elevated card: `background` + `borderSubtle`, one level
  /// back so it reads against `surfaceElevated`.
  inset,
}

/// Rounded container for any grouped content. The only way screens draw a
/// card: color, border, radius and padding come from tokens.
///
/// A [highlight] color turns it into a state card (`stateFill` background,
/// `stateBorder` border), e.g. `t.brand` for "my row" or `t.success` for an
/// exact hit (docs/DESIGN.md, "Como escolher a cor certa").
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = AppCardTone.surface,
    this.highlight,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.width,
    this.onTap,
  });

  const AppCard.elevated({
    super.key,
    required this.child,
    this.highlight,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.width,
    this.onTap,
  }) : tone = AppCardTone.elevated;

  const AppCard.inset({
    super.key,
    required this.child,
    this.highlight,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.width,
    this.onTap,
  }) : tone = AppCardTone.inset;

  final Widget child;
  final AppCardTone tone;

  /// State color (brand, success, loss...). Overrides [tone].
  final Color? highlight;
  final EdgeInsetsGeometry padding;

  /// `double.infinity` to fill the row.
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(AppRadii.md);
    final state = highlight;

    final (Color background, Color? border) = switch ((state, tone)) {
      (final Color color, _) => (t.stateFill(color), t.stateBorder(color)),
      (null, AppCardTone.surface) => (t.surface, t.borderSubtle),
      (null, AppCardTone.elevated) => (t.surfaceElevated, null),
      (null, AppCardTone.inset) => (t.background, t.borderSubtle),
    };

    final decoration = BoxDecoration(
      color: background,
      borderRadius: radius,
      border: border == null ? null : Border.all(color: border),
    );

    if (onTap == null) {
      return Container(
        width: width,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    // Ink paints the decoration on the Material, so the ripple shows on top.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          width: width,
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
