import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/catalog/design_system_catalog_screen.dart';
import 'package:palpitero/design_system/design_system.dart';

/// The catalog runs in CI (goldens don't): every section must build
/// without layout errors in both themes, at phone width.
void main() {
  test('section ids are unique (they name the golden files)', () {
    final ids = catalogSections.map((section) => section.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  for (final (name, theme) in [
    ('dark', AppTheme.dark),
    ('light', AppTheme.light),
  ]) {
    group('catalog sections ($name)', () {
      for (final section in catalogSections) {
        testWidgets(section.title, (tester) async {
          tester.view.physicalSize = const Size(390, 3000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: theme(),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: CatalogSectionView(section: section),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));

          expect(tester.takeException(), isNull);
          expect(find.text(section.title), findsOneWidget);
        });
      }
    });
  }

  group('DesignSystemCatalogScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const DesignSystemCatalogScreen(),
        ),
      );
      await tester.pump();
    }

    testWidgets('group chips filter the sections', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Cores'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppChip, 'Domínio'));
      await tester.pump();

      expect(find.text('Cores'), findsNothing);
      expect(find.text('MatchCard'), findsOneWidget);
    });

    testWidgets('theme button cycles system -> light -> dark', (tester) async {
      await pumpScreen(tester);
      Brightness brightness() =>
          Theme.of(tester.element(find.text('Design system'))).brightness;

      expect(brightness(), Brightness.dark);
      await tester.tap(find.byTooltip('Tema: sistema'));
      await tester.pump();
      expect(brightness(), Brightness.light);
      await tester.tap(find.byTooltip('Tema: claro'));
      await tester.pump();
      expect(brightness(), Brightness.dark);
      expect(find.byTooltip('Tema: escuro'), findsOneWidget);
    });
  });
}
