import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../models/playoff.dart';
import '../../utils/playoff_rounds.dart';

/// A player in one slot of the bracket.
class BracketParticipant {
  const BracketParticipant({
    required this.seed,
    required this.nick,
    required this.score,
    this.userId = '',
    this.isBye = false,
  });

  factory BracketParticipant.bye({required int seed}) {
    return BracketParticipant(seed: seed, nick: 'BYE', score: 0, isBye: true);
  }

  final int seed;
  final String nick;
  final int score;
  final String userId;
  final bool isBye;
}

/// The 32-player knockout bracket, scrolling sideways and starting
/// centered on the final.
///
/// - [PlayoffBracketView.preview]: seeds from the ranking, before the
///   official draw. Byes advance automatically.
/// - [PlayoffBracketView.official]: the real bracket, every round, with
///   each player's points in that round.
class PlayoffBracketView extends StatelessWidget {
  PlayoffBracketView.preview({
    super.key,
    required List<BracketParticipant> participants,
  }) : participantsCount = participants.length,
       slots = _previewSlots(participants);

  PlayoffBracketView.official({
    super.key,
    required PlayoffBracket bracket,
    required Map<String, Map<String, PlayoffRoundScore>> roundScoresByRound,
  }) : participantsCount = bracket.participants.length,
       slots = _OfficialSlots(bracket, roundScoresByRound).build();

  final int participantsCount;

  /// Positioned [BracketSlot]s on the bracket canvas.
  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    return _BracketCanvas(participantsCount: participantsCount, slots: slots);
  }
}

/// Bracket geometry, in canvas pixels. Not spacing tokens: these place
/// slots and lines on a fixed 1120×690 drawing.
abstract final class _Geometry {
  static const width = 1120.0;
  static const height = 690.0;
  static const slotHeight = 34.0;
  static const rowGap = 8.0;
  static const top = 18.0;
  static const edge = 10.0;
  static const finalTop = 330.0;

  static double rowTop(int row) => top + row * (slotHeight + rowGap);
}

class _BracketCanvas extends StatefulWidget {
  const _BracketCanvas({required this.participantsCount, required this.slots});

  final int participantsCount;
  final List<Widget> slots;

  @override
  State<_BracketCanvas> createState() => _BracketCanvasState();
}

