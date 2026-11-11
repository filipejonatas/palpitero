## O que muda

<!-- Uma ou duas frases. Mudança visual e de comportamento ficam em PRs separados. -->

## Checklist de design (telas e componentes)

Apague esta seção se o PR não toca em `lib/screens/`, `lib/widgets/` ou `lib/design_system/`.
Guia completo: [docs/DESIGN.md](../docs/DESIGN.md).

- [ ] `dart run tool/design_lint.dart` passa. Cada `// design-lint: ignore` novo tem o motivo no comentário.
- [ ] Cor só por `context.tokens.*`; cor nova entrou primeiro na paleta do `DESIGN.md`.
- [ ] Texto só por estilos do `TextTheme` (+ `.numeric`/`.strong`); nada de `w900` em texto corrido.
- [ ] Lima como texto ou ícone usa `brandOnSurface`; cor semântica só no seu significado.
- [ ] A tela usa os componentes de `design_system.dart` e `widgets.dart`; não declara widget visual privado reaproveitável.
- [ ] Componente novo (ou estado novo) está na tabela do `DESIGN.md`, no catálogo `/design-system` e com golden gerado.
- [ ] Conferido nos dois temas (claro e escuro) e na largura de celular (390 px).
- [ ] Goldens rodados localmente (`flutter test test/goldens --dart-define=RUN_GOLDENS=true`); diferenças são intencionais e estão descritas abaixo.

## Mudanças visíveis

<!-- Antes → depois, com capturas se mudar a tela. "Nenhuma" se for só refatoração. -->
