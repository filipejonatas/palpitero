import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/match_prediction.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/match_day_selector.dart';
import '../widgets/match_card.dart';

/// Matches screen showing official scores and status cards by date.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    this.predictionService,
    this.sessionController,
  });

  final PredictionService? predictionService;
  final SessionController? sessionController;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<MatchPrediction> _matches = [];
  late final PredictionService _predictionService =
      widget.predictionService ?? PredictionService();
  bool _isLoading = true;
  int _dayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchDays = _matchDays;
    final visibleDay = matchDays.isEmpty ? null : matchDays[_dayIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            Text('Calendario oficial', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Placares e status da fase de grupos em tempo real.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxxl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_matches.isEmpty)
              const _SurfaceMessage(message: 'Nenhum resultado encontrado.')
            else ...[
              Text(visibleDay!.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final match in visibleDay.matches)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child:
                      MatchCard(
                            match: match,
                            footer: _ResultActions(
                              match: match,
                              onOpenPredictions:
                                  widget.sessionController?.currentUser ==
                                          null ||
                                      !match.isFinished
                                  ? null
                                  : () => _openPredictionResults(match),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 220.ms)
                          .slideY(begin: .06, end: 0),
                ),
              if (matchDays.length > 1)
                _MatchDaysPager(
                  currentDay: _dayIndex + 1,
                  totalDays: matchDays.length,
                  onPrevious: _dayIndex == 0
                      ? null
                      : () => setState(() => _dayIndex--),
                  onNext: _dayIndex >= matchDays.length - 1
                      ? null
                      : () => setState(() => _dayIndex++),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<_MatchDay> get _matchDays {
    return _buildMatchDays(_matches);
  }

  List<_MatchDay> _buildMatchDays(List<MatchPrediction> matches) {
    final days = <String, List<MatchPrediction>>{};
    for (final match in matches) {
      days.putIfAbsent(_dayLabel(match), () => []).add(match);
    }

    return days.entries
        .map((entry) => _MatchDay(label: entry.key, matches: entry.value))
        .toList();
  }

  Future<void> _loadResults() async {
    try {
      final matches = await _predictionService.loadMatches();
      if (!mounted) return;
      final matchDays = _buildMatchDays(matches);
      setState(() {
        _matches = matches;
        _dayIndex = initialMatchDayIndex(
          matchDays.map((day) => day.matches).toList(),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (kReleaseMode) {
        setState(() {
          _matches = [];
          _dayIndex = 0;
          _isLoading = false;
        });
        _showMessage('Nao foi possivel conectar ao backend.');
        return;
      }
      final matchDays = _buildMatchDays(mockMatches);
      setState(() {
        _matches = mockMatches;
        _dayIndex = initialMatchDayIndex(
          matchDays.map((day) => day.matches).toList(),
        );
        _isLoading = false;
      });
      _showMessage(
        'Nao foi possivel conectar ao backend. Usando resultados mockados.',
      );
    }
  }

  Future<void> _openPredictionResults(MatchPrediction match) async {
    final AppUser? user = widget.sessionController?.currentUser;
    if (user == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.tokens.surface,
      isScrollControlled: true,
      builder: (context) => _PredictionResultsSheet(
        predictionService: _predictionService,
        user: user,
        match: match,
      ),
    );
  }

  String _dayLabel(MatchPrediction match) {
    final labelParts = match.kickoffLabel.split(',');
    if (labelParts.isEmpty) return 'Dia do jogo';
    return labelParts.first.trim();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.match, required this.onOpenPredictions});

  final MatchPrediction match;
  final VoidCallback? onOpenPredictions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(
          match.isFinished
              ? PhosphorIcons.checkCircle()
              : PhosphorIcons.clock(),
          size: 16,
          color: match.isFinished
              ? context.tokens.success
              : context.tokens.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            match.isFinished
                ? 'Resultado confirmado'
                : 'Palpites liberados apos o fim',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (match.isFinished)
          TextButton.icon(
            onPressed: onOpenPredictions,
            icon: PhosphorIcon(PhosphorIcons.users(), size: 16),
            label: const Text('Palpites'),
          ),
      ],
    );
  }
}

class _PredictionResultsSheet extends StatefulWidget {
  const _PredictionResultsSheet({
    required this.predictionService,
    required this.user,
    required this.match,
  });

  final PredictionService predictionService;
  final AppUser user;
  final MatchPrediction match;

  @override
  State<_PredictionResultsSheet> createState() =>
      _PredictionResultsSheetState();
}

class _PredictionResultsSheetState extends State<_PredictionResultsSheet> {
  late final Future<MatchPredictionResults> _future = widget.predictionService
      .loadMatchPredictionResults(
        user: widget.user,
        fixtureId: widget.match.fixtureId,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        child: FutureBuilder<MatchPredictionResults>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Nao foi possivel carregar os palpites.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }

            final result = snapshot.data!;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: .72,
              minChildSize: .35,
              maxChildSize: .9,
              builder: (context, controller) => ListView(
                controller: controller,
                children: [
                  Text(
                    '${result.homeTeam} ${result.homeScore} x ${result.awayScore} ${result.awayTeam}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${result.predictions.length} palpites salvos',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (result.predictions.isEmpty)
                    const _SurfaceMessage(
                      message: 'Nenhum palpite salvo para este jogo.',
                    )
                  else
                    for (final prediction in result.predictions)
                      _PublicPredictionTile(prediction: prediction),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PublicPredictionTile extends StatelessWidget {
  const _PublicPredictionTile({required this.prediction});

  final PublicPredictionResult prediction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final scored = prediction.points > 0;
    // Exact score is a hit: success state (docs/DESIGN.md, "Semânticas").
    final highlight = prediction.exactScore
        ? t.stateFill(t.success)
        : t.surfaceElevated;
    final border = prediction.exactScore
        ? t.stateBorder(t.success)
        : t.borderSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: t.background,
            foregroundColor: t.brandOnSurface,
            child: Text(_initial, style: text.titleMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.nick,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${prediction.predictedHomeScore} x ${prediction.predictedAwayScore}',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scored ? t.brand : t.background,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              '${prediction.points} pts',
              style: text.labelLarge?.numeric.copyWith(
                color: scored ? t.onBrand : t.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _initial {
    final trimmed = prediction.nick.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}

class _MatchDay {
  const _MatchDay({required this.label, required this.matches});

  final String label;
  final List<MatchPrediction> matches;
}

class _MatchDaysPager extends StatelessWidget {
  const _MatchDaysPager({
    required this.currentDay,
    required this.totalDays,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentDay;
  final int totalDays;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Dia anterior',
            onPressed: onPrevious,
            icon: PhosphorIcon(PhosphorIcons.caretLeft()),
          ),
          Expanded(
            child: Text(
              'Dia $currentDay de $totalDays',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Proximo dia',
            onPressed: onNext,
            icon: PhosphorIcon(PhosphorIcons.caretRight()),
          ),
        ],
      ),
    );
  }
}

class _SurfaceMessage extends StatelessWidget {
  const _SurfaceMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
