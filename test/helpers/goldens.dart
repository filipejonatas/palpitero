import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palpitero/theme/app_theme.dart';

/// Goldens are off by default: pixels differ between operating systems, so
/// they are generated and compared on one machine (docs/DESIGN.md,
/// "Catálogo e goldens").
///
/// ```sh
/// flutter test test/goldens --dart-define=RUN_GOLDENS=true                   # compare
/// flutter test test/goldens --dart-define=RUN_GOLDENS=true --update-goldens  # regenerate
/// ```
const runGoldens = bool.fromEnvironment('RUN_GOLDENS');

/// Each golden runs in both themes, keyed by file-name suffix: dark keeps
/// the plain name, light adds `_light`.
final goldenThemes = <String, ThemeData Function()>{
  '': AppTheme.dark,
  '_light': AppTheme.light,
};

/// Loads every font in the app's `FontManifest.json` (Inter, Phosphor,
/// Material Icons) so text renders as text instead of Ahem blocks. Called
/// once from `test/flutter_test_config.dart`.
///
/// Replaces `golden_toolkit`'s `loadAppFonts` (package discontinued).
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
    'FontManifest.json',
    (data) async => json.decode(data) as List<dynamic>,
  );

  for (final font in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(font['family'] as String);
    for (final variant in (font['fonts'] as List).cast<Map>()) {
      loader.addFont(rootBundle.load(variant['asset'] as String));
    }
    await loader.load();
  }
}

/// A golden test: skipped unless `RUN_GOLDENS` is set.
void testGolden(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, body, skip: !runGoldens);
}

/// Pumps [child] in a `MaterialApp` with [theme] on a [size] surface at
/// device pixel ratio 1, waits for images and settles.
///
/// Spinners never settle: pass [settleFor] to advance the clock by a fixed
/// time instead (deterministic, longer than any `AppDurations`).
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
  required Size size,
  Duration? settleFor,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('en')],
        theme: theme.copyWith(platform: TargetPlatform.android),
        home: Material(child: child),
      ),
    ),
  );
  await tester.pump();
  await _precacheImages(tester);
  if (settleFor == null) {
    await tester.pumpAndSettle();
  } else {
    // Two frames: the second runs what the first scheduled.
    await tester.pump(settleFor);
    await tester.pump(settleFor);
  }
}

/// Compares [finder] (default: the whole surface) with
/// `goldens/<name>.png`, next to the test file.
Future<void> expectGolden(WidgetTester tester, String name, {Finder? finder}) {
  return expectLater(
    finder ?? find.byWidgetPredicate((_) => true).first,
    matchesGoldenFile('goldens/$name.png'),
  );
}

/// Decodes every `Image` and `DecorationImage` before the screenshot, so
/// assets never show up half-loaded.
Future<void> _precacheImages(WidgetTester tester) async {
  final images = find.byType(Image, skipOffstage: false).evaluate();
  final boxes = find.byType(DecoratedBox, skipOffstage: false).evaluate();

  await tester.runAsync(() async {
    for (final element in images) {
      await precacheImage((element.widget as Image).image, element);
    }
    for (final element in boxes) {
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is BoxDecoration && decoration.image != null) {
        await precacheImage(decoration.image!.image, element);
      }
    }
  });
}

/// Reads assets without the 10 KB `loadString` cache limit (large SVGs).
class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(data.buffer.asUint8List());
  }

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}
