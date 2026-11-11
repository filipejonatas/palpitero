import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';

/// Banner with the competition name and how many matches it has.
class CompetitionStrip extends StatelessWidget {
  const CompetitionStrip({
    super.key,
    required this.title,
    required this.matchCount,
  });

  final String title;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.trophy(PhosphorIconsStyle.fill),
            color: context.tokens.brandOnSurface,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: text.titleMedium)),
          Text('$matchCount jogos', style: text.bodyMedium),
        ],
      ),
    );
  }
}
