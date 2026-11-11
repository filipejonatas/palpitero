import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';

/// Footer line of a [MatchCard]: small icon, a line of text and an
/// optional trailing widget (round name, action).
class MatchInfoRow extends StatelessWidget {
  const MatchInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.trailing,
  });

  final PhosphorIconData icon;
  final String label;

  /// Defaults to `textSecondary`; `success` for a confirmed result.
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(
          icon,
          size: 16,
          color: iconColor ?? context.tokens.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        ?trailing,
      ],
    );
  }
}
