import 'package:flutter/material.dart';

import '../models/match_prediction.dart';
import '../design_system/design_system.dart';
import 'match_status_badge.dart';
import 'team_flag.dart';

/// A match: both teams with flags, the score (or "VS") and the status
/// badge. [footer] holds what the screen adds below (kickoff, stepper...).
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.homeScoreOverride,
    this.awayScoreOverride,
    this.footer,
    this.onTap,
  });

  final MatchPrediction match;
  final int? homeScoreOverride;
  final int? awayScoreOverride;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scoreText = _scoreText;

    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _TeamSide(name: match.homeTeam)),
              const SizedBox(width: AppSpacing.md),
              _ScoreColumn(scoreText: scoreText, status: match.status),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _TeamSide(name: match.awayTeam)),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }

  String get _scoreText {
    final homeScore = homeScoreOverride ?? match.homeScore;
    final awayScore = awayScoreOverride ?? match.awayScore;
    if (homeScore == null || awayScore == null) return 'VS';
    return '$homeScore - $awayScore';
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamFlag(teamName: name),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.scoreText, required this.status});

  final String scoreText;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Text(
            scoreText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          MatchStatusChip(status: status),
        ],
      ),
    );
  }
}
