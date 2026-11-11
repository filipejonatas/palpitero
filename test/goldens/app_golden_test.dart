import 'package:palpitero/screens/leaderboard_screen.dart';
import 'package:palpitero/screens/login_screen.dart';
import 'package:palpitero/screens/splash_page.dart';
import 'package:palpitero/models/match_prediction.dart';
import 'package:palpitero/theme/app_theme.dart';
import 'package:palpitero/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/goldens.dart';
import '../helpers/test_helpers.dart';

/// Whole screens. Each component in every state is in
/// `components_golden_test.dart`.
void main() {
  for (final MapEntry(key: suffix, value: theme) in goldenThemes.entries) {
    _goldens(suffix, theme);
  }
}

void _goldens(String suffix, ThemeData Function() theme) {
  group('Golden tests${suffix.isEmpty ? '' : ' ($suffix)'}', () {
    testGolden('SplashPage matches iPhone 14 screenshot', (tester) async {
      // Arrange
      await pumpGolden(
        tester,
        const SplashPage(),
        theme: theme(),
        size: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await expectGolden(tester, 'splash_page_iphone_14$suffix');
    });

    testGolden('LoginPage matches screenshot', (tester) async {
      // Arrange
      await pumpGolden(
        tester,
        ProviderScope(
          child: LoginPage(
            sessionController: TestSessionController(currentUser: null),
          ),
        ),
        theme: theme(),
        size: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await expectGolden(tester, 'login_page$suffix');
    });

    testGolden('MatchCard states match screenshots', (tester) async {
      // Arrange
      await pumpGolden(
        tester,
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
        theme: theme(),
        size: const Size(390, 520),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await expectGolden(tester, 'match_card_states$suffix');
    });

    testGolden('RankingPage top 3 matches screenshot', (tester) async {
      // Arrange
      final service = MockLeaderboardService();
      when(
        () => service.loadLeaderboard(testUser),
      ).thenAnswer((_) async => leaderboardEntries());
      await pumpGolden(
        tester,
        LeaderboardScreen(
          sessionController: TestSessionController(),
          leaderboardService: service,
        ),
        theme: theme(),
        size: const Size(390, 844),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      await expectGolden(tester, 'ranking_page_top_3$suffix');
    });
  });
}
