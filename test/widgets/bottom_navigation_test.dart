import 'package:flutter/widgets.dart';
import 'package:palpitero/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BottomNavigationBar', () {
    testWidgets('should navigate to correct screen on each tab tap', (
      tester,
    ) async {
      // Arrange
      final sessionController = TestSessionController();
      await tester.pumpWidget(
        ProviderScope(
          child: PalpiteroApp(sessionController: sessionController),
        ),
      );
      await tester.tap(find.textContaining('Come'));
      await tester.pumpAndSettle();

      // Act / Assert
      expect(find.text('Fase de grupos'), findsOneWidget);

      await tester.tap(find.byTooltip('Matches'));
      await tester.pumpAndSettle();
      expect(find.text('Seus palpites'), findsOneWidget);

      await tester.tap(find.byTooltip('Ranking'));
      await tester.pumpAndSettle();
      expect(find.text('Leaderboard'), findsOneWidget);

      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Fase de grupos'), findsOneWidget);

      // Perfil não é uma aba: abre pelo botão do cabeçalho da Home.
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Fase de grupos'), findsOneWidget);
    });

    testWidgets('keeps the current route when the app rebuilds', (
      tester,
    ) async {
      // Arrange
      final sessionController = TestSessionController();
      Widget app() => ProviderScope(
        child: PalpiteroApp(sessionController: sessionController),
      );
      await tester.pumpWidget(app());
      await tester.tap(find.textContaining('Come'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ranking'));
      await tester.pumpAndSettle();

      // Act: a new widget instance with the same controller (as after a
      // theme change) must not rebuild the router.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Leaderboard'), findsOneWidget);
    });
  });
}
