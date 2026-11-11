import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import '../models/match_prediction.dart';
import 'avatar_badge.dart';

/// A saved prediction as a list item: leading avatar/icon, title, the
/// predicted score and, when known, the points pill.
class PredictionTile extends StatelessWidget {
  const PredictionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.points,
    this.exactScore = false,
    this.elevated = false,
  });

  /// Someone's prediction after the match, inside the results sheet:
  /// initial avatar, nick, "2 x 1" and points. Exact score = success card
  /// (docs/DESIGN.md, "Acerto").
  PredictionTile.public(PublicPredictionResult prediction, {Key? key})
    : this(
        key: key,
        leading: AvatarBadge(
          name: prediction.nick,
          radius: 18,
          onElevated: true,
        ),
        title: prediction.nick,
        subtitle:
            '${prediction.predictedHomeScore} x ${prediction.predictedAwayScore}',
        points: prediction.points,
        exactScore: prediction.exactScore,
        elevated: true,
      );

  /// One of the user's own predictions in the profile history.
  PredictionTile.history({
    Key? key,
    required MatchPrediction match,
    required UserMatchPrediction prediction,
  }) : this(
         key: key,
         leading: const _HistoryIcon(),
         title: '${match.homeTeam} x ${match.awayTeam}',
         subtitle:
             'Palpite: ${prediction.homeScore ?? '-'} x ${prediction.awayScore ?? '-'} - ${_pickLabel(match, prediction.pick)}',
       );

  final Widget leading;
  final String title;
  final String subtitle;

  /// `null` hides the points pill (match not scored yet).
  final int? points;
  final bool exactScore;

  /// Inside a sheet or card: `AppCard.elevated`.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final content = Row(
      children: [
        leading,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: text.bodyMedium),
            ],
          ),
        ),
        if (points != null) AppBadge.points(points!, highlighted: points! > 0),
      ],
    );
    final highlight = exactScore ? t.success : null;

    return elevated
        ? AppCard.elevated(highlight: highlight, child: content)
        : AppCard(highlight: highlight, child: content);
  }
}

String _pickLabel(MatchPrediction match, MatchPick pick) {
  return switch (pick) {
    MatchPick.home => match.homeTeam,
    MatchPick.draw => 'Empate',
    MatchPick.away => match.awayTeam,
  };
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon();

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      PhosphorIcons.clockCounterClockwise(),
      color: context.tokens.pending,
    );
  }
}
