import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    for (final (name, theme) in [
      ('dark', AppTheme.dark()),
      ('light', AppTheme.light()),
    ]) {
      test('$name theme uses Inter in every text style', () {
        final styles = [
          theme.textTheme.displayLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.titleLarge,
          theme.textTheme.titleMedium,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.labelLarge,
          theme.textTheme.labelSmall,
        ];
        for (final style in styles) {
          expect(style?.fontFamily, AppTheme.fontFamily);
        }
      });

      test('$name theme does not fall back to white outlines', () {
        final scheme = theme.colorScheme;
        expect(scheme.outline, isNot(scheme.onSurface));
        expect(scheme.outlineVariant, isNot(scheme.onSurface));
        expect(scheme.surfaceTint, Colors.transparent);
      });
    }

    test('dark and light share the brand fill', () {
      expect(AppTheme.dark().colorScheme.primary, const Color(0xFFC6F135));
      expect(AppTheme.light().colorScheme.primary, const Color(0xFFC6F135));
      expect(AppTheme.dark().brightness, Brightness.dark);
      expect(AppTheme.light().brightness, Brightness.light);
    });

    testWidgets('Inter is bundled and renders (not the Ahem fallback)', (
      tester,
    ) async {
      // Ahem draws every glyph as a square as wide as the font size, so
      // "iiii" at 20px would measure 80px. Inter's "i" is much narrower.
      const key = Key('probe');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Material(
            child: Center(
              child: Text('iiii', key: key, style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(key)).width, lessThan(40));
    });
  });
}
