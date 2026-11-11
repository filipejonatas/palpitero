import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Previous / next bar for stepping through pages, days or rounds. The
/// center shows a [label] ("Dia 2 de 5") or any [child] (e.g. chips).
///
/// A `null` callback disables that arrow (first or last page).
class AppPager extends StatelessWidget {
  const AppPager({
    super.key,
    this.label,
    this.child,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onPrevious,
    required this.onNext,
  }) : assert(
         (label == null) != (child == null),
         'Give either a label or a child.',
       );

  final String? label;
  final Widget? child;
  final String previousTooltip;
  final String nextTooltip;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: previousTooltip,
            onPressed: onPrevious,
            icon: PhosphorIcon(PhosphorIcons.caretLeft()),
          ),
          Expanded(
            child:
                child ??
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
          ),
          IconButton(
            tooltip: nextTooltip,
            onPressed: onNext,
            icon: PhosphorIcon(PhosphorIcons.caretRight()),
          ),
        ],
      ),
    );
  }
}
