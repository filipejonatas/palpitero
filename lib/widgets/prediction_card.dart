import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import '../models/match_prediction.dart';
import 'match_card.dart';
import 'score_stepper.dart';

/// A [MatchCard] with the prediction form: one [ScoreStepper] per team,
/// the penalty winner when a knockout match ends in a draw, and the
/// confirm button.
///
/// Every edit is reported through [onDraftChanged]; [onSave] fires on
/// confirm. The card keeps the draft locally and resyncs when
/// [draftPrediction] changes.
class PredictionCard extends StatefulWidget {
  const PredictionCard({
    super.key,
    required this.match,
    required this.draftPrediction,
    required this.savedPrediction,
    required this.isSaving,
    required this.isLocked,
    required this.onDraftChanged,
    required this.onSave,
  });

  final MatchPrediction match;
  final UserMatchPrediction? draftPrediction;
  final UserMatchPrediction? savedPrediction;
  final bool isSaving;
  final bool isLocked;
  final ValueChanged<UserMatchPrediction> onDraftChanged;
  final ValueChanged<UserMatchPrediction> onSave;

  @override
  State<PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends State<PredictionCard> {
  late int _homeScore;
  late int _awayScore;
  MatchPick? _qualifiedPick;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant PredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.fixtureId != widget.match.fixtureId ||
        oldWidget.draftPrediction != widget.draftPrediction) {
      _syncFromWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction = _draftPrediction;
    final saved = widget.savedPrediction;
    final canEdit = !widget.isSaving && !widget.isLocked;
    final note = Theme.of(context).textTheme.bodyMedium;

    return MatchCard(
      match: widget.match,
      homeScoreOverride: _homeScore,
      awayScoreOverride: _awayScore,
      footer: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ScoreStepper(
                  label: widget.match.homeTeam,
                  value: _homeScore,
                  enabled: canEdit,
                  onChanged: (value) => _update(() => _homeScore = value),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ScoreStepper(
                  label: widget.match.awayTeam,
                  value: _awayScore,
                  enabled: canEdit,
                  onChanged: (value) => _update(() => _awayScore = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_shouldAskQualifiedPick) ...[
            QualifiedPickSelector(
              homeTeam: widget.match.homeTeam,
              awayTeam: widget.match.awayTeam,
              value: _qualifiedPick ?? MatchPick.home,
              enabled: canEdit,
              onChanged: (value) => _update(() => _qualifiedPick = value),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppButton(
            label: widget.isSaving
                ? 'Confirmando...'
                : saved != null
                ? 'Atualizar palpite'
                : 'Confirmar palpite',
            icon: PhosphorIcon(PhosphorIcons.checkCircle()),
            isLoading: widget.isSaving,
            onPressed: canEdit ? () => widget.onSave(prediction) : null,
          ),
          if (widget.isLocked) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Palpites encerrados para este jogo.', style: note),
          ],
          if (saved != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Salvo: ${_predictionLabel(saved)}', style: note),
          ],
        ],
      ),
    );
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onDraftChanged(_draftPrediction);
  }

  UserMatchPrediction get _draftPrediction {
    return UserMatchPrediction(
      pick: pickFromScore(_homeScore, _awayScore),
      qualifiedPick: _shouldAskQualifiedPick
          ? (_qualifiedPick ?? MatchPick.home)
          : null,
      homeScore: _homeScore,
      awayScore: _awayScore,
    );
  }

  bool get _shouldAskQualifiedPick {
    return widget.match.isPlayoffMatch && _homeScore == _awayScore;
  }

  void _syncFromWidget() {
    _homeScore = widget.draftPrediction?.homeScore ?? 0;
    _awayScore = widget.draftPrediction?.awayScore ?? 0;
    _qualifiedPick = widget.draftPrediction?.qualifiedPick ?? MatchPick.home;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDraftChanged(_draftPrediction);
    });
  }

  String _predictionLabel(UserMatchPrediction prediction) {
    final pick = switch (prediction.pick) {
      MatchPick.home => widget.match.homeTeam,
      MatchPick.draw => 'Empate',
      MatchPick.away => widget.match.awayTeam,
    };
    return '$pick (${prediction.homeScore} x ${prediction.awayScore})';
  }
}

/// "Em caso de penaltis, quem passa?": picks the team that goes through
/// when a knockout prediction is a draw.
class QualifiedPickSelector extends StatelessWidget {
  const QualifiedPickSelector({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String homeTeam;
  final String awayTeam;
  final MatchPick value;
  final bool enabled;
  final ValueChanged<MatchPick> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.elevated(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'Em caso de penaltis, quem passa?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.strong.copyWith(
              color: context.tokens.brandOnSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SegmentedButton<MatchPick>(
              segments: [
                for (final (pick, team) in [
                  (MatchPick.home, homeTeam),
                  (MatchPick.away, awayTeam),
                ])
                  ButtonSegment(
                    value: pick,
                    label: Text(
                      team,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {value},
              onSelectionChanged: enabled
                  ? (selected) => onChanged(selected.first)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
