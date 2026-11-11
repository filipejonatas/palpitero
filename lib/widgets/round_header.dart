import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Label of a match day or round, centered between two dividers
/// ("— 11 jun —"). Sits above the list of that day's [MatchCard]s.
class RoundHeader extends StatelessWidget {
  const RoundHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final divider = Expanded(child: Divider(color: context.tokens.border));

    return Row(
      children: [
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        divider,
      ],
    );
  }
}
