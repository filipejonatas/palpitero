import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Pill-shaped status chip for live, finished, and upcoming matches.
class MatchStatusChip extends StatelessWidget {
  const MatchStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isLive =
        normalized == 'LIVE' || normalized == '1H' || normalized == '2H';
    // Finished matches are neutral; anything not live or finished is
    // scheduled, which is `pending` (docs/DESIGN.md).
    if (isLive) return const AppBadge(label: 'Live', tone: AppBadgeTone.live);
    if (normalized == 'FT') {
      return const AppBadge(label: 'FT', tone: AppBadgeTone.neutral);
    }
    return AppBadge(
      label: status == 'NS' ? 'Today' : status,
      tone: AppBadgeTone.pending,
    );
  }
}

/// Knockout matchup status (`live`, `finished`/`done`, `pending`). Same
/// tones as [MatchStatusChip], with Portuguese labels.
class PlayoffStatusBadge extends StatelessWidget {
  const PlayoffStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'live' => const AppBadge(label: 'Live', tone: AppBadgeTone.live),
      'finished' ||
      'done' => const AppBadge(label: 'Finalizado', tone: AppBadgeTone.neutral),
      'pending' ||
      '' => const AppBadge(label: 'Pendente', tone: AppBadgeTone.pending),
      _ => AppBadge(label: status, tone: AppBadgeTone.pending),
    };
  }
}
