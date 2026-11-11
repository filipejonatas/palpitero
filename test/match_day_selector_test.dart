import 'package:palpitero/models/match_prediction.dart';
import 'package:palpitero/utils/match_day_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initialMatchDayIndex', () {
    test('selects the day that matches today', () {
      final days = [
        [_match(1, '2026-06-22T19:00:00Z')],
        [_match(2, '2026-06-23T19:00:00Z')],
        [_match(3, '2026-06-24T19:00:00Z')],
      ];

      expect(
        initialMatchDayIndex(days, now: DateTime.parse('2026-06-23T12:00:00Z')),
        1,
      );
    });

    test('selects the next future day when today has no matches', () {
      final days = [
        [_match(1, '2026-06-22T19:00:00Z')],
        [_match(2, '2026-06-24T19:00:00Z')],
      ];

      expect(
        initialMatchDayIndex(days, now: DateTime.parse('2026-06-23T12:00:00Z')),
        1,
      );
    });

    test('selects the last valid day after all matches ended', () {
      final days = [
        [_match(1, '2026-06-22T19:00:00Z')],
        [_match(2, '2026-06-24T19:00:00Z')],
      ];

      expect(
        initialMatchDayIndex(days, now: DateTime.parse('2026-06-25T12:00:00Z')),
        1,
      );
    });
  });

  group('grouping matches by day', () {
    test('by kickoff label keeps the date part, in order', () {
      final days = groupMatchesByKickoffLabel([
        _match(1, '2026-06-23T19:00:00Z'),
        _match(2, ''),
      ]);

      expect(days, hasLength(1));
      expect(days.single.label, '23 jun');
      expect(days.single.matches.map((m) => m.fixtureId), [1, 2]);
    });

    test('by kickoff date splits calendar days and labels them', () {
      final first = DateTime(2026, 6, 23, 12).toUtc().toIso8601String();
      final second = DateTime(2026, 6, 24, 12).toUtc().toIso8601String();
      final days = groupMatchesByKickoffDate([
        _match(1, first),
        _match(2, second),
        _match(3, first),
      ]);

      expect(days.map((day) => day.label), ['23 jun', '24 jun']);
      expect(days.first.matches.map((m) => m.fixtureId), [1, 3]);
    });
  });
}

MatchPrediction _match(int fixtureId, String kickoffAt) {
  return MatchPrediction(
    fixtureId: fixtureId,
    round: 'Group',
    kickoffLabel: '23 jun, 16:00',
    kickoffAt: kickoffAt,
    homeTeam: 'Brazil',
    awayTeam: 'Japan',
    status: 'NS',
  );
}
