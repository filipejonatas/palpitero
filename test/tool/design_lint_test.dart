import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/design_lint.dart';

List<String> _rules(String source, {String path = 'lib/screens/x.dart'}) =>
    lintSource(path, source).map((issue) => issue.rule.id).toList();

void main() {
  test('lib/ não tem valores visuais avulsos', () {
    final issues = lintPaths(Directory.current, ['lib']);
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  group('regras', () {
    test('cores avulsas', () {
      expect(_rules('final c = Color(0xFF00FF00);'), ['hex-color']);
      expect(_rules('final c = Color.fromARGB(1, 2, 3, 4);'), ['hex-color']);
      expect(_rules('final c = Colors.white;'), ['material-colors']);
      expect(_rules('final c = Colors.transparent;'), isEmpty);
    });

    test('tipografia avulsa', () {
      expect(_rules('TextStyle(fontSize: 14)'), ['font-size']);
      expect(_rules('TextStyle(fontWeight: FontWeight.w800)'), ['font-weight']);
      expect(_rules("TextStyle(fontFamily: 'Roboto')"), ['font-family']);
      expect(_rules('final s = style.fontSize! * 2;'), isEmpty);
    });

    test('espaçamento, raio e opacidade numéricos', () {
      expect(_rules('EdgeInsets.all(12)'), ['numeric-spacing']);
      expect(
        _rules('EdgeInsets.fromLTRB(\n  AppSpacing.lg,\n  0,\n  3,\n  0,\n)'),
        ['numeric-spacing'],
      );
      expect(_rules('EdgeInsets.all(AppSpacing.md)'), isEmpty);
      expect(_rules('EdgeInsets.only(top: 0)'), isEmpty);
      expect(_rules('const SizedBox(height: 10)'), ['numeric-gap']);
      expect(_rules('const SizedBox(width: AppSpacing.xs)'), isEmpty);
      expect(_rules('SizedBox(height: 220, child: x)'), isEmpty);
      expect(_rules('BorderRadius.circular(10)'), ['numeric-radius']);
      expect(_rules('BorderRadius.circular(AppRadii.md)'), isEmpty);
      expect(_rules('c.withValues(alpha: .5)'), ['numeric-opacity']);
      expect(_rules('c.withValues(alpha: AppOpacity.glass)'), isEmpty);
      expect(_rules('c.withOpacity(0.3)'), ['numeric-opacity']);
      expect(_rules('BoxShadow(blurRadius: 4)'), ['raw-shadow']);
    });

    test('widgets do Material só dentro de lib/design_system/', () {
      const source = 'FilledButton(onPressed: f, child: c)';
      expect(_rules(source), ['raw-material-widget']);
      expect(_rules('ScaffoldMessenger.of(c).showSnackBar(s)'), isEmpty);
      expect(_rules('showModalBottomSheet(context: c)'), [
        'raw-material-widget',
      ]);
      expect(
        _rules(source, path: 'lib/design_system/app_button.dart'),
        isEmpty,
      );
      expect(_rules('Color(0xFF000000)', path: 'lib/design_system/x.dart'), [
        'hex-color',
      ]);
    });

    test('lib/theme/ define os tokens e fica de fora', () {
      expect(_rules('Color(0xFF000000)', path: 'lib/theme/app_tokens.dart'), [
        // nenhuma regra
      ]);
    });

    test('comentários e strings não contam', () {
      expect(_rules('// Color(0xFF000000)\nfinal a = 1;'), isEmpty);
      expect(_rules("final s = 'fontSize: 12';"), isEmpty);
      expect(_rules('/* Colors.red */'), isEmpty);
      expect(_rules("final s = '''\nEdgeInsets.all(3)\n''';"), isEmpty);
    });

    test('exceções por linha e por arquivo', () {
      expect(
        _rules(
          '// design-lint: ignore numeric-spacing (motivo)\n'
          'EdgeInsets.all(size * .22)',
        ),
        isEmpty,
      );
      expect(
        _rules('EdgeInsets.all(3) // design-lint: ignore numeric-spacing'),
        isEmpty,
      );
      // Ignorar uma regra não silencia as outras.
      expect(_rules('Color(0x1) // design-lint: ignore numeric-spacing'), [
        'hex-color',
      ]);
      expect(
        _rules(
          '// design-lint: ignore-file hex-color, font-size\n'
          'Color(0x1);\nTextStyle(fontSize: 3);\nColors.red;',
        ),
        ['material-colors'],
      );
    });

    test('aponta a linha certa', () {
      final issues = lintSource(
        'lib/screens/x.dart',
        'a;\nb;\n  final c = Colors.red;\n',
      );
      expect(issues.single.line, 3);
      expect(issues.single.snippet, 'final c = Colors.red;');
    });
  });
}
