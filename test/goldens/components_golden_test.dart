import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/catalog/design_system_catalog_screen.dart';
import 'package:palpitero/design_system/design_system.dart';

import '../helpers/goldens.dart';

/// One golden per catalog section (`/design-system`), in both themes. The
/// section shows every state of the component (normal, disabled, loading,
/// error...), so a visual change in any state shows up here.
///
/// Files: `goldens/components/<section id>[_light].png`.
void main() {
  for (final MapEntry(key: suffix, value: theme) in goldenThemes.entries) {
    group('Component goldens${suffix.isEmpty ? '' : ' ($suffix)'}', () {
      for (final section in catalogSections) {
        testGolden(section.title, (tester) async {
          const boundary = Key('section');
          await pumpGolden(
            tester,
            Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: boundary,
                child: Builder(
                  builder: (context) => ColoredBox(
                    color: context.tokens.background,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: CatalogSectionView(section: section),
                    ),
                  ),
                ),
              ),
            ),
            theme: theme(),
            // Phone width; tall enough for the longest section. Only the
            // section itself is captured.
            size: const Size(390, 3000),
            // Some sections show a loading spinner, which never settles.
            settleFor: const Duration(seconds: 1),
          );

          await expectGolden(
            tester,
            'components/${section.id}$suffix',
            finder: find.byKey(boundary),
          );
        });
      }

      // Snackbars and sheets open over the screen, so they are captured
      // on a whole (small) screen after being shown.
      testGolden('AppSnackBar', (tester) async {
        await pumpGolden(
          tester,
          const Scaffold(),
          theme: theme(),
          size: const Size(390, 160),
        );
        final context = tester.element(find.byType(Scaffold));

        AppSnackBar.info(context, 'Palpite salvo.');
        await tester.pumpAndSettle();
        await expectGolden(tester, 'components/app_snack_bar_info$suffix');

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        AppSnackBar.error(context, 'Não foi possível salvar o palpite.');
        await tester.pumpAndSettle();
        await expectGolden(tester, 'components/app_snack_bar_error$suffix');
      });

      testGolden('showAppBottomSheet', (tester) async {
        await pumpGolden(
          tester,
          const Scaffold(),
          theme: theme(),
          size: const Size(390, 480),
        );

        showAppBottomSheet<void>(
          context: tester.element(find.byType(Scaffold)),
          builder: (_) => const CatalogSheetContent(),
        );
        await tester.pumpAndSettle();

        await expectGolden(tester, 'components/app_bottom_sheet$suffix');
      });
    });
  }
}
