import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Steps through match days: "Dia 2 de 5" with previous / next arrows.
/// [index] is zero-based; the arrows disable on the first and last day.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.index,
    required this.count,
    required this.onChanged,
  });

  final int index;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppPager(
      label: 'Dia ${index + 1} de $count',
      previousTooltip: 'Dia anterior',
      nextTooltip: 'Proximo dia',
      onPrevious: index <= 0 ? null : () => onChanged(index - 1),
      onNext: index >= count - 1 ? null : () => onChanged(index + 1),
    );
  }
}

/// Steps through knockout rounds; every round shows as a chip and the
/// current one is selected.
class RoundSelector extends StatelessWidget {
  const RoundSelector({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppPager(
      previousTooltip: 'Rodada anterior',
      nextTooltip: 'Proxima rodada',
      onPrevious: index <= 0 ? null : () => onChanged(index - 1),
      onNext: index >= labels.length - 1 ? null : () => onChanged(index + 1),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) =>
              AppChip(label: labels[i], selected: i == index),
        ),
      ),
    );
  }
}
