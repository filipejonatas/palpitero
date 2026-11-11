import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../design_system/design_system.dart';
import '../../models/match_prediction.dart';
import '../../models/playoff.dart';
import '../../utils/playoff_rounds.dart';
import '../leaderboard_row.dart';
import '../match_status_badge.dart';

/// One knockout duel, side by side: each competitor's round points (the
/// winner highlighted), "VS" between them, and below, what each one
/// predicted for the round's finished matches.
class BracketMatchup extends StatelessWidget {
  const BracketMatchup({
    super.key,
    required this.match,
    required this.scoresByUserId,
    required this.roundPredictionResults,
  });

  final PlayoffMatch match;
  final Map<String, PlayoffRoundScore> scoresByUserId;
  final List<MatchPredictionResults> roundPredictionResults;

  @override
  Widget build(BuildContext context) {
    final participantA = match.participantA;
    final participantB = match.participantB;

    return Column(
      children: [
        _competitor(participantA),
        const SizedBox(height: AppSpacing.md),
        _VersusDivider(isBye: match.isBye),
        const SizedBox(height: AppSpacing.md),
        _competitor(participantB),
        const SizedBox(height: AppSpacing.lg),
        _MatchupPredictions(
          participantA: participantA,
          participantB: participantB,
          results: roundPredictionResults,
        ),
      ],
    );
  }

  Widget _competitor(PlayoffParticipant? participant) {
    final score = participant == null
        ? null
        : scoresByUserId[participant.userId];
    final isWinner = participant?.userId == match.winnerParticipantId;

    return LeaderboardRow(
      rank: participant == null ? 'BYE' : '#${participant.seed}',
      nick: participant?.nick ?? 'Aguardando adversario',
      avatarId: participant?.avatarId,
      photoUrl: participant?.photoUrl,
      points: score?.points ?? 0,
      highlighted: isWinner,
      pointsHighlighted: isWinner || (score?.points ?? 0) > 0,
      rankStyle: isWinner
          ? LeaderboardRankStyle.winner
          : LeaderboardRankStyle.normal,
      stats: [
        LeaderboardStat(
          icon: PhosphorIcons.target(),
          label:
              '${score?.predictionsCount ?? 0} placares - ${score?.exactScores ?? 0} exatos',
        ),
        LeaderboardStat(
          icon: PhosphorIcons.checkCircle(),
          label: '${score?.correctQualified ?? 0} classificados corretos',
        ),
      ],
    );
  }
}

/// Picks which duel of the round to show.
class MatchupPicker extends StatelessWidget {
  const MatchupPicker({
    super.key,
    required this.matches,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<PlayoffMatch> matches;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      // `initialValue` is read once: a new key resets the field when the
      // round or the selection changes from outside.
      key: ValueKey((matches.isEmpty ? '' : matches.first.id, selectedIndex)),
      initialValue: selectedIndex,
      icon: PhosphorIcon(PhosphorIcons.caretDown()),
      decoration: const InputDecoration(labelText: 'Resultado dos confrontos'),
      items: [
        for (final (index, match) in matches.indexed)
          DropdownMenuItem(
            value: index,
            child: Text(
              playoffMatchLabel(match),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

/// Selected duel's name and status: check in `success` once finished.
class MatchupStatusBar extends StatelessWidget {
  const MatchupStatusBar({super.key, required this.match});

  final PlayoffMatch match;

  @override
  Widget build(BuildContext context) {
    final status = match.status.toLowerCase();
    final isFinished = status == 'finished' || status == 'done';
    final t = context.tokens;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PhosphorIcon(
            isFinished ? PhosphorIcons.checkCircle() : PhosphorIcons.clock(),
            size: AppSizes.iconSm,
            color: isFinished ? t.success : t.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              match.isBye ? 'Confronto com bye' : playoffMatchLabel(match),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          PlayoffStatusBadge(status: match.status),
        ],
      ),
    );
  }
}

class _VersusDivider extends StatelessWidget {
  const _VersusDivider({required this.isBye});

  final bool isBye;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final divider = Expanded(child: Divider(color: t.surfaceElevated));

    return Row(
      children: [
        divider,
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: t.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            isBye ? 'BYE' : 'VS',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.strong.copyWith(color: t.brandOnSurface),
          ),
        ),
        divider,
      ],
    );
  }
}

class _MatchupPredictions extends StatelessWidget {
  const _MatchupPredictions({
    required this.participantA,
    required this.participantB,
    required this.results,
  });

  final PlayoffParticipant? participantA;
  final PlayoffParticipant? participantB;
  final List<MatchPredictionResults> results;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Placares contabilizados',
            icon: PhosphorIcons.checkCircle(),
          ),
          const SizedBox(height: AppSpacing.md),
          if (results.isEmpty)
            Text(
              'Os placares aparecem aqui apos os jogos da rodada terminarem.',
              style: text.bodyMedium,
            )
          else
            for (final result in results)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard.elevated(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.homeTeam} ${result.homeScore} x ${result.awayScore} ${result.awayTeam}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _pill(result, participantA)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _pill(result, participantB)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _pill(MatchPredictionResults result, PlayoffParticipant? participant) {
    PublicPredictionResult? prediction;
    if (participant != null) {
      for (final candidate in result.predictions) {
        if (candidate.userId == participant.userId) {
          prediction = candidate;
          break;
        }
      }
    }
    return PredictionPill(nick: participant?.nick, prediction: prediction);
  }
}

/// What one competitor predicted for one match, and the points it gave.
/// Scored = success state (docs/DESIGN.md, "Acerto").
class PredictionPill extends StatelessWidget {
  const PredictionPill({super.key, this.nick, this.prediction});

  static const _minHeight = 58.0;

  /// `null` reads "A definir" (opponent not known yet).
  final String? nick;

  /// `null` reads "Sem palpite".
  final PublicPredictionResult? prediction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final prediction = this.prediction;
    final scored = (prediction?.points ?? 0) > 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: AppCard.inset(
        highlight: scored ? t.success : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nick ?? 'A definir',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.strong.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              prediction == null
                  ? 'Sem palpite'
                  : '${prediction.predictedHomeScore} x ${prediction.predictedAwayScore} - ${prediction.points} pts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.numeric.copyWith(
                color: scored ? t.success : t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
