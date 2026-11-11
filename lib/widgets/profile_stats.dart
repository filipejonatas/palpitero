import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../models/leaderboard_entry.dart';

/// The user's numbers (points, exact scores, predictions, position) as a
/// grid of [StatTile]s: 2 columns on phones, 4 from 520 wide. While
/// [isLoading], every value reads "--".
class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    super.key,
    required this.entry,
    required this.isLoading,
  });

  static const _wideBreakpoint = 520.0;

  final LeaderboardEntry? entry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    String value(String Function(LeaderboardEntry? entry) read) =>
        isLoading ? '--' : read(entry);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.cardGap,
          mainAxisSpacing: AppSpacing.cardGap,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            StatTile(label: 'Pontos', value: value((e) => '${e?.points ?? 0}')),
            StatTile(
              label: 'Exatos',
              value: value((e) => '${e?.exactScores ?? 0}'),
            ),
            StatTile(
              label: 'Palpites',
              value: value((e) => '${e?.predictionsCount ?? 0}'),
            ),
            StatTile(
              label: 'Posicao',
              value: value((e) => '#${e?.position ?? 0}'),
            ),
          ],
        );
      },
    );
  }
}

/// One number with its label, on an elevated card.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard.elevated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: text.titleLarge?.numeric.copyWith(
              color: context.tokens.brandOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}
