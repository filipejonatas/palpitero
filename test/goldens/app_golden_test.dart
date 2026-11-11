import 'package:palpitero/screens/leaderboard_screen.dart';
import 'package:palpitero/screens/login_screen.dart';
import 'package:palpitero/screens/splash_page.dart';
import 'package:palpitero/models/match_prediction.dart';
import 'package:palpitero/theme/app_theme.dart';
import 'package:palpitero/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_helpers.dart';

const _runGoldens = bool.fromEnvironment('RUN_GOLDENS');

/// Each golden runs in both themes (docs/DESIGN.md, "Modo de tema").
/// Dark keeps the original file names; light adds the `_light` suffix.
final _themes = <String, ThemeData Function()>{
  '': AppTheme.dark,
  '_light': AppTheme.light,
};

void main() {
  for (final MapEntry(key: suffix, value: theme) in _themes.entries) {
    _goldens(suffix, theme);
  }
}

void _goldens(String suffix, ThemeData Function() theme) {
  group('Golden tests${suffix.isEmpty ? '' : ' ($suffix)'}', () {
    testGoldens('SplashPage matches iPhone 14 screenshot', (tester) async {
      // Arrange
      await tester.pumpWidgetBuilder(
        const SplashPage(),
        wrapper: materialAppWrapper(theme: theme()),
        surfaceSize: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'splash_page_iphone_14$suffix');
    }, skip: !_runGoldens);

    testGoldens('LoginPage matches screenshot', (tester) async {
      // Arrange
      await tester.pumpWidgetBuilder(
        ProviderScope(
          child: LoginPage(
            sessionController: TestSessionController(currentUser: null),
          ),
        ),
        wrapper: materialAppWrapper(theme: theme()),
        surfaceSize: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'login_page$suffix');
    }, skip: !_runGoldens);

    testGoldens('MatchCard states match screenshots', (tester) async {
      // Arrange
      await tester.pumpWidgetBuilder(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatchCard(match: futureMatch),
            SizedBox(height: AppSpacing.cardGap),
            MatchCard(match: lockedMatch),
            SizedBox(height: AppSpacing.cardGap),
            MatchCard(
              match: MatchPrediction(
                fixtureId: 103,
                round: 'Group Stage - 1',
                kickoffLabel: '11 jun, 16:00',
                kickoffAt: '2099-06-11T19:00:00Z',
                homeTeam: 'Argentina',
                awayTeam: 'France',
                status: 'LIVE',
                homeScore: 1,
                awayScore: 0,
              ),
            ),
          ],
        ),
        wrapper: materialAppWrapper(theme: theme()),
        surfaceSize: const Size(390, 520),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'match_card_states$suffix');
    }, skip: !_runGoldens);

    testGoldens('RankingPage top 3 matches screenshot', (tester) async {
      // Arrange
      final service = MockLeaderboardService();
      when(
        () => service.loadLeaderboard(testUser),
      ).thenAnswer((_) async => leaderboardEntries());
      await tester.pumpWidgetBuilder(
        LeaderboardScreen(
          sessionController: TestSessionController(),
          leaderboardService: service,
        ),
        wrapper: materialAppWrapper(theme: theme()),
        surfaceSize: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await screenMatchesGolden(tester, 'ranking_page_top_3$suffix');
    }, skip: !_runGoldens);
  });
}
