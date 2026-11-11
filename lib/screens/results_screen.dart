import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/match_prediction.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../utils/match_day_selector.dart';
import '../widgets/widgets.dart';

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
            const AppPageHeader(
              title: 'Calendario oficial',
              subtitle: 'Placares e status da fase de grupos em tempo real.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoading)
              const AppLoading()
            else if (_matches.isEmpty)
              const AppEmptyState(message: 'Nenhum resultado encontrado.')
            else ...[
              RoundHeader(label: visibleDay!.label),
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
                DaySelector(
                  index: _dayIndex,
                  count: matchDays.length,
                  onChanged: (index) => setState(() => _dayIndex = index),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<MatchDay> get _matchDays => groupMatchesByKickoffLabel(_matches);

  Future<void> _loadResults() async {
    try {
      final matches = await _predictionService.loadMatches();
      if (!mounted) return;
      final matchDays = groupMatchesByKickoffLabel(matches);
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
        AppSnackBar.error(context, 'Nao foi possivel conectar ao backend.');
        return;
      }
      final matchDays = groupMatchesByKickoffLabel(mockMatches);
      setState(() {
        _matches = mockMatches;
        _dayIndex = initialMatchDayIndex(
          matchDays.map((day) => day.matches).toList(),
        );
        _isLoading = false;
      });
      AppSnackBar.error(
        context,
        'Nao foi possivel conectar ao backend. Usando resultados mockados.',
      );
    }
  }

  Future<void> _openPredictionResults(MatchPrediction match) async {
    final AppUser? user = widget.sessionController?.currentUser;
    if (user == null) return;

    showAppBottomSheet<void>(
      context: context,
      builder: (context) => _PredictionResultsSheet(
        predictionService: _predictionService,
        user: user,
        match: match,
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.match, required this.onOpenPredictions});

  final MatchPrediction match;
  final VoidCallback? onOpenPredictions;

  @override
  Widget build(BuildContext context) {
    final finished = match.isFinished;

    return MatchInfoRow(
      icon: finished ? PhosphorIcons.checkCircle() : PhosphorIcons.clock(),
      iconColor: finished ? context.tokens.success : null,
      label: finished
          ? 'Resultado confirmado'
          : 'Palpites liberados apos o fim',
      trailing: finished
          ? AppButton.text(
              label: 'Palpites',
              icon: PhosphorIcon(PhosphorIcons.users(), size: 16),
              onPressed: onOpenPredictions,
            )
          : null,
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
          0,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        child: FutureBuilder<MatchPredictionResults>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 220, child: AppLoading());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const AppErrorState(
                message: 'Nao foi possivel carregar os palpites.',
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
                    const AppEmptyState(
                      message: 'Nenhum palpite salvo para este jogo.',
                    )
                  else
                    for (final prediction in result.predictions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: PredictionTile.public(prediction),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
