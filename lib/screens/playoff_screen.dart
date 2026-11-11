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
import '../widgets/logout_circle_button.dart';

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
        ? _PreviewBracket(participants: participants)
        : _OfficialBracket(
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
            const _RulesPanel(),
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

  List<_BracketParticipant> get _participants {
    return _entries
        .take(_PreviewBracket.maxParticipants)
        .map(
          (entry) => _BracketParticipant(
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

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pontuação do mata-mata', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          const _RuleLine(text: 'Base: 5 / 7 / 10 pts'),
          const _RuleLine(text: 'Semifinal: 10 / 14 / 20 pts'),
          const _RuleLine(
            text: 'Terceiro: 13 / 18 / 25 pts; final: 15 / 21 / 30 pts',
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: context.tokens.border, height: 18),
          const _RuleLine(
            text:
                'Seed é a posição no ranking geral no fechamento da chave. Se faltar player, os melhores seeds recebem bye e avançam direto.',
          ),
          const _RuleLine(
            text: 'Em empate de pontos no confronto, passa o seed mais alto.',
          ),
          const _RuleLine(
            text: 'A disputa começa a contar em 28/06, na fase 1/16 da Copa.',
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.tokens.brandOnSurface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PreviewBracket extends StatefulWidget {
  const _PreviewBracket({required this.participants});

  static const int maxParticipants = 32;
  static const List<int> seedOrder = [
    1,
    32,
    16,
    17,
    8,
    25,
    9,
    24,
    4,
    29,
    13,
    20,
    5,
    28,
    12,
    21,
    2,
    31,
    15,
    18,
    7,
    26,
    10,
    23,
    3,
    30,
    14,
    19,
    6,
    27,
    11,
    22,
  ];

  final List<_BracketParticipant> participants;

  @override
  State<_PreviewBracket> createState() => _PreviewBracketState();
}

class _PreviewBracketState extends State<_PreviewBracket> {
  final ScrollController _scrollController = ScrollController();
  bool _didCenterBracket = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantBySeed = {
      for (final participant in widget.participants)
        participant.seed: participant,
    };
    final firstRound = _PreviewBracket.seedOrder
        .map(
          (seed) =>
              participantBySeed[seed] ?? _BracketParticipant.bye(seed: seed),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportContentWidth = constraints.maxWidth - 28;
        final bracketViewportWidth = viewportContentWidth > 1120
            ? viewportContentWidth
            : 1120.0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_didCenterBracket && _scrollController.hasClients) {
            final maxExtent = _scrollController.position.maxScrollExtent;
            if (maxExtent > 0) {
              _scrollController.jumpTo(maxExtent / 2);
            }
            _didCenterBracket = true;
          }
        });

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            color: context.tokens.surface,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: bracketViewportWidth,
                height: 690,
                child: Center(
                  child: SizedBox(
                    width: 1120,
                    height: 690,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BracketLinesPainter(
                              color: context.tokens.stateBorder(
                                context.tokens.brandOnSurface,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 428,
                          right: 428,
                          child: _CenterBadge(
                            participantsCount: widget.participants.length,
                          ),
                        ),
                        ..._buildFirstRoundSlots(firstRound),
                        const Positioned(
                          left: 514,
                          top: 330,
                          child: _FinalSlot(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFirstRoundSlots(List<_BracketParticipant> firstRound) {
    const slotHeight = 34.0;
    const rowGap = 8.0;
    const top = 18.0;
    final slots = <Widget>[];

    for (var index = 0; index < 16; index++) {
      final isByeWin =
          index.isEven && firstRound[index + 1].isBye ||
          index.isOdd && firstRound[index - 1].isBye;
      slots.add(
        Positioned(
          left: 10,
          top: top + index * (slotHeight + rowGap),
          child: _PlayerSlot(
            participant: firstRound[index],
            isAdvanced: isByeWin && !firstRound[index].isBye,
          ),
        ),
      );
    }

    for (var index = 16; index < 32; index++) {
      final localIndex = index - 16;
      final isByeWin =
          localIndex.isEven && firstRound[index + 1].isBye ||
          localIndex.isOdd && firstRound[index - 1].isBye;
      slots.add(
        Positioned(
          right: 10,
          top: top + localIndex * (slotHeight + rowGap),
          child: _PlayerSlot(
            participant: firstRound[index],
            alignRight: true,
            isAdvanced: isByeWin && !firstRound[index].isBye,
          ),
        ),
      );
    }

    return slots;
  }
}

class _BracketParticipant {
  const _BracketParticipant({
    required this.seed,
    required this.nick,
    required this.score,
    this.userId = '',
    this.isBye = false,
  });

  factory _BracketParticipant.bye({required int seed}) {
    return _BracketParticipant(seed: seed, nick: 'BYE', score: 0, isBye: true);
  }

  final int seed;
  final String nick;
  final int score;
  final String userId;
  final bool isBye;
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.participant,
    this.alignRight = false,
    this.isAdvanced = false,
    this.width = 214,
  });

  final _BracketParticipant participant;
  final bool alignRight;
  final bool isAdvanced;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = Theme.of(context).textTheme.labelMedium;
    final background = participant.isBye
        ? t.background
        : isAdvanced
        ? t.brand
        : t.surfaceElevated;
    final foreground = isAdvanced ? t.onBrand : t.textPrimary;
    final secondary = isAdvanced ? t.onBrand : t.textSecondary;

    return Container(
      width: width,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: participant.isBye
              ? t.border
              : isAdvanced
              ? t.brand
              : t.borderStrong,
        ),
      ),
      child: Row(
        textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Text(
            participant.seed <= 0 ? '--' : '#${participant.seed}',
            style: label?.numeric.copyWith(color: secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              participant.nick,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: label?.strong.copyWith(
                color: participant.isBye ? t.textSecondary : foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${participant.score}',
            style: label?.numeric.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _OfficialBracket extends StatefulWidget {
  const _OfficialBracket({
    required this.bracket,
    required this.roundScoresByRound,
  });

  final PlayoffBracket bracket;
  final Map<String, Map<String, PlayoffRoundScore>> roundScoresByRound;

  @override
  State<_OfficialBracket> createState() => _OfficialBracketState();
}

class _OfficialBracketState extends State<_OfficialBracket> {
  final ScrollController _scrollController = ScrollController();
  bool _didCenterBracket = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didCenterBracket && _scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent > 0) {
          _scrollController.jumpTo(maxExtent / 2);
        }
        _didCenterBracket = true;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportContentWidth = constraints.maxWidth - 28;
        final bracketViewportWidth = viewportContentWidth > 1120
            ? viewportContentWidth
            : 1120.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            color: context.tokens.surface,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: bracketViewportWidth,
                height: 690,
                child: Center(
                  child: SizedBox(
                    width: 1120,
                    height: 690,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BracketLinesPainter(
                              color: context.tokens.stateBorder(
                                context.tokens.brandOnSurface,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 428,
                          right: 428,
                          child: _CenterBadge(
                            participantsCount:
                                widget.bracket.participants.length,
                          ),
                        ),
                        ..._officialSlots(),
                        const Positioned(
                          left: 514,
                          top: 330,
                          child: _FinalSlot(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _officialSlots() {
    final slots = <Widget>[];
    final matchesByRoundIndex = <int, List<PlayoffMatch>>{};
    for (final match in widget.bracket.matches) {
      matchesByRoundIndex.putIfAbsent(match.roundIndex, () => []).add(match);
    }
    for (final matches in matchesByRoundIndex.values) {
      matches.sort((a, b) => a.position.compareTo(b.position));
    }

    slots.addAll(_firstRoundSlots(matchesByRoundIndex[0] ?? []));
    slots.addAll(_advancedRoundSlots(matchesByRoundIndex[1] ?? [], 1));
    slots.addAll(_advancedRoundSlots(matchesByRoundIndex[2] ?? [], 2));
    slots.addAll(_advancedRoundSlots(matchesByRoundIndex[3] ?? [], 3));
    slots.addAll(_advancedRoundSlots(matchesByRoundIndex[4] ?? [], 4));
    return slots;
  }

  List<Widget> _firstRoundSlots(List<PlayoffMatch> matches) {
    const slotHeight = 34.0;
    const rowGap = 8.0;
    const top = 18.0;
    final slots = <Widget>[];

    for (final match in matches) {
      final localMatchIndex = match.position <= 8
          ? match.position - 1
          : match.position - 9;
      final participantRows = [
        _participantSlot(match.participantA, match),
        _participantSlot(match.participantB, match),
      ];

      for (var row = 0; row < participantRows.length; row++) {
        final participant = participantRows[row];
        if (participant == null) continue;

        final topOffset =
            top + (localMatchIndex * 2 + row) * (slotHeight + rowGap);
        final alignRight = match.position > 8;
        slots.add(
          Positioned(
            left: alignRight ? null : 10,
            right: alignRight ? 10 : null,
            top: topOffset,
            child: _PlayerSlot(
              participant: participant,
              alignRight: alignRight,
              isAdvanced: participant.userId == match.winnerParticipantId,
            ),
          ),
        );
      }
    }

    return slots;
  }

  List<Widget> _advancedRoundSlots(List<PlayoffMatch> matches, int roundIndex) {
    if (matches.isEmpty) return [];
    if (roundIndex == 4) {
      return _finalRoundSlots(matches.first);
    }

    final split = matches.length / 2;
    final leftMatches = matches
        .where((match) => match.position <= split)
        .toList();
    final rightMatches = matches
        .where((match) => match.position > split)
        .toList();
    final specs = _roundSpecs[roundIndex]!;
    final slots = <Widget>[];

    for (var index = 0; index < leftMatches.length; index++) {
      slots.addAll(
        _matchSlots(
          match: leftMatches[index],
          left: specs.leftX,
          top: specs.leftTops[index],
          compact: roundIndex >= 3,
        ),
      );
    }

    for (var index = 0; index < rightMatches.length; index++) {
      slots.addAll(
        _matchSlots(
          match: rightMatches[index],
          right: specs.rightX,
          top: specs.rightTops[index],
          alignRight: true,
          compact: roundIndex >= 3,
        ),
      );
    }

    return slots;
  }

  List<Widget> _finalRoundSlots(PlayoffMatch match) {
    final participants = [
      _participantSlot(match.participantA, match),
      _participantSlot(match.participantB, match),
    ];
    final leftParticipant = participants[0];
    final rightParticipant = participants[1];
    final slots = <Widget>[];

    if (leftParticipant != null) {
      slots.add(
        Positioned(
          left: 360,
          top: 330,
          child: _PlayerSlot(
            participant: leftParticipant,
            isAdvanced: leftParticipant.userId == match.winnerParticipantId,
            width: 144,
          ),
        ),
      );
    }
    if (rightParticipant != null) {
      slots.add(
        Positioned(
          right: 360,
          top: 330,
          child: _PlayerSlot(
            participant: rightParticipant,
            alignRight: true,
            isAdvanced: rightParticipant.userId == match.winnerParticipantId,
            width: 144,
          ),
        ),
      );
    }

    return slots;
  }

  List<Widget> _matchSlots({
    required PlayoffMatch match,
    required double top,
    double? left,
    double? right,
    bool alignRight = false,
    bool compact = false,
  }) {
    final slotGap = compact ? 4.0 : 6.0;
    final participants = [
      _participantSlot(match.participantA, match),
      _participantSlot(match.participantB, match),
    ];

    final slots = <Widget>[];

    for (var index = 0; index < participants.length; index++) {
      final participant = participants[index];
      if (participant == null) continue;

      slots.add(
        Positioned(
          left: left,
          right: right,
          top: top + index * (34 + slotGap),
          child: _PlayerSlot(
            participant: participant,
            alignRight: alignRight,
            isAdvanced: participant.userId == match.winnerParticipantId,
            width: compact ? 154 : 178,
          ),
        ),
      );
    }

    return slots;
  }

  _BracketParticipant? _participantSlot(
    PlayoffParticipant? participant,
    PlayoffMatch match,
  ) {
    if (participant == null) {
      return null;
    }

    final roundScore =
        widget.roundScoresByRound[match.round]?[participant.userId]?.points ??
        0;

    return _BracketParticipant(
      seed: participant.seed,
      nick: participant.nick,
      score: roundScore,
      userId: participant.userId,
      isBye:
          match.isBye &&
          (match.participantA == null || match.participantB == null),
    );
  }
}

class _RoundSlotSpec {
  const _RoundSlotSpec({
    required this.leftX,
    required this.rightX,
    required this.leftTops,
    required this.rightTops,
  });

  final double leftX;
  final double rightX;
  final List<double> leftTops;
  final List<double> rightTops;
}

const _roundSpecs = {
  1: _RoundSlotSpec(
    leftX: 258,
    rightX: 258,
    leftTops: [39, 207, 375, 543],
    rightTops: [39, 207, 375, 543],
  ),
  2: _RoundSlotSpec(
    leftX: 318,
    rightX: 318,
    leftTops: [123, 459],
    rightTops: [123, 459],
  ),
  3: _RoundSlotSpec(leftX: 340, rightX: 340, leftTops: [291], rightTops: [291]),
  4: _RoundSlotSpec(leftX: 478, rightX: 478, leftTops: [602], rightTops: []),
};

class _FinalSlot extends StatelessWidget {
  const _FinalSlot();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      width: 92,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.stateFill(t.brand),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: t.stateBorder(t.brand)),
      ),
      child: Text(
        'FINAL',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.strong.copyWith(color: t.brandOnSurface),
      ),
    );
  }
}

class _CenterBadge extends StatelessWidget {
  const _CenterBadge({required this.participantsCount});

  final int participantsCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          'PLAYOFF',
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$participantsCount/32 players',
          textAlign: TextAlign.center,
          style: text.labelMedium?.numeric.copyWith(
            color: context.tokens.brandOnSurface,
          ),
        ),
      ],
    );
  }
}

class _BracketLinesPainter extends CustomPainter {
  _BracketLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawSide(canvas, paint, isLeft: true);
    _drawSide(canvas, paint, isLeft: false);

    canvas.drawLine(const Offset(514, 347), const Offset(606, 347), paint);
  }

  void _drawSide(Canvas canvas, Paint paint, {required bool isLeft}) {
    const slotHeight = 34.0;
    const rowGap = 8.0;
    const top = 18.0;
    final rowCenters = List<double>.generate(
      16,
      (index) => top + index * (slotHeight + rowGap) + slotHeight / 2,
    );
    final round2 = _midpoints(rowCenters);
    final round3 = _midpoints(round2);
    final round4 = _midpoints(round3);
    final round5 = _midpoints(round4);

    if (isLeft) {
      _connect(canvas, paint, rowCenters, round2, 224, 330);
      _connect(canvas, paint, round2, round3, 330, 450);
      _connect(canvas, paint, round3, round4, 450, 550);
      _connect(canvas, paint, round4, round5, 550, 514);
    } else {
      _connect(canvas, paint, rowCenters, round2, 896, 790);
      _connect(canvas, paint, round2, round3, 790, 670);
      _connect(canvas, paint, round3, round4, 670, 570);
      _connect(canvas, paint, round4, round5, 570, 606);
    }
  }

  List<double> _midpoints(List<double> values) {
    return [
      for (var index = 0; index < values.length; index += 2)
        (values[index] + values[index + 1]) / 2,
    ];
  }

  void _connect(
    Canvas canvas,
    Paint paint,
    List<double> from,
    List<double> to,
    double fromX,
    double toX,
  ) {
    for (var index = 0; index < to.length; index++) {
      final first = from[index * 2];
      final second = from[index * 2 + 1];
      final target = to[index];
      final elbowX = (fromX + toX) / 2;

      canvas.drawLine(Offset(fromX, first), Offset(elbowX, first), paint);
      canvas.drawLine(Offset(fromX, second), Offset(elbowX, second), paint);
      canvas.drawLine(Offset(elbowX, first), Offset(elbowX, second), paint);
      canvas.drawLine(Offset(elbowX, target), Offset(toX, target), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}
