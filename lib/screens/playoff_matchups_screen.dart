import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_prediction.dart';
import '../models/playoff.dart';
import '../services/leaderboard_service.dart';
import '../services/playoff_service.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../utils/playoff_rounds.dart';
import '../widgets/widgets.dart';

/// Matchup comparison screen for the knockout bracket.
class PlayoffMatchupsScreen extends StatefulWidget {
  const PlayoffMatchupsScreen({
    super.key,
    required this.sessionController,
    this.playoffService,
  });

  final SessionController sessionController;
  final PlayoffService? playoffService;

  @override
  State<PlayoffMatchupsScreen> createState() => _PlayoffMatchupsScreenState();
}

class _PlayoffMatchupsScreenState extends State<PlayoffMatchupsScreen> {
  late final PlayoffService _playoffService =
      widget.playoffService ?? PlayoffService();
  late final LeaderboardService _leaderboardService = LeaderboardService();
  late final PredictionService _predictionService = PredictionService();

  PlayoffBracket? _bracket;
  List<PlayoffRoundScore> _roundScores = [];
  List<MatchPredictionResults> _roundPredictionResults = [];
  bool _isLoading = true;
  bool _isLoadingScores = false;
  int _roundIndex = 0;
  int _matchIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _rounds;
    final selectedRound = rounds.isEmpty ? null : rounds[_roundIndex];
    final safeMatchIndex =
        selectedRound == null || selectedRound.matches.isEmpty
        ? 0
        : _matchIndex.clamp(0, selectedRound.matches.length - 1).toInt();
    final selectedMatch = selectedRound == null || selectedRound.matches.isEmpty
        ? null
        : selectedRound.matches[safeMatchIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar para o bracket',
          onPressed: () => context.go('/playoff'),
          icon: PhosphorIcon(PhosphorIcons.caretLeft()),
        ),
        title: const Text('Confrontos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _loadBracket,
            icon: PhosphorIcon(PhosphorIcons.clockCounterClockwise()),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
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
              title: 'Mata-mata',
              subtitle: 'Compare os placares e pontos de cada duelo da rodada.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoading)
              const AppLoading()
            else if (rounds.isEmpty)
              const AppEmptyState(
                message: 'Nenhum confronto de mata-mata encontrado.',
              )
            else ...[
              MatchupPicker(
                matches: selectedRound!.matches,
                selectedIndex: safeMatchIndex,
                onChanged: (value) => setState(() => _matchIndex = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              MatchupStatusBar(match: selectedMatch!),
              const SizedBox(height: AppSpacing.lg),
              if (_isLoadingScores)
                const AppLoading(padding: EdgeInsets.all(AppSpacing.xxl))
              else
                BracketMatchup(
                  match: selectedMatch,
                  scoresByUserId: _scoresByUserId,
                  roundPredictionResults: _roundPredictionResults,
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .04),
              const SizedBox(height: AppSpacing.xl),
              RoundSelector(
                labels: [for (final round in rounds) round.label],
                index: _roundIndex,
                onChanged: _selectRound,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PlayoffRound> get _rounds {
    final bracket = _bracket;
    if (bracket == null) return [];
    return groupPlayoffRounds(
      bracket.matches.isNotEmpty
          ? bracket.matches
          : buildFirstRoundFallback(bracket.participants),
    );
  }

  Map<String, PlayoffRoundScore> get _scoresByUserId {
    return {for (final score in _roundScores) score.userId: score};
  }

  Future<void> _loadBracket() async {
    setState(() {
      _isLoading = true;
      _isLoadingScores = false;
    });

    try {
      final bracket =
          await _playoffService.loadCurrentBracket() ?? await _previewBracket();
      if (!mounted) return;
      setState(() {
        _bracket = bracket;
        _roundIndex = 0;
        _matchIndex = 0;
        _isLoading = false;
      });
      await _loadRoundScores();
    } catch (error) {
      debugPrint('Falha ao carregar confrontos: $error');
      if (!mounted) return;
      setState(() {
        _bracket = null;
        _roundScores = [];
        _roundPredictionResults = [];
        _isLoading = false;
      });
      _showError('Nao foi possivel carregar os confrontos.');
    }
  }

  Future<void> _loadRoundScores() async {
    final rounds = _rounds;
    if (rounds.isEmpty) return;

    setState(() {
      _isLoadingScores = true;
      _roundScores = [];
      _roundPredictionResults = [];
    });

    var scores = <PlayoffRoundScore>[];
    var predictionResults = <MatchPredictionResults>[];
    final roundCode = rounds[_roundIndex].code;

    try {
      scores = await _playoffService.loadRoundScore(roundCode);
    } catch (error) {
      debugPrint('Falha ao carregar pontuacao da rodada: $error');
    }

    try {
      predictionResults = await _loadFinishedPredictionResults(roundCode);
    } catch (error) {
      debugPrint('Falha ao carregar placares palpitados da rodada: $error');
    }

    if (!mounted) return;
    setState(() {
      _roundScores = scores;
      _roundPredictionResults = predictionResults;
      _isLoadingScores = false;
    });
  }

  Future<List<MatchPredictionResults>> _loadFinishedPredictionResults(
    String round,
  ) async {
    final user = widget.sessionController.currentUser;
    if (user == null) return [];

    final matches = await _predictionService.loadMatches();
    final finishedMatches = matches
        .where(
          (match) =>
              isSamePlayoffRound(match.round, round) &&
              match.isPlayoffMatch &&
              match.isFinished,
        )
        .toList();

    final results = <MatchPredictionResults>[];
    for (final match in finishedMatches) {
      results.add(
        await _predictionService.loadMatchPredictionResults(
          user: user,
          fixtureId: match.fixtureId,
        ),
      );
    }
    return results;
  }

  void _selectRound(int index) {
    setState(() {
      _roundIndex = index;
      _matchIndex = 0;
    });
    _loadRoundScores();
  }

  Future<PlayoffBracket> _previewBracket() async {
    final user = widget.sessionController.currentUser;
    if (user == null) {
      return _buildPreviewBracket([]);
    }

    try {
      final entries = await _leaderboardService.loadLeaderboard(user);
      return _buildPreviewBracket(entries);
    } catch (error) {
      debugPrint('Falha ao carregar ranking para preview do mata-mata: $error');
      return _buildPreviewBracket([_fallbackEntry(user)]);
    }
  }

  PlayoffBracket _buildPreviewBracket(List<LeaderboardEntry> entries) {
    final participants = entries
        .take(32)
        .map(
          (entry) => PlayoffParticipant(
            userId: entry.userId,
            seed: entry.position,
            nick: entry.nick,
            avatarId: entry.avatarId,
            photoUrl: entry.photoUrl,
            rankingPoints: entry.points,
          ),
        )
        .toList();

    return PlayoffBracket(
      id: 'preview',
      maxParticipants: 32,
      generatedAt: DateTime.now().toUtc().toIso8601String(),
      participants: participants,
      matches: buildFirstRoundFallback(participants),
    );
  }

  LeaderboardEntry _fallbackEntry(AppUser user) {
    return LeaderboardEntry(
      position: 1,
      userId: user.id,
      nick: user.nick,
      avatarId: user.avatarId,
      photoUrl: user.photoUrl,
      points: 0,
      predictionsCount: 0,
      exactScores: 0,
      isCurrentUser: true,
    );
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.error(context, message);
    });
  }
}
