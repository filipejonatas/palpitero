import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  group('AppTokens', () {
    test('both themes register their tokens', () {
      expect(AppTheme.dark().extension<AppTokens>(), AppTokens.dark);
      expect(AppTheme.light().extension<AppTokens>(), AppTokens.light);
    });

    testWidgets('context.tokens follows the active theme', (tester) async {
      late AppTokens read;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              read = context.tokens;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(read, AppTokens.light);
    });

    test('lerp interpolates between themes', () {
      final mid = AppTokens.dark.lerp(AppTokens.light, .5);
      expect(mid.brand, AppTokens.dark.brand);
      expect(mid.background, isNot(AppTokens.dark.background));
      expect(
        AppTokens.dark.lerp(AppTokens.light, 1).surface,
        AppTokens.light.surface,
      );
    });

    test('scheme mirrors the tokens', () {
      for (final (theme, tokens) in [
        (AppTheme.dark(), AppTokens.dark),
        (AppTheme.light(), AppTokens.light),
      ]) {
        expect(theme.colorScheme.error, tokens.loss);
        expect(theme.colorScheme.surface, tokens.surface);
        expect(theme.scaffoldBackgroundColor, tokens.background);
      }
    });

    for (final (name, t) in [
      ('dark', AppTokens.dark),
      ('light', AppTokens.light),
    ]) {
      group('$name contrast (WCAG AA 4.5:1)', () {
        final allSurfaces = [t.background, t.surface, t.surfaceElevated];
        final textOnAnySurface = {
          'textPrimary': t.textPrimary,
          'textSecondary': t.textSecondary,
          'brandOnSurface': t.brandOnSurface,
          'success': t.success,
          'loss': t.loss,
          'pending': t.pending,
          'gold': t.gold,
        };
        textOnAnySurface.forEach((role, color) {
          test('$role on every surface', () {
            for (final surface in allSurfaces) {
              expect(_contrast(color, surface), greaterThanOrEqualTo(4.5));
            }
          });
        });

        test('live only on background and surface', () {
          for (final surface in [t.background, t.surface]) {
            expect(_contrast(t.live, surface), greaterThanOrEqualTo(4.5));
          }
        });

        test('on-colors over their fills', () {
          expect(_contrast(t.onBrand, t.brand), greaterThanOrEqualTo(4.5));
          expect(_contrast(t.onLive, t.live), greaterThanOrEqualTo(4.5));
          expect(_contrast(t.onLoss, t.loss), greaterThanOrEqualTo(4.5));
          expect(_contrast(t.onGold, t.goldFill), greaterThanOrEqualTo(4.5));
        });
      });
    }
  });

  group('AppTypography', () {
    test('closed scale is mapped onto every Material role', () {
      final sizes = [30.0, 24.0, 16.0, 14.0, 13.0, 12.0];
      final tt = AppTheme.dark().textTheme;
      for (final style in [
        tt.displayLarge,
        tt.displayMedium,
        tt.displaySmall,
        tt.headlineLarge,
        tt.headlineMedium,
        tt.headlineSmall,
        tt.titleLarge,
        tt.titleMedium,
        tt.titleSmall,
        tt.bodyLarge,
        tt.bodyMedium,
        tt.bodySmall,
        tt.labelLarge,
        tt.labelMedium,
        tt.labelSmall,
      ]) {
        expect(sizes, contains(style!.fontSize));
      }
    });

    test('w900 only on display', () {
      for (final style in [
        AppTypography.headline,
        AppTypography.title,
        AppTypography.titleSmall,
        AppTypography.body,
        AppTypography.bodySmall,
        AppTypography.label,
        AppTypography.caption,
      ]) {
        expect(style.fontWeight, isNot(FontWeight.w900));
      }
    });
  });
}
