# Palpitero

App Flutter de palpites da Copa do Mundo (Firebase + backend em `api/`). Documentação geral em
[docs/README.md](docs/README.md).

## Antes de criar ou mudar uma tela ou um componente

Leia [docs/DESIGN.md](docs/DESIGN.md). Ele é a fonte de verdade do visual e vence o código se
os dois divergirem. Comece por estas seções:
- "Tela nova, passo a passo";
- "Componentes" e "Componentes de domínio" (o que já existe e quando usar);
- "Como escolher a cor certa" e "O que nunca fazer".

O essencial:
- Imports: `package:palpitero/design_system/design_system.dart` (tokens + base) e
  `package:palpitero/widgets/widgets.dart` (domínio).
- Cor só por `context.tokens.*`; texto só pelo `TextTheme` (+ `.numeric`/`.strong`);
  espaçamento `AppSpacing`, raio `AppRadii`, opacidade `AppOpacity`. Nada de número solto.
- Nada de `FilledButton`, `TextField`, `SnackBar`, `showModalBottomSheet` ou spinner do Material
  direto na tela: use `AppButton`, `AppTextField`, `AppSnackBar`, `showAppBottomSheet`, `AppLoading`.
- Componente novo vai para a tabela do `DESIGN.md`, para o catálogo (`lib/catalog/`) e ganha
  golden nos dois temas, no mesmo commit.
- Não misture mudança visual com mudança de comportamento.

## Verificação antes de commitar

```sh
dart format .
flutter analyze
dart run tool/design_lint.dart     # guardrail do design system (também roda no CI)
flutter test
flutter test test/goldens --dart-define=RUN_GOLDENS=true   # se mudou visual
```

Golden que mudou: abra a imagem e confirme que a diferença é intencional antes de rodar com
`--update-goldens`. Exceção ao lint só com `// design-lint: ignore <regra> (motivo)`.
