import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';
import '../models/playoff.dart';
import '../services/leaderboard_service.dart';
import '../services/playoff_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../widgets/widgets.dart';

/// Playoff preview screen with a seeded 32-player bracket.
class PlayoffScreen extends StatefulWidget {
  const PlayoffScreen({
    super.key,
    required this.sessionController,
    this.leaderboardService,
    this.playoffService,
  });

  final SessionController sessionController;
  final LeaderboardService? leaderboardService;
  final PlayoffService? playoffService;

  @override
  State<PlayoffScreen> createState() => _PlayoffScreenState();
}

class _PlayoffScreenState extends State<PlayoffScreen> {
  static const _maxParticipants = 32;

  late final LeaderboardService _leaderboardService =
      widget.leaderboardService ?? LeaderboardService();
  late final PlayoffService _playoffService =
      widget.playoffService ?? PlayoffService();

  List<LeaderboardEntry> _entries = [];
  PlayoffBracket? _bracket;
  Map<String, Map<String, PlayoffRoundScore>> _roundScoresByRound = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviewEntries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants = _participants;
    final bracket = _bracket == null
        ? PlayoffBracketView.preview(participants: participants)
        : PlayoffBracketView.official(
            bracket: _bracket!,
            roundScoresByRound: _roundScoresByRound,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata-Mata'),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            Text(
              'Mata-Mata da Copa do Mundo : Onde o filho chora e a mãe não vê',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(height: 1.04),
            ),
            const SizedBox(height: AppSpacing.md),
            const PlayoffRulesCard(),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Visualizar Confrontos',
              icon: PhosphorIcon(PhosphorIcons.target()),
              onPressed: _isLoading
                  ? null
                  : () => context.push('/playoff/confrontos'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              icon: PhosphorIcons.target(),
              title: _isLoading
                  ? 'Montando preview...'
                  : _bracket == null
                  ? '${participants.length} players no chaveamento'
                  : '${participants.length} players na chave oficial',
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isLoading)
              const AppLoading()
            else
              bracket.animate().fadeIn(duration: 260.ms).slideY(begin: .03),
          ],
        ),
      ),
    );
  }

  List<BracketParticipant> get _participants {
    return _entries
        .take(_maxParticipants)
        .map(
          (entry) => BracketParticipant(
            seed: entry.position,
            nick: entry.nick,
            score: 0,
          ),
        )
        .toList();
  }

  Future<void> _loadPreviewEntries() async {
    final user = widget.sessionController.currentUser;
    if (user == null) return;

    try {
      try {
        final bracket = await _playoffService.loadCurrentBracket();
        if (!mounted) return;
        if (bracket != null) {
          final roundScoresByRound = await _loadRoundScores(bracket);
          if (!mounted) return;
          setState(() {
            _bracket = bracket;
            _roundScoresByRound = roundScoresByRound;
            _entries = bracket.participants
                .map(
                  (participant) => participant.toLeaderboardEntry(
                    isCurrentUser: participant.userId == user.id,
                  ),
                )
                .toList();
            _isLoading = false;
          });
          return;
        }
      } catch (_) {
        debugPrint('Chave oficial indisponivel. Usando preview.');
      }

      final entries = await _leaderboardService.loadLeaderboard(user);
      if (!mounted) return;
      setState(() {
        _entries = entries.isEmpty ? _fallbackEntries(user) : entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = _fallbackEntries(user);
        _isLoading = false;
      });
    }
  }

  List<LeaderboardEntry> _fallbackEntries(AppUser user) {
    return [
      LeaderboardEntry(
        position: 1,
        userId: user.id,
        nick: user.nick,
        avatarId: user.avatarId,
        photoUrl: user.photoUrl,
        points: 0,
        predictionsCount: 0,
        exactScores: 0,
        isCurrentUser: true,
      ),
    ];
  }

  Future<Map<String, Map<String, PlayoffRoundScore>>> _loadRoundScores(
    PlayoffBracket bracket,
  ) async {
    final rounds = bracket.matches.map((match) => match.round).toSet();
    final entries = await Future.wait(
      rounds.map((round) async {
        try {
          final scores = await _playoffService.loadRoundScore(round);
          return MapEntry(round, {
            for (final score in scores) score.userId: score,
          });
        } catch (_) {
          return MapEntry(round, <String, PlayoffRoundScore>{});
        }
      }),
    );
    return Map.fromEntries(entries);
  }
}
