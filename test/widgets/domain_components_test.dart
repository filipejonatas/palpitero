import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/design_system/design_system.dart';
import 'package:palpitero/models/leaderboard_entry.dart';
import 'package:palpitero/models/match_prediction.dart';
import 'package:palpitero/models/playoff.dart';
import 'package:palpitero/utils/playoff_rounds.dart';
import 'package:palpitero/widgets/widgets.dart';

import '../helpers/test_helpers.dart';

/// Domain components are built from tokens only, so every check runs in
/// both themes (same pattern as test/design_system/components_test.dart).
final _themes = <String, (ThemeData Function(), AppTokens)>{
  'dark': (AppTheme.dark, AppTokens.dark),
  'light': (AppTheme.light, AppTokens.light),
};

Widget _app(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

BoxDecoration _cardDecorationOf(WidgetTester tester, Finder finder) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: finder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

const _participantA = PlayoffParticipant(
  userId: 'a',
  seed: 1,
  nick: 'Canarinho',
  avatarId: 'cup',
  rankingPoints: 12,
);
const _participantB = PlayoffParticipant(
  userId: 'b',
  seed: 32,
  nick: 'Hexa',
  avatarId: 'ball',
  rankingPoints: 3,
);

PublicPredictionResult _prediction({
  String userId = 'a',
  String nick = 'Canarinho',
  int points = 0,
  bool exactScore = false,
}) {
  return PublicPredictionResult(
    userId: userId,
    nick: nick,
    avatarId: 'cup',
    pick: MatchPick.home,
    predictedHomeScore: 2,
    predictedAwayScore: 1,
    points: points,
    exactScore: exactScore,
    correctPick: points > 0,
  );
}

void main() {
  for (final MapEntry(key: name, value: (theme, t)) in _themes.entries) {
    group('ScoreStepper ($name)', () {
      testWidgets('steps the value and stops at the limits', (tester) async {
        final values = <int>[];
        Widget stepper(int value) => _app(
          theme(),
          ScoreStepper(label: 'Brasil', value: value, onChanged: values.add),
        );

        await tester.pumpWidget(stepper(0));
        await tester.tap(find.byTooltip('Diminuir'));
        await tester.tap(find.byTooltip('Aumentar'));
        expect(values, [1]);

        await tester.pumpWidget(stepper(9));
        await tester.tap(find.byTooltip('Aumentar'));
        await tester.tap(find.byTooltip('Diminuir'));
        expect(values, [1, 8]);
      });

      testWidgets('disabled ignores both buttons', (tester) async {
        final values = <int>[];
        await tester.pumpWidget(
          _app(
            theme(),
            ScoreStepper(
              label: 'Brasil',
              value: 3,
              enabled: false,
              onChanged: values.add,
            ),
          ),
        );

        await tester.tap(find.byTooltip('Aumentar'));
        await tester.tap(find.byTooltip('Diminuir'));

        expect(values, isEmpty);
      });
    });

    group('DaySelector and RoundSelector ($name)', () {
      testWidgets('day selector reads "Dia N de M" and moves', (tester) async {
        final changes = <int>[];
        await tester.pumpWidget(
          _app(
            theme(),
            DaySelector(index: 0, count: 3, onChanged: changes.add),
          ),
        );

        expect(find.text('Dia 1 de 3'), findsOneWidget);
        await tester.tap(find.byTooltip('Dia anterior'));
        await tester.tap(find.byTooltip('Proximo dia'));
        expect(changes, [1]);
      });

      testWidgets('round selector selects the current round chip', (
        tester,
      ) async {
        final changes = <int>[];
        await tester.pumpWidget(
          _app(
            theme(),
            RoundSelector(
              labels: const ['RD32', 'RD16', 'Quartas'],
              index: 2,
              onChanged: changes.add,
            ),
          ),
        );

        final selected = tester.widget<AppChip>(
          find.widgetWithText(AppChip, 'Quartas'),
        );
        expect(selected.selected, isTrue);
        await tester.tap(find.byTooltip('Proxima rodada'));
        await tester.tap(find.byTooltip('Rodada anterior'));
        expect(changes, [1]);
      });
    });

    group('LeaderboardRow ($name)', () {
      testWidgets('podium entry shows the trophy and a gold rank', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(theme(), LeaderboardRow.entry(leaderboardEntries().first)),
        );

        expect(find.byTooltip('Top 3'), findsOneWidget);
        expect(tester.widget<Text>(find.text('#1')).style!.color, t.gold);
        expect(find.text('12 pts'), findsOneWidget);
        expect(find.text('4 palpites - 2 exatos'), findsOneWidget);
      });

      testWidgets('current user is a brand state card', (tester) async {
        const me = LeaderboardEntry(
          position: 7,
          userId: 'me',
          nick: 'Eu',
          avatarId: 'star',
          points: 1,
          predictionsCount: 1,
          exactScores: 0,
          isCurrentUser: true,
        );
        await tester.pumpWidget(_app(theme(), LeaderboardRow.entry(me)));

        expect(find.byTooltip('Top 3'), findsNothing);
        expect(
          tester.widget<Text>(find.text('#7')).style!.color,
          t.textPrimary,
        );
        expect(
          _cardDecorationOf(tester, find.text('Eu')).color,
          t.stateFill(t.brand),
        );
      });
    });

    group('PredictionTile ($name)', () {
      testWidgets('public exact score is a success card with points', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            PredictionTile.public(_prediction(points: 5, exactScore: true)),
          ),
        );

        expect(find.text('C'), findsOneWidget);
        expect(find.text('2 x 1'), findsOneWidget);
        expect(find.text('5 pts'), findsOneWidget);
        expect(
          _cardDecorationOf(tester, find.text('2 x 1')).color,
          t.stateFill(t.success),
        );
      });

      testWidgets('history shows the pick and no points', (tester) async {
        await tester.pumpWidget(
          _app(
            theme(),
            PredictionTile.history(
              match: futureMatch,
              prediction: savedPrediction,
            ),
          ),
        );

        expect(
          find.text('${futureMatch.homeTeam} x ${futureMatch.awayTeam}'),
          findsOneWidget,
        );
        expect(find.textContaining('Palpite: '), findsOneWidget);
        expect(find.textContaining(' pts'), findsNothing);
      });
    });

    group('AvatarBadge ($name)', () {
      testWidgets('falls back to the initial, then to a user icon', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(theme(), const AvatarBadge(name: ' hexa', onElevated: true)),
        );
        expect(find.text('H'), findsOneWidget);
        expect(
          tester
              .widget<CircleAvatar>(find.byType(CircleAvatar))
              .backgroundColor,
          t.background,
        );

        await tester.pumpWidget(_app(theme(), const AvatarBadge()));
        expect(find.byType(Text), findsNothing);
        expect(
          tester
              .widget<CircleAvatar>(find.byType(CircleAvatar))
              .backgroundColor,
          t.surfaceElevated,
        );
      });
    });

    group('Match widgets ($name)', () {
      testWidgets('round header shows the label', (tester) async {
        await tester.pumpWidget(
          _app(theme(), const RoundHeader(label: '11 jun')),
        );

        expect(find.text('11 jun'), findsOneWidget);
        expect(find.byType(Divider), findsNWidgets(2));
      });

      testWidgets('playoff status badge maps statuses to tones', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            const Column(
              children: [
                PlayoffStatusBadge(status: 'live'),
                PlayoffStatusBadge(status: 'done'),
                PlayoffStatusBadge(status: ''),
              ],
            ),
          ),
        );

        final tones = tester
            .widgetList<AppBadge>(find.byType(AppBadge))
            .map((badge) => badge.tone)
            .toList();
        expect(tones, [
          AppBadgeTone.live,
          AppBadgeTone.neutral,
          AppBadgeTone.pending,
        ]);
      });

      testWidgets('prediction card asks for the penalty winner on a draw', (
        tester,
      ) async {
        const knockout = MatchPrediction(
          fixtureId: 900,
          round: 'Round of 32',
          kickoffLabel: '28 jun, 16:00',
          kickoffAt: '2099-06-28T19:00:00Z',
          homeTeam: 'Brazil',
          awayTeam: 'France',
          status: 'NS',
        );
        final drafts = <UserMatchPrediction>[];
        await tester.pumpWidget(
          _app(
            theme(),
            PredictionCard(
              match: knockout,
              draftPrediction: null,
              savedPrediction: null,
              isSaving: false,
              isLocked: false,
              onDraftChanged: drafts.add,
              onSave: (_) {},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Em caso de penaltis, quem passa?'), findsOneWidget);
        expect(drafts.last.qualifiedPick, MatchPick.home);

        await tester.tap(find.byTooltip('Aumentar').first);
        await tester.pump();

        expect(find.text('Em caso de penaltis, quem passa?'), findsNothing);
        expect(drafts.last.homeScore, 1);
        expect(drafts.last.qualifiedPick, isNull);
      });
    });

    group('Playoff widgets ($name)', () {
      testWidgets('preview bracket advances players facing a bye', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            PlayoffBracketView.preview(
              participants: const [
                BracketParticipant(seed: 1, nick: 'Canarinho', score: 0),
                BracketParticipant(seed: 32, nick: 'Hexa', score: 0),
                BracketParticipant(seed: 16, nick: 'Sozinho', score: 0),
              ],
            ),
          ),
        );

        final slots = tester
            .widgetList<BracketSlot>(find.byType(BracketSlot))
            .toList();
        expect(slots, hasLength(32));
        bool advanced(String nick) => slots
            .firstWhere((slot) => slot.participant.nick == nick)
            .isAdvanced;
        expect(advanced('Canarinho'), isFalse);
        expect(advanced('Sozinho'), isTrue);
        expect(find.text('3/32 players'), findsOneWidget);
      });

      testWidgets('official bracket places every participant of each round', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            PlayoffBracketView.official(
              bracket: const PlayoffBracket(
                id: 'b',
                maxParticipants: 32,
                generatedAt: '2026-06-27T00:00:00Z',
                participants: [_participantA, _participantB],
                matches: [
                  PlayoffMatch(
                    id: 'rd32-1',
                    round: 'RD32',
                    roundIndex: 0,
                    position: 1,
                    status: 'finished',
                    isBye: false,
                    participantA: _participantA,
                    participantB: _participantB,
                    winnerParticipantId: 'a',
                  ),
                  PlayoffMatch(
                    id: 'rd16-1',
                    round: 'RD16',
                    roundIndex: 1,
                    position: 1,
                    status: 'pending',
                    isBye: false,
                    participantA: _participantA,
                  ),
                ],
              ),
              roundScoresByRound: const {
                'RD32': {
                  'a': PlayoffRoundScore(
                    userId: 'a',
                    nick: 'Canarinho',
                    avatarId: 'cup',
                    points: 10,
                    predictionsCount: 2,
                    exactScores: 1,
                    correctQualified: 0,
                  ),
                },
              },
            ),
          ),
        );

        expect(find.byType(BracketSlot), findsNWidgets(3));
        expect(find.text('10'), findsOneWidget);
      });

      testWidgets('matchup highlights the winner and scored predictions', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            BracketMatchup(
              match: const PlayoffMatch(
                id: 'rd32-1',
                round: 'RD32',
                roundIndex: 0,
                position: 1,
                status: 'finished',
                isBye: false,
                participantA: _participantA,
                participantB: _participantB,
                winnerParticipantId: 'a',
              ),
              scoresByUserId: const {},
              roundPredictionResults: [
                MatchPredictionResults(
                  fixtureId: 1,
                  round: 'Round of 32',
                  homeTeam: 'Brazil',
                  awayTeam: 'France',
                  status: 'FT',
                  homeScore: 2,
                  awayScore: 1,
                  predictions: [_prediction(points: 5, exactScore: true)],
                ),
              ],
            ),
          ),
        );

        expect(
          tester.widget<Text>(find.text('#1')).style!.color,
          t.brandOnSurface,
        );
        expect(
          _cardDecorationOf(tester, find.text('Canarinho').first).color,
          t.stateFill(t.brand),
        );
        expect(find.text('2 x 1 - 5 pts'), findsOneWidget);
        expect(find.text('Sem palpite'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('2 x 1 - 5 pts')).style!.color,
          t.success,
        );
      });
    });
  }

  group('Playoff rounds', () {
    test('first-round fallback pairs seeds and marks byes', () {
      final matches = buildFirstRoundFallback(const [
        _participantA,
        _participantB,
      ]);

      expect(matches, hasLength(16));
      expect(matches.first.participantA?.seed, 1);
      expect(matches.first.participantB?.seed, 32);
      expect(matches.first.isBye, isFalse);
      expect(matches[1].isBye, isTrue);
    });

    test('rounds come grouped in bracket order', () {
      PlayoffMatch match(String round, int position) => PlayoffMatch(
        id: '$round-$position',
        round: round,
        roundIndex: 0,
        position: position,
        status: 'pending',
        isBye: false,
      );

      final rounds = groupPlayoffRounds([
        match('QF', 1),
        match('RD32', 2),
        match('RD32', 1),
      ]);

      expect(rounds.map((round) => round.label), ['RD32', 'Quartas']);
      expect(rounds.first.matches.map((m) => m.position), [1, 2]);
    });

    test('fixture round names match bracket codes', () {
      expect(isSamePlayoffRound('Round of 32', 'RD32'), isTrue);
      expect(isSamePlayoffRound('Quartas', 'QF'), isTrue);
      expect(isSamePlayoffRound('Semis', 'QF'), isFalse);
    });
  });
}
