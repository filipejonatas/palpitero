# Plano de refatoração: Design System do Palpitero

Objetivo: ter uma identidade visual única e consistente, com tokens e componentes
reutilizáveis, para criar telas novas sem quebrar o visual.

**Regras de trabalho**
- Um checkpoint = uma branch (`ds/cp-N-nome`) = um PR/commit revisável.
- Ao fim de cada checkpoint: `flutter analyze`, `flutter test` e goldens passando.
- Não misturar refatoração visual com mudança de comportamento.
- Marcar as caixas conforme for concluindo.

**Estado de partida (auditoria)**
- `lib/theme/app_theme.dart` já tem `AppColors`, `AppRadii` e `ThemeData` completo.
- Fonte `Inter` configurada no tema, mas não declarada no `pubspec.yaml`.
- 7 cores fora dos tokens nas telas + 6 em `avatar_option.dart`; 12 tamanhos de fonte; sem escala de espaçamento.
- Telas grandes com widgets privados: `playoff_matchups_screen` (1075 linhas), `playoff_screen` (1019), `predictions_screen` (765).
- Só 4 arquivos em `lib/widgets/`.

---

## Checkpoint 0: Baseline e rede de segurança
**Objetivo:** saber que o app e os testes funcionam antes de mexer.
- [ ] `flutter pub get`, `flutter analyze`, `flutter test` rodando (registrar falhas pré-existentes).
- [ ] Firebase novo configurado (`flutterfire configure`) ou testes cobertos por mocks.
- [ ] Goldens atuais gerados/atualizados (`flutter test --update-goldens`) como referência visual.
- [ ] Capturas de tela de cada tela (antes) em `docs/before/`.

**Pronto quando:** análise limpa e testes verdes, ou lista de falhas conhecidas anotada.

## Checkpoint 1: Identidade e decisões de base
**Objetivo:** decidir o que o Palpitero é visualmente, antes de codar tokens.
- [ ] Definir paleta final (manter fundo `#0D0D0D` e lima `#C6F135`, ou redefinir).
- [ ] Definir tom: raios, densidade, peso tipográfico (hoje `w900` é muito usado).
- [ ] Definir cores semânticas: `success/win`, `loss`, `pending`, `live`, `gold`.
- [ ] Decidir tema escuro apenas ou claro + escuro.
- [ ] Opcional: explorar telas com Stitch/Claude como referência visual.

**Entrega:** seção "Identidade" neste arquivo (ou `DESIGN.md`) com paleta e regras.

## Checkpoint 2: Fonte e fundação do tema
**Objetivo:** a tipografia realmente renderizar como projetada.
- [ ] Declarar a Inter (assets em `assets/fonts/` + `pubspec.yaml`, ou `google_fonts`).
- [ ] Conferir em aparelho real que a fonte carregou.
- [ ] Revisar `ColorScheme` completo (hoje só alguns papéis definidos).

**Arquivos:** `pubspec.yaml`, `lib/theme/app_theme.dart`.

## Checkpoint 3: Tokens
**Objetivo:** todo valor visual vive em um só lugar.
- [ ] `AppColors`: adicionar semânticos (`border`, `overlay`, `gold`, `success`, `win`, `loss`, `pending`) e cores de avatar.
- [ ] `AppSpacing`: escala (4, 8, 12, 16, 20, 24, 32; remover 7, 10, 14, 18, 22 se possível).
- [ ] `AppTypography`: escala fechada (ex.: caption 12, body 14/16, title 20/22, display 28/30) no `TextTheme`.
- [ ] `AppRadii`: incluir os raios avulsos (8, 32, 40) ou eliminá-los.
- [ ] `AppShadows`, `AppDurations` (animações) e opacidades padrão (`.06`, `.08`, `.12`).
- [ ] Expor via `ThemeExtension` (`context.tokens`) para acesso curto nas telas.

**Pronto quando:** tokens documentados e `app_theme.dart` sem números mágicos.

## Checkpoint 4: Migrar telas para os tokens
**Objetivo:** remover valores avulsos das telas, uma tela por vez.
- [ ] `login_screen` e `splash_page` (cores `#FFD700`, `#111111`, `#2A2A2A`, `#555555`).
- [ ] `predictions_screen` (rosa `#E45CFF` do botão "Salvar dia").
- [ ] `models/avatar_option.dart` (cores dos avatares).
- [ ] `Colors.white/black` com alpha viram `AppColors.border/overlay`.
- [ ] `fontSize`/`FontWeight` inline viram estilos do `TextTheme`.
- [ ] `EdgeInsets`/`SizedBox` viram `AppSpacing`; o `120` da barra de navegação vira constante nomeada.
- [ ] Goldens revisados a cada tela (diferença visual deve ser intencional).

**Pronto quando:** `grep "Color(0x"` e `grep "fontSize:"` fora do tema retornam zero.

## Checkpoint 5: Componentes base
**Objetivo:** blocos reutilizáveis que só leem tokens.
- [ ] `AppButton` (primário, secundário, outline; estados loading/desabilitado).
- [ ] `AppCard`, `AppChip`, `AppTextField`, `AppBadge` (ao vivo, status do palpite).
- [ ] `AppSectionHeader`, `AppEmptyState` (`_SurfaceMessage`), `AppLoading`, `AppErrorState`.
- [ ] `AppBottomSheet`/diálogos padronizados e `AppSnackBar`.
- [ ] Substituir usos nas telas.

**Pasta:** `lib/widgets/` (ou `lib/design_system/`).

## Checkpoint 6: Componentes de domínio
**Objetivo:** extrair os widgets privados das telas gigantes.
- [ ] `MatchCard` (revisar `lib/widgets/match_card.dart`).
- [ ] `ScoreStepper` (palpite de 0 a 9), `PredictionTile`.
- [ ] `LeaderboardRow` + `AvatarBadge` (revisar).
- [ ] `RoundHeader`, `BracketMatchup`, `DaySelector`.
- [ ] Reduzir `playoff_matchups_screen`, `playoff_screen` e `predictions_screen` a composição de componentes.

**Pronto quando:** nenhuma tela passa de ~400 linhas e não há widget visual duplicado.

## Checkpoint 7: Catálogo e testes visuais
**Objetivo:** ver e proteger cada componente em todos os estados.
- [ ] Widgetbook (ou tela `/design-system` só em debug) com todos os componentes.
- [ ] Goldens por componente (normal, desabilitado, carregando, erro).
- [ ] Teste de contraste das cores de texto sobre as superfícies (acessibilidade).

## Checkpoint 8: Guardrails e documentação
**Objetivo:** impedir regressão e orientar quem (ou qual IA) criar telas novas.
- [ ] Regra de lint proibindo `Color(0x…)`, `fontSize:` e `EdgeInsets` numéricos fora do design system (`custom_lint` ou script de CI).
- [ ] `DESIGN.md`: princípios, tokens, quando usar cada componente, o que nunca fazer.
- [ ] Checklist de PR para telas novas.
- [ ] Rodar o lint no CI (`.github/`).

## Checkpoint 9 (opcional): Performance ligada ao design
**Objetivo:** ganhos de desempenho identificados na auditoria, depois do design estável.
- [ ] `GoRouter` criado uma vez (hoje recriado no `build` de `PalpiteroApp`).
- [ ] Listas de jogos com `ListView.builder`/slivers.
- [ ] Bandeiras SVG (48 arquivos, 484 KB) otimizadas ou convertidas para WebP/PNG.
- [ ] Avaliar o `BackdropFilter` da barra de navegação.
- [ ] Medir antes e depois em aparelho real (DevTools, modo profile).
