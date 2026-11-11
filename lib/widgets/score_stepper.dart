import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';

/// Picks one team's score with − / + buttons, from [min] to [max]
/// (0 to 9 by default). The buttons have the tooltips "Diminuir" and
/// "Aumentar" and disable themselves at the limits.
class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.min = 0,
    this.max = 9,
  });

  /// Team name above the value.
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.elevated(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                tooltip: 'Diminuir',
                icon: PhosphorIcons.minus(),
                onTap: enabled && value > min
                    ? () => onChanged(value - 1)
                    : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              _StepButton(
                tooltip: 'Aumentar',
                icon: PhosphorIcons.plus(),
                onTap: enabled && value < max
                    ? () => onChanged(value + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  static const _size = 40.0;

  final String tooltip;
  final PhosphorIconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(_size),
        fixedSize: const Size.square(_size),
        padding: EdgeInsets.zero,
        backgroundColor: t.background,
        foregroundColor: t.brandOnSurface,
        disabledForegroundColor: t.textDisabled,
      ),
      icon: PhosphorIcon(icon, size: AppSizes.iconSm),
    );
  }
}
