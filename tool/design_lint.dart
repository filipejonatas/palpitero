// Guardrail do design system (Checkpoint 8).
//
// Procura em `lib/` valores visuais avulsos que deveriam vir dos tokens ou dos
// componentes. Roda no CI e em `test/tool/design_lint_test.dart`.
//
//   dart run tool/design_lint.dart          # verifica lib/
//   dart run tool/design_lint.dart lib/foo  # verifica só um caminho
//
// Exceção pontual (justifique no comentário):
//   // design-lint: ignore <regra> (motivo)      nesta linha ou na linha de cima
//   // design-lint: ignore-file <regra> (motivo) no arquivo inteiro
//
// Regras e onde valem: veja `designLintRules` e a seção "Guardrails" de
// docs/DESIGN.md. Sem dependências: só `dart:io`.
import 'dart:io';

/// Pastas onde os tokens são definidos: nenhuma regra vale aqui.
const _tokenDirs = ['lib/theme/'];

/// Pastas dos componentes base: podem usar os widgets do Material por baixo.
const _componentDirs = ['lib/design_system/'];

class DesignLintRule {
  const DesignLintRule({
    required this.id,
    required this.pattern,
    required this.message,
    this.allowInComponents = false,
    this.argumentsNeedNumber = false,
  });

  final String id;
  final RegExp pattern;
  final String message;

  /// Vale em `lib/design_system/`? (Os componentes podem usar Material cru.)
  final bool allowInComponents;

  /// Só acusa se os argumentos da chamada tiverem um número literal ≠ 0.
  final bool argumentsNeedNumber;
}

final designLintRules = <DesignLintRule>[
  DesignLintRule(
    id: 'hex-color',
    pattern: RegExp(r'\bColor(\.fromARGB|\.fromRGBO)?\s*\('),
    message:
        'Cor avulsa. Use context.tokens.* (crie o token no DESIGN.md antes).',
  ),
  DesignLintRule(
    id: 'material-colors',
    pattern: RegExp(r'\bColors\.(?!transparent\b)\w+'),
    message: 'Colors.* quebra um dos temas. Use context.tokens.*.',
  ),
  DesignLintRule(
    id: 'font-size',
    pattern: RegExp(r'\bfontSize\s*:'),
    message: 'Tamanho de fonte avulso. Use um estilo do TextTheme.',
  ),
  DesignLintRule(
    id: 'font-weight',
    pattern: RegExp(r'\bFontWeight\.\w+'),
    message: 'Peso avulso. Use o estilo do TextTheme ou .numeric/.strong.',
  ),
  DesignLintRule(
    id: 'font-family',
    pattern: RegExp(r'\bfontFamily\s*:|\bGoogleFonts\.'),
    message: 'A fonte vem do tema (Inter). Não defina família na tela.',
  ),
  DesignLintRule(
    id: 'numeric-spacing',
    pattern: RegExp(
      r'\bEdgeInsets(Directional)?\.(all|symmetric|only|fromLTRB|fromSTEB)\s*\(',
    ),
    argumentsNeedNumber: true,
    message: 'Espaçamento numérico. Use AppSpacing.*.',
  ),
  DesignLintRule(
    id: 'numeric-gap',
    // Só o espaçador: SizedBox com apenas height ou width (sem child).
    pattern: RegExp(r'\bSizedBox\s*\(\s*(height|width)\s*:\s*[^,()]*\)'),
    argumentsNeedNumber: true,
    message: 'Espaço numérico. Use SizedBox(height: AppSpacing.*).',
  ),
  DesignLintRule(
    id: 'numeric-radius',
    pattern: RegExp(r'\b(BorderRadius|Radius)\.circular\s*\('),
    argumentsNeedNumber: true,
    message: 'Raio numérico. Use AppRadii.*.',
  ),
  DesignLintRule(
    id: 'numeric-opacity',
    pattern: RegExp(r'\.withOpacity\s*\(|\.withValues\s*\('),
    argumentsNeedNumber: true,
    message: 'Opacidade numérica. Use AppOpacity.* ou stateFill/stateBorder.',
  ),
  DesignLintRule(
    id: 'raw-shadow',
    pattern: RegExp(r'\bBoxShadow\s*\('),
    message: 'Sombra avulsa. Use floatingShadow/glowShadow de context.tokens.',
  ),
  DesignLintRule(
    id: 'raw-material-widget',
    pattern: RegExp(
      r'\b(FilledButton|ElevatedButton|OutlinedButton|TextButton|TextField|'
      r'TextFormField|SnackBar|CircularProgressIndicator|'
      r'LinearProgressIndicator)\b(?!Theme)|\bshowModalBottomSheet\b',
    ),
    allowInComponents: true,
    message:
        'Widget do Material direto. Use AppButton, AppTextField, AppSnackBar, '
        'showAppBottomSheet ou AppLoading.',
  ),
];

class DesignLintIssue {
  const DesignLintIssue(this.path, this.line, this.rule, this.snippet);

  final String path;
  final int line;
  final DesignLintRule rule;
  final String snippet;

  @override
  String toString() => '$path:$line [${rule.id}] ${rule.message}\n    $snippet';
}

final _number = RegExp(r'(?<![\w.$])(\d+\.?\d*|\.\d+)');
final _ignoreLine = RegExp(
  r'//\s*design-lint:\s*ignore\s+([\w-]+(?:\s*,\s*[\w-]+)*)',
);
final _ignoreFile = RegExp(
  r'//\s*design-lint:\s*ignore-file\s+([\w-]+(?:\s*,\s*[\w-]+)*)',
);