class _BracketCanvasState extends State<_BracketCanvas> {
  final ScrollController _scrollController = ScrollController();
  bool _didCenterBracket = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
        final bracketViewportWidth = viewportContentWidth > _Geometry.width
            ? viewportContentWidth
            : _Geometry.width;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ColoredBox(
            color: t.surface,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: bracketViewportWidth,
                height: _Geometry.height,
                child: Center(
                  child: SizedBox(
                    width: _Geometry.width,
                    height: _Geometry.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BracketLinesPainter(
                              color: t.stateBorder(t.brandOnSurface),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 428,
                          right: 428,
                          child: _CenterBadge(
                            participantsCount: widget.participantsCount,
                          ),
                        ),
                        ...widget.slots,
                        const Positioned(
                          left: 514,
                          top: _Geometry.finalTop,
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
}

/// One player in the bracket: seed, nick and points. Winners (and players
/// who got a bye) fill with lima; empty bye slots step back to
/// `background`. [alignRight] mirrors it for the right half.
class BracketSlot extends StatelessWidget {
  const BracketSlot({
    super.key,
    required this.participant,
    this.alignRight = false,
    this.isAdvanced = false,
    this.width = 214,
  });

  final BracketParticipant participant;
  final bool alignRight;
  final bool isAdvanced;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = Theme.of(context).textTheme.labelMedium;
    final (Color background, Color border) = participant.isBye
        ? (t.background, t.border)
        : isAdvanced
        ? (t.brand, t.brand)
        : (t.surfaceElevated, t.borderStrong);
    final foreground = isAdvanced ? t.onBrand : t.textPrimary;
    final secondary = isAdvanced ? t.onBrand : t.textSecondary;

    return Container(
      width: width,
      height: _Geometry.slotHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: border),
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

List<Widget> _previewSlots(List<BracketParticipant> participants) {
  final bySeed = {
    for (final participant in participants) participant.seed: participant,
  };
  final firstRound = [
    for (final seed in playoffSeedOrder)
      bySeed[seed] ?? BracketParticipant.bye(seed: seed),
  ];

  return [
    for (var index = 0; index < firstRound.length; index++)
      _firstRoundSlot(
        participant: firstRound[index],
        row: index % 16,
        alignRight: index >= 16,
        // A real player whose opponent is a bye advances.
        isAdvanced: !firstRound[index].isBye && firstRound[index ^ 1].isBye,
      ),
  ];
}

Widget _firstRoundSlot({
  required BracketParticipant participant,
  required int row,
  required bool alignRight,
  required bool isAdvanced,
}) {
  return Positioned(
    left: alignRight ? null : _Geometry.edge,
    right: alignRight ? _Geometry.edge : null,
    top: _Geometry.rowTop(row),
    child: BracketSlot(
      participant: participant,
      alignRight: alignRight,
      isAdvanced: isAdvanced,
    ),
  );
}

/// Where the matches of a later round sit on each half.
class _RoundSlotSpec {
  const _RoundSlotSpec({required this.x, required this.tops});

  final double x;
  final List<double> tops;
}

const _roundSpecs = {
  1: _RoundSlotSpec(x: 258, tops: [39, 207, 375, 543]),
  2: _RoundSlotSpec(x: 318, tops: [123, 459]),
  3: _RoundSlotSpec(x: 340, tops: [291]),
};

class _OfficialSlots {
  _OfficialSlots(this.bracket, this.roundScoresByRound);

  final PlayoffBracket bracket;
  final Map<String, Map<String, PlayoffRoundScore>> roundScoresByRound;

  List<Widget> build() {
    final matchesByRoundIndex = <int, List<PlayoffMatch>>{};
    for (final match in bracket.matches) {
      matchesByRoundIndex.putIfAbsent(match.roundIndex, () => []).add(match);
    }
    for (final matches in matchesByRoundIndex.values) {
      matches.sort((a, b) => a.position.compareTo(b.position));
    }

    final finalMatches = matchesByRoundIndex[4] ?? const [];
    return [
      ..._firstRound(matchesByRoundIndex[0] ?? const []),
      for (final roundIndex in const [1, 2, 3])
        ..._laterRound(matchesByRoundIndex[roundIndex] ?? const [], roundIndex),
      if (finalMatches.isNotEmpty) ..._finalRound(finalMatches.first),
    ];
  }

  List<Widget> _firstRound(List<PlayoffMatch> matches) {
    return [
      for (final match in matches)
        for (final (row, participant) in _participants(match).indexed)
          if (participant != null)
            _firstRoundSlot(
              participant: participant,
              row:
                  (match.position <= 8
                          ? match.position - 1
                          : match.position - 9) *
                      2 +
                  row,
              alignRight: match.position > 8,
              isAdvanced: participant.userId == match.winnerParticipantId,
            ),
    ];
  }

  List<Widget> _laterRound(List<PlayoffMatch> matches, int roundIndex) {
    if (matches.isEmpty) return const [];

    final split = matches.length / 2;
    final spec = _roundSpecs[roundIndex]!;
    final compact = roundIndex >= 3;
    final left = matches.where((match) => match.position <= split).toList();
    final right = matches.where((match) => match.position > split).toList();

    return [
      for (final (index, match) in left.indexed)
        ..._matchSlots(match, spec.tops[index], spec.x, false, compact),
      for (final (index, match) in right.indexed)
        ..._matchSlots(match, spec.tops[index], spec.x, true, compact),
    ];
  }

  List<Widget> _matchSlots(
    PlayoffMatch match,
    double top,
    double x,
    bool alignRight,
    bool compact,
  ) {
    final slotGap = compact ? 4.0 : 6.0;
    return [
      for (final (index, participant) in _participants(match).indexed)
        if (participant != null)
          Positioned(
            left: alignRight ? null : x,
            right: alignRight ? x : null,
            top: top + index * (_Geometry.slotHeight + slotGap),
            child: BracketSlot(
              participant: participant,
              alignRight: alignRight,
              isAdvanced: participant.userId == match.winnerParticipantId,
              width: compact ? 154 : 178,
            ),
          ),
    ];
  }

  List<Widget> _finalRound(PlayoffMatch match) {
    return [
      for (final (index, participant) in _participants(match).indexed)
        if (participant != null)
          Positioned(
            left: index == 0 ? 360 : null,
            right: index == 1 ? 360 : null,
            top: _Geometry.finalTop,
            child: BracketSlot(
              participant: participant,
              alignRight: index == 1,
              isAdvanced: participant.userId == match.winnerParticipantId,
              width: 144,
            ),
          ),
    ];
  }

  List<BracketParticipant?> _participants(PlayoffMatch match) {
    return [
      _participant(match.participantA, match),
      _participant(match.participantB, match),
    ];
  }

  BracketParticipant? _participant(
    PlayoffParticipant? participant,
    PlayoffMatch match,
  ) {
    if (participant == null) return null;

    return BracketParticipant(
      seed: participant.seed,
      nick: participant.nick,
      score: roundScoresByRound[match.round]?[participant.userId]?.points ?? 0,
      userId: participant.userId,
      isBye:
          match.isBye &&
          (match.participantA == null || match.participantB == null),
    );
  }
}

class _FinalSlot extends StatelessWidget {
  const _FinalSlot();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      width: 92,
      height: _Geometry.slotHeight,
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
    final rowCenters = List<double>.generate(
      16,
      (index) => _Geometry.rowTop(index) + _Geometry.slotHeight / 2,
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
