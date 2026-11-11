import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/design_system/design_system.dart';

/// Base components read only tokens, so every check runs in both themes.
final _themes = <String, (ThemeData Function(), AppTokens)>{
  'dark': (AppTheme.dark, AppTokens.dark),
  'light': (AppTheme.light, AppTokens.light),
};

Widget _app(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

BoxDecoration _decorationOf(WidgetTester tester, Finder finder) {
  final container = tester.widget<Container>(
    find.ancestor(of: finder, matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  for (final MapEntry(key: name, value: (theme, t)) in _themes.entries) {
    group('AppButton ($name)', () {
      testWidgets('primary wraps a FilledButton and calls onPressed', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(theme(), AppButton(label: 'Salvar', onPressed: () => taps++)),
        );

        await tester.tap(find.text('Salvar'));

        expect(find.byType(FilledButton), findsOneWidget);
        expect(taps, 1);
      });

      testWidgets('loading disables the button and shows a spinner', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(
            theme(),
            AppButton(
              label: 'Salvando...',
              icon: const Icon(Icons.save),
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        );

        await tester.tap(find.text('Salvando...'));

        // FilledButton.icon builds a private subclass: match by `is`.
        final button = tester.widget<FilledButton>(
          find.byWidgetPredicate((widget) => widget is FilledButton),
        );
        expect(button.onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
        expect(taps, 0);
      });

      testWidgets('variants map to the Material buttons', (tester) async {
        await tester.pumpWidget(
          _app(
            theme(),
            Column(
              children: [
                AppButton.secondary(label: 'Google', onPressed: () {}),
                AppButton.outline(label: 'Sair', onPressed: () {}),
                AppButton.text(label: 'Palpites', onPressed: () {}),
              ],
            ),
          ),
        );

        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
        final secondary = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(
          secondary.style!.backgroundColor!.resolve({}),
          t.surfaceElevated,
        );
      });

      testWidgets('text button uses brandOnSurface, never raw lima', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(theme(), AppButton.text(label: 'Palpites', onPressed: () {})),
        );

        final style = Theme.of(
          tester.element(find.byType(TextButton)),
        ).textButtonTheme.style!;
        expect(style.foregroundColor!.resolve({}), t.brandOnSurface);
      });

      testWidgets('expands to the full width by default', (tester) async {
        await tester.pumpWidget(
          _app(theme(), AppButton(label: 'OK', onPressed: () {})),
        );

        expect(
          tester.getSize(find.byType(FilledButton)),
          const Size(800 - 32, AppSizes.buttonHeight),
        );
      });
    });

    group('AppCard ($name)', () {
      testWidgets('surface card has surface fill and subtle border', (
        tester,
      ) async {
        await tester.pumpWidget(_app(theme(), const AppCard(child: Text('x'))));

        final decoration = _decorationOf(tester, find.text('x'));
        expect(decoration.color, t.surface);
        expect((decoration.border! as Border).top.color, t.borderSubtle);
      });

      testWidgets('elevated card has no border', (tester) async {
        await tester.pumpWidget(
          _app(theme(), const AppCard.elevated(child: Text('x'))),
        );

        final decoration = _decorationOf(tester, find.text('x'));
        expect(decoration.color, t.surfaceElevated);
        expect(decoration.border, isNull);
      });

      testWidgets('highlight uses the state fill and border', (tester) async {
        await tester.pumpWidget(
          _app(theme(), AppCard(highlight: t.success, child: const Text('x'))),
        );

        final decoration = _decorationOf(tester, find.text('x'));
        expect(decoration.color, t.stateFill(t.success));
        expect(
          (decoration.border! as Border).top.color,
          t.stateBorder(t.success),
        );
      });

      testWidgets('onTap makes it tappable', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(theme(), AppCard(onTap: () => taps++, child: const Text('x'))),
        );

        await tester.tap(find.text('x'));

        expect(taps, 1);
      });
    });

    group('AppBadge ($name)', () {
      testWidgets('each tone uses its semantic color', (tester) async {
        final expected = {
          AppBadgeTone.live: t.live,
          AppBadgeTone.pending: t.pending,
          AppBadgeTone.success: t.success,
          AppBadgeTone.loss: t.loss,
          AppBadgeTone.gold: t.gold,
        };
        for (final MapEntry(key: tone, value: color) in expected.entries) {
          await tester.pumpWidget(
            _app(theme(), AppBadge(label: tone.name, tone: tone)),
          );

          final text = tester.widget<Text>(find.text(tone.name));
          expect(text.style!.color, color, reason: tone.name);
          expect(
            _decorationOf(tester, find.text(tone.name)).color,
            t.stateFill(color),
          );
        }
      });

      testWidgets('neutral tone keeps primary text', (tester) async {
        await tester.pumpWidget(
          _app(
            theme(),
            const AppBadge(label: 'FT', tone: AppBadgeTone.neutral),
          ),
        );

        expect(
          tester.widget<Text>(find.text('FT')).style!.color,
          t.textPrimary,
        );
      });

      testWidgets('points pill: lima when highlighted, quiet otherwise', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            const Column(
              children: [
                AppBadge.points(12),
                AppBadge.points(0, highlighted: false),
              ],
            ),
          ),
        );

        expect(_decorationOf(tester, find.text('12 pts')).color, t.brand);
        expect(
          tester.widget<Text>(find.text('12 pts')).style!.color,
          t.onBrand,
        );
        expect(_decorationOf(tester, find.text('0 pts')).color, t.background);
        expect(
          tester.widget<Text>(find.text('0 pts')).style!.color,
          t.textSecondary,
        );
      });
    });

    group('AppChip ($name)', () {
      testWidgets('selected chip is lima with onBrand text', (tester) async {
        await tester.pumpWidget(
          _app(
            theme(),
            const Row(
              children: [
                AppChip(label: 'Oitavas', selected: true),
                AppChip(label: 'Quartas'),
              ],
            ),
          ),
        );

        expect(
          tester.widget<Text>(find.text('Oitavas')).style!.color,
          t.onBrand,
        );
        expect(
          tester.widget<Text>(find.text('Quartas')).style!.color,
          t.textPrimary,
        );
      });
    });

    group('States ($name)', () {
      testWidgets('empty state shows the message in a card', (tester) async {
        await tester.pumpWidget(
          _app(theme(), const AppEmptyState(message: 'Nada aqui.')),
        );

        expect(find.text('Nada aqui.'), findsOneWidget);
        expect(find.byType(AppCard), findsOneWidget);
      });

      testWidgets('error state offers retry only when given', (tester) async {
        var retries = 0;
        await tester.pumpWidget(
          _app(theme(), const AppErrorState(message: 'Falhou.')),
        );
        expect(find.text('Tentar novamente'), findsNothing);

        await tester.pumpWidget(
          _app(
            theme(),
            AppErrorState(message: 'Falhou.', onRetry: () => retries++),
          ),
        );
        await tester.tap(find.text('Tentar novamente'));

        expect(retries, 1);
      });

      testWidgets('loading shows a spinner in brandOnSurface', (tester) async {
        await tester.pumpWidget(_app(theme(), const AppLoading()));

        final context = tester.element(find.byType(CircularProgressIndicator));
        expect(
          Theme.of(context).progressIndicatorTheme.color,
          t.brandOnSurface,
        );
      });
    });

    group('Feedback ($name)', () {
      testWidgets('error snackbar uses error fill and onLoss text', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            Builder(
              builder: (context) => AppButton(
                label: 'Erro',
                onPressed: () => AppSnackBar.error(context, 'Deu ruim.'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Erro'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, t.error);
        expect(
          tester.widget<Text>(find.text('Deu ruim.')).style!.color,
          t.onLoss,
        );
      });

      testWidgets('bottom sheet opens on surface with a drag handle', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            theme(),
            Builder(
              builder: (context) => AppButton(
                label: 'Abrir',
                onPressed: () => showAppBottomSheet<void>(
                  context: context,
                  builder: (_) => const Text('Conteúdo'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Conteúdo'), findsOneWidget);
        final sheetTheme = Theme.of(
          tester.element(find.text('Conteúdo')),
        ).bottomSheetTheme;
        expect(sheetTheme.modalBackgroundColor, t.surface);
        expect(sheetTheme.showDragHandle, isTrue);
      });
    });

    group('AppTextField ($name)', () {
      testWidgets('limits length without showing a counter', (tester) async {
        await tester.pumpWidget(
          _app(theme(), const AppTextField(hintText: 'Nick', maxLength: 3)),
        );

        await tester.enterText(find.byType(TextField), 'abcdef');
        await tester.pump();

        expect(find.text('abc'), findsOneWidget);
        expect(find.textContaining('/3'), findsNothing);
      });
    });
  }
}