/// Verifica um arquivo. [path] é relativo à raiz do projeto, com `/`.
List<DesignLintIssue> lintSource(String path, String source) {
  final normalized = path.replaceAll('\\', '/');
  if (_tokenDirs.any(normalized.startsWith)) return const [];
  final inComponents = _componentDirs.any(normalized.startsWith);

  final lines = source.split('\n');
  final fileIgnores = {
    for (final m in _ignoreFile.allMatches(source)) ..._ids(m.group(1)!),
  };
  final code = stripCommentsAndStrings(source);
  final lineStarts = <int>[0];
  for (var i = 0; i < code.length; i++) {
    if (code.codeUnitAt(i) == 0x0A) lineStarts.add(i + 1);
  }

  final issues = <DesignLintIssue>[];
  for (final rule in designLintRules) {
    if (inComponents && rule.allowInComponents) continue;
    if (fileIgnores.contains(rule.id)) continue;
    for (final match in rule.pattern.allMatches(code)) {
      if (rule.argumentsNeedNumber) {
        final args = _arguments(code, code.indexOf('(', match.start));
        if (!_hasNonZeroNumber(args)) continue;
      }
      final line = _lineOf(lineStarts, match.start);
      if (_ignoredAt(lines, line, rule.id)) continue;
      issues.add(
        DesignLintIssue(normalized, line, rule, lines[line - 1].trim()),
      );
    }
  }
  issues.sort((a, b) => a.line.compareTo(b.line));
  return issues;
}

/// Verifica todos os `.dart` sob [roots] (relativos a [projectRoot]).
List<DesignLintIssue> lintPaths(Directory projectRoot, List<String> roots) {
  final issues = <DesignLintIssue>[];
  for (final root in roots) {
    final entity = FileSystemEntity.typeSync('${projectRoot.path}/$root');
    final files = switch (entity) {
      FileSystemEntityType.file => [File('${projectRoot.path}/$root')],
      FileSystemEntityType.directory =>
        Directory('${projectRoot.path}/$root')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList(),
      _ => throw ArgumentError('Caminho não encontrado: $root'),
    };
    for (final file in files) {
      final relative = file.path
          .substring(projectRoot.path.length + 1)
          .replaceAll('\\', '/');
      issues.addAll(lintSource(relative, file.readAsStringSync()));
    }
  }
  issues.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  return issues;
}

/// Troca comentários e o conteúdo de strings por espaços, mantendo as quebras
/// de linha (e portanto os números de linha).
String stripCommentsAndStrings(String source) {
  final out = StringBuffer();
  var i = 0;
  void blank(int end) {
    for (; i < end && i < source.length; i++) {
      out.write(source[i] == '\n' ? '\n' : ' ');
    }
  }

  while (i < source.length) {
    final rest = source.substring(
      i,
      i + 3 > source.length ? source.length : i + 3,
    );
    if (rest.startsWith('//')) {
      final end = source.indexOf('\n', i);
      blank(end == -1 ? source.length : end);
    } else if (rest.startsWith('/*')) {
      final end = source.indexOf('*/', i + 2);
      blank(end == -1 ? source.length : end + 2);
    } else if (rest.startsWith("'''") || rest.startsWith('"""')) {
      final end = source.indexOf(rest, i + 3);
      blank(end == -1 ? source.length : end + 3);
    } else if (rest.startsWith("'") || rest.startsWith('"')) {
      final quote = rest[0];
      final raw = i > 0 && source[i - 1] == 'r';
      var j = i + 1;
      while (j < source.length && source[j] != quote && source[j] != '\n') {
        j += (!raw && source[j] == r'\') ? 2 : 1;
      }
      blank(j + 1);
    } else {
      out.write(source[i]);
      i++;
    }
  }
  return out.toString();
}

/// Texto entre o `(` em [open] e o `)` correspondente.
String _arguments(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    final c = code[i];
    if (c == '(') depth++;
    if (c == ')' && --depth == 0) return code.substring(open + 1, i);
  }
  return code.substring(open + 1);
}

bool _hasNonZeroNumber(String args) =>
    _number.allMatches(args).any((m) => double.tryParse(m.group(1)!) != 0);

int _lineOf(List<int> lineStarts, int offset) {
  var lo = 0, hi = lineStarts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (lineStarts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo + 1;
}

bool _ignoredAt(List<String> lines, int line, String ruleId) {
  for (final index in [line - 1, line - 2]) {
    if (index < 0) continue;
    final m = _ignoreLine.firstMatch(lines[index]);
    if (m != null && _ids(m.group(1)!).contains(ruleId)) return true;
  }
  return false;
}

Iterable<String> _ids(String list) => list.split(',').map((s) => s.trim());

void main(List<String> args) {
  final roots = args.isEmpty ? ['lib'] : args;
  final issues = lintPaths(Directory.current, roots);
  if (issues.isEmpty) {
    stdout.writeln('design-lint: nenhum valor avulso em ${roots.join(', ')}.');
    return;
  }
  issues.forEach(stderr.writeln);
  stderr.writeln(
    '\ndesign-lint: ${issues.length} problema(s). Regras e exceções na seção '
    '"Guardrails" de docs/DESIGN.md.',
  );
  exitCode = 1;
}
