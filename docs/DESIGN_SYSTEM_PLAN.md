# Plano de refatoração: Design System do Palpitero

Objetivo: ter uma identidade visual única e consistente, com tokens e componentes
reutilizáveis, para criar telas novas sem quebrar o visual.

**Regras de trabalho**
- Um checkpoint = um commit direto na `main` (mensagem `ds(cp-N): ...`). Branch só se o checkpoint for longo (ex.: CP4, CP6).
- Antes de cada push: `flutter analyze`, `dart format`, `flutter test` e goldens passando.
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
Ambiente: Flutter 3.35.1 / Dart 3.9.0 (Windows).

- [x] `flutter pub get`, `flutter analyze`, `flutter test` rodando (registrar falhas pré-existentes).
- [x] Firebase novo configurado (`flutterfire configure`) ou testes cobertos por mocks.
      Projeto `palpitero-620eb` (web, android, ios). Testes seguem usando mocks.
- [x] Goldens atuais gerados/atualizados (`flutter test --update-goldens`) como referência visual.
      3 de 4 ok no CP0; o do Login fechou no Checkpoint 2 (veja 0.4).
- [ ] Capturas de tela de cada tela (antes) em `docs/before/`.

### Passo a passo

**0.1 Dependências e análise** ✅
```sh
flutter pub get
flutter analyze
dart format --output=none --set-exit-if-changed .   # mesmo passo do CI
```
- `analyze`: 1 aviso (`info`), aceito por enquanto: `DropdownButtonFormField.value` está
  depreciado em `playoff_matchups_screen.dart:438` (trocar por `initialValue` no Checkpoint 6).
- `format`: 6 arquivos fora do padrão faziam o CI falhar. Corrigido com `dart format lib test`.
- `pub get`: 1 pacote descontinuado (`golden_toolkit`). Decidir no Checkpoint 7 se migra
  para `alchemist` ou para os `matchesGoldenFile` nativos.

**0.2 Testes unitários e de widget** ✅
```sh
flutter test
```
- Situação inicial: 63 passando, 4 pulados (goldens), **2 falhando**.
- Causa: `widget_test.dart` e `bottom_navigation_test.dart` procuravam uma aba `Profile`, mas
  o perfil agora abre pelo botão "Perfil" no cabeçalho da Home (`context.push('/profile')`).
  Os testes foram ajustados para esse fluxo; o app não mudou.
- `widget_test.dart` deixou de verificar o nick dentro do Ranking: em `PalpiteroApp` o
  `LeaderboardService` é o real (Firebase). Esse conteúdo continua coberto com mock em
  `test/widgets/leaderboard_screen_test.dart`.
- Situação final: **65 passando, 4 pulados, 0 falhando**.

**0.3 Goldens (referência visual)** ⚠️ parcial
```sh
# goldens ficam desligados por padrão (flag RUN_GOLDENS)
flutter test test/goldens --update-goldens --dart-define=RUN_GOLDENS=true   # gerar
flutter test test/goldens --dart-define=RUN_GOLDENS=true                    # comparar
```
- Imagens em `test/goldens/goldens/`: `splash_page_iphone_14`, `match_card_states`,
  `ranking_page_top_3` (ok) e `login_page` (falha, veja 0.4).
- Corrigido no teste: `LoginPage` virou `ConsumerStatefulWidget` e precisava de `ProviderScope`.
- Goldens gerados no Windows podem diferir dos gerados no Linux. Gerar e comparar sempre no
  mesmo sistema (por enquanto, local; o CI não roda goldens).

**0.4 Achado: a fonte não renderiza nos testes** (confirma a auditoria)
- O tema pede `Inter`, que não está no `pubspec.yaml`. O `loadAppFonts()` não a encontra e
  o texto vira blocos (fonte Ahem) nos goldens. As imagens atuais servem para cor, layout e
  espaçamento, não para tipografia.
- O golden do Login falha com `RenderFlex overflowed by 62 pixels` no botão
  "Continuar com o Google" (`login_screen.dart:424`), porque o texto em blocos fica mais largo
  que com a fonte real. **Ação:** declarar a Inter no Checkpoint 2 e regenerar **todos** os
  goldens; esse passa a ser o baseline real.

**0.5 Firebase e app rodando** ✅ Firebase configurado (`palpitero-620eb`)
- `lib/firebase_options.dart` gerado com web, android e ios. `android/app/google-services.json`
  existe localmente, mas está no `.gitignore`.
- Pendente: o job `build` do CI roda `flutter build apk` e o Gradle aplica o plugin
  `google-services`; sem esse arquivo no CI, o build Android falha (já era assim antes).
  Resolver gerando o arquivo no CI a partir de um secret.
- iOS: falta `GoogleService-Info.plist` no Xcode e a URL scheme `REVERSED_CLIENT_ID` no
  `Info.plist` (exige Mac).

Histórico da decisão:
- `lib/firebase_options.dart` é um placeholder que lança `UnsupportedError`. Sem ele, o app
  para na Splash com "Não foi possível iniciar o app".
- Opção A (app real): `dart pub global activate flutterfire_cli` e depois
  `flutterfire configure --project=<projeto>`. Também é preciso o `.env` (copiar de
  `.env.example`: `API_BASE_URL`, chave do reCAPTCHA do App Check) e
  `scripts/run-web.ps1` ou `scripts/run-local.ps1`.
- Opção B (sem Firebase): um teste de captura que renderiza cada tela com mocks
  (`TestSessionController`, services mockados), já com uma fonte real carregada.

**0.6 Capturas "antes" em `docs/before/`** ⏳
- Telas: splash, login, home, matches (palpites), ranking, profile, playoff, playoff
  confrontos, results.
