import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/match_prediction.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../utils/match_day_selector.dart';
import '../widgets/widgets.dart';

/// Palpite screen where users predict exact scores for each match.
class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({
    super.key,
    required this.sessionController,
    this.predictionService,
  });

  final SessionController sessionController;
  final PredictionService? predictionService;

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final Map<int, UserMatchPrediction> _picks = {};
  final Map<int, UserMatchPrediction> _drafts = {};
  List<MatchPrediction> _matches = [];
  late final PredictionService _predictionService =
      widget.predictionService ?? PredictionService();
  bool _isLoading = true;
  bool _isSavingAll = false;
  int? _savingFixtureId;
  int _dayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  @override
  Widget build(BuildContext context) {
    final matchDays = _matchDays;
    final visibleDay = matchDays.isEmpty ? null : matchDays[_dayIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: LogoutCircleButton(
              sessionController: widget.sessionController,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.bottomNavClearance,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverList.list(
                    children: [
                      const AppPageHeader(
                        eyebrow: 'Mata-mata',
                        title: 'Seus palpites',
                        subtitle:
                            'Ajuste o placar de 0 a 9 antes da bola rolar.',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_isLoading)
                        const AppLoading()
                      else ...[
                        if (_matches.isEmpty)
                          const AppEmptyState(
                            message: 'Nenhum jogo encontrado.',
                          )
                        else ...[
                          AppButton(
                            label: _isSavingAll
                                ? 'Salvando palpites...'
                                : 'Salvar dia',
                            icon: PhosphorIcon(PhosphorIcons.floppyDisk()),
                            isLoading: _isSavingAll,
                            onPressed: _canSaveAll ? _saveAllPredictions : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          RoundHeader(label: visibleDay!.label),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ],
                  ),
                  if (!_isLoading && visibleDay != null) ...[
                    // Lazy: only the cards on screen are built. A card that
                    // scrolls away is rebuilt from _drafts, which every edit
                    // updates, so no draft is lost.
                    SliverList.builder(
                      itemCount: visibleDay.matches.length,
                      itemBuilder: (context, index) {
                        final match = visibleDay.matches[index];
                        return Padding(
                          key: ValueKey(match.fixtureId),
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child:
                              PredictionCard(
                                    match: match,
                                    draftPrediction: _drafts[match.fixtureId],
                                    savedPrediction: _picks[match.fixtureId],
                                    isSaving:
                                        _savingFixtureId == match.fixtureId,
                                    isLocked: !match.isPredictionOpen(),
                                    onDraftChanged: (prediction) {
                                      _drafts[match.fixtureId] = prediction;
                                    },
                                    onSave: (prediction) =>
                                        _savePrediction(match, prediction),
                                  )
                                  .animate()
                                  .fadeIn(duration: 220.ms)
                                  .slideY(begin: .06),
                        );
                      },
                    ),
                    if (matchDays.length > 1)
                      SliverToBoxAdapter(
                        child: DaySelector(
                          index: _dayIndex,
                          count: matchDays.length,
                          onChanged: (index) =>
                              setState(() => _dayIndex = index),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MatchDay> get _matchDays => groupMatchesByKickoffDate(_matches);

  bool get _canSaveAll {
    return !_isSavingAll &&
        _savingFixtureId == null &&
        _visibleDayMatches.any((match) => match.isPredictionOpen());
  }

  List<MatchPrediction> get _visibleDayMatches {
    final matchDays = _matchDays;
    if (matchDays.isEmpty || _dayIndex >= matchDays.length) {
      return const <MatchPrediction>[];
    }
    return matchDays[_dayIndex].matches;
  }

  Future<void> _loadPredictions() async {
    final user = widget.sessionController.currentUser;
    if (user == null) return;

    List<MatchPrediction> matches;
    try {
      matches = await _predictionService.loadMatches();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _matches = [];
        _dayIndex = 0;
        _picks.clear();
        _isLoading = false;
      });
      _showMessage('Nao foi possivel carregar jogos da API.', isError: true);
      debugPrint('Falha ao carregar jogos: $error');
      return;
    }

    Map<int, UserMatchPrediction> predictions = {};
    try {
      predictions = await _predictionService.loadUserPredictions(user);
    } catch (error) {
      debugPrint('Falha ao carregar palpites do usuario: $error');
      _showMessage(
        'Nao foi possivel carregar seus palpites salvos.',
        isError: true,
      );
    }

    if (!mounted) return;
    final matchDays = groupMatchesByKickoffDate(matches);
    setState(() {
      _matches = matches;
      _dayIndex = initialMatchDayIndex(
        matchDays.map((day) => day.matches).toList(),
      );
      _picks
        ..clear()
        ..addAll(predictions);
      _drafts
        ..clear()
        ..addEntries(
          matches.map(
            (match) => MapEntry(
              match.fixtureId,
              predictions[match.fixtureId] ??
                  const UserMatchPrediction(
                    pick: MatchPick.draw,
                    homeScore: 0,
                    awayScore: 0,
                  ),
            ),
          ),
        );
      _isLoading = false;
    });
  }

  Future<void> _savePrediction(
    MatchPrediction match,
    UserMatchPrediction prediction,
  ) async {
    final AppUser? user = widget.sessionController.currentUser;
    if (user == null) return;

    setState(() {
      _savingFixtureId = match.fixtureId;
    });

    try {
      await _predictionService.savePrediction(
        user: user,
        match: match,
        prediction: prediction,
      );
      if (!mounted) return;
      setState(() {
        _picks[match.fixtureId] = prediction;
        _drafts[match.fixtureId] = prediction;
      });
      _showMessage('Palpite salvo.');
    } catch (error) {
      debugPrint('Falha ao salvar palpite: $error');
      if (!mounted) return;
      _showMessage('Nao foi possivel salvar o palpite.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingFixtureId = null);
      }
    }
  }

  Future<void> _saveAllPredictions() async {
    final AppUser? user = widget.sessionController.currentUser;
    if (user == null) return;

    final predictions = <MatchPrediction, UserMatchPrediction>{};
    for (final match in _visibleDayMatches) {
      final prediction = _drafts[match.fixtureId];
      if (prediction == null || !match.isPredictionOpen()) continue;
      predictions[match] = prediction;
    }
    if (predictions.isEmpty) {
      _showMessage('Nenhum jogo aberto para salvar.');
      return;
    }

    setState(() => _isSavingAll = true);
    try {
      await _predictionService.savePredictionsBulk(
        user: user,
        predictions: predictions,
      );
      if (!mounted) return;
      setState(() {
        for (final entry in predictions.entries) {
          _picks[entry.key.fixtureId] = entry.value;
        }
      });
      _showMessage('${predictions.length} palpites do dia salvos.');
    } catch (error) {
      debugPrint('Falha ao salvar todos os palpites: $error');
      if (!mounted) return;
      _showMessage('Nao foi possivel salvar todos os palpites.', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      isError
          ? AppSnackBar.error(context, message)
          : AppSnackBar.info(context, message);
    });
  }
}