- Tamanho padrão 390×844 (iPhone 14), nome `NN-tela.png` (ex.: `01-splash.png`).
- Via A: capturas manuais no Chrome (DevTools, modo dispositivo) ou no emulador.
- Via B: gerar com o teste de captura de 0.5.

**0.7 Fechar o checkpoint**
- `flutter analyze`, `dart format`, `flutter test` e os goldens (exceto o Login) passando.
- Commit na `main` (feito em `b566b91`).

**Pronto quando:** análise limpa e testes verdes, ou lista de falhas conhecidas anotada.

## Checkpoint 1: Identidade e decisões de base
**Objetivo:** decidir o que o Palpitero é visualmente, antes de codar tokens.
- [x] Definir paleta final: mantidos fundo `#0D0D0D` e lima `#C6F135` como única cor de marca.
- [x] Definir tom: raios em escala (8/14/24/32/pill), densidade confortável, hierarquia de
      peso (`w900` só em números e destaque; `w700` títulos; `w500` rótulos; `w400` corpo).
- [x] Definir cores semânticas: `success/win`, `loss/error`, `pending`, `live`, `gold`,
      com contraste WCAG AA verificado nos dois temas.
- [x] Decidir tema: **claro + escuro**, padrão seguindo o sistema.
- [ ] Opcional: explorar telas com Stitch/Claude como referência visual (não feito).

**Entrega:** ✅ seção "Identidade" em [`DESIGN.md`](DESIGN.md).

**Impacto de "claro + escuro" nos próximos checkpoints**
- CP2: criar `AppTheme.light()` e `themeMode: ThemeMode.system` no `MaterialApp`.
- CP3: tokens de cor por tema (`ThemeExtension` com `lerp`), não `static const`; `AppColors`
  estático deixa de ser usado nas telas.
- CP4: telas não podem usar `Colors.white/black` direto (quebra no claro).
- CP7: goldens e teste de contraste nos dois temas.
- Fora do design system: seletor manual de tema no Perfil (mudança de comportamento).

## Checkpoint 2: Fonte e fundação do tema
**Objetivo:** a tipografia realmente renderizar como projetada.
- [x] Declarar a Inter (assets em `assets/fonts/` + `pubspec.yaml`, ou `google_fonts`).
- [ ] Conferir em aparelho real que a fonte carregou.
- [x] Revisar `ColorScheme` completo (hoje só alguns papéis definidos).
- [x] `AppTheme.light()` criado e ligado no `MaterialApp` (`theme`/`darkTheme`/`themeMode`).
- [x] Todos os goldens regenerados com a fonte real (novo baseline, inclusive o Login).

**Arquivos:** `pubspec.yaml`, `assets/fonts/`, `lib/theme/app_theme.dart`, `lib/main.dart`.

**Decisões e achados**
- **Fonte empacotada, não `google_fonts`:** funciona offline, no primeiro frame e nos testes
  (`loadAppFonts()` lê o `FontManifest`). Inter 4.1 estática (`rsms/inter`), licença OFL em
  `assets/fonts/OFL.txt`. Pesos 400/500/700/900 da escala + 800, que as telas ainda usam
  (9 usos); remover o arquivo `Inter-ExtraBold.ttf` ao fim do CP4. Custo: ~2 MB.
- **`themeMode` fica `dark` por enquanto** (`AppTheme.mode`). O tema claro já existe, mas as
  telas leem `AppColors` estático (escuro); ligar `ThemeMode.system` agora quebraria o visual
  no claro. Vira `system` no fim do CP4.
- **`ColorScheme` completo**, construído de uma paleta privada por tema (valores do
  `DESIGN.md`). Antes, `outline`/`outlineVariant` caíam em branco puro e
  `secondaryContainer` no verde `#00C896`. Mudanças visíveis (intencionais):
  - `SegmentedButton` (pênaltis em `predictions_screen`): seleção verde vira lima, borda
    branca vira `borderStrong`.
  - `colorScheme.error` passa de `live` (`#FF3B30`) para `loss` (`#FF6B5E`); bordas de erro
    em inputs definidas.
  - `surfaceTint` transparente (sem véu lima em superfícies elevadas); `surfaceContainerHigh*`
    = `surfaceElevated` (switch, diálogos, menus).
  - Texto de `onPrimary` passa de `#000000` para `onBrand` `#0D0D0D`.
- **Teste frágil corrigido:** em `predictions_screen_test.dart`, o finder do botão de
  confirmar pegava qualquer `FilledButton`. Com a fonte real o botão "Salvar dia" também
  fica na árvore; o finder agora se ancora no rótulo do botão. O app não mudou.
- Novo `test/theme/app_theme_test.dart`: Inter em todos os estilos, scheme sem contornos
  brancos, e um teste que falha se a fonte cair no fallback Ahem.
- Resultado: `analyze` só com o aviso conhecido; **71 passando, 4 pulados**; 4/4 goldens ok.

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
- [ ] Ligar `ThemeMode.system` (`AppTheme.mode`) e remover `Inter-ExtraBold.ttf` se o CP4 não tiver feito.

## Checkpoint 9 (opcional): Performance ligada ao design
**Objetivo:** ganhos de desempenho identificados na auditoria, depois do design estável.
- [ ] `GoRouter` criado uma vez (hoje recriado no `build` de `PalpiteroApp`).
- [ ] Listas de jogos com `ListView.builder`/slivers.
- [ ] Bandeiras SVG (48 arquivos, 484 KB) otimizadas ou convertidas para WebP/PNG.
- [ ] Avaliar o `BackdropFilter` da barra de navegação.
- [ ] Medir antes e depois em aparelho real (DevTools, modo profile).
