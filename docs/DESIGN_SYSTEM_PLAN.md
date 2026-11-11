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
- Alerta do GitHub sobre as chaves `AIza…` de `lib/firebase_options.dart`: tratado em
  [SECURITY_PLAN.md](SECURITY_PLAN.md). As restrições ficam para quando o build rodar.

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
- [x] Cores: todos os tokens do `DESIGN.md` (neutros, marca, `success/win`, `loss/error`,
      `live`, `pending`, `gold`) em `AppTokens`, por tema; cores de avatar em `AppAvatarPalette`.
- [x] `AppSpacing`: escala 4/8/12/16/20/24/32 + `screen`, `screenAuth`, `cardGap`, `bottomNavClearance` (120).
- [x] `AppTypography`: escala fechada de 8 estilos, mapeada em todos os papéis do `TextTheme`.
- [x] `AppRadii`: `sm 8`, `md 14`, `lg 24`, `xl 32`, `pill` (`card`/`nav` ficam como aliases até o CP4).
- [x] Sombras (`floatingShadow`, `glowShadow` em `AppTokens`), `AppDurations` (150/250/400),
      `AppOpacity` e `AppSizes` (botão 52, toque 48).
- [x] Expor via `ThemeExtension` (`context.tokens`).

**Pronto quando:** tokens documentados e `app_theme.dart` sem números mágicos. ✅

**Arquivos:** `lib/theme/app_scales.dart` (igual nos dois temas), `lib/theme/app_tokens.dart`
(cores e sombras por tema), `lib/theme/app_theme.dart` (monta o `ThemeData` e reexporta os dois).
Basta `import 'package:palpitero/theme/app_theme.dart'`.

**Decisões e achados**
- **`AppColors` legado continua** (dark-only, usado ~140 vezes nas telas). Some no CP4.
- **`overlay` não virou token:** os `Colors.white/black` com alpha das telas são todos bordas
  (`border`/`borderSubtle`) ou texto sobre lima (`onBrand`). Nenhum é overlay de fato.
- **Mudanças visíveis (intencionais, seguem o `DESIGN.md`)**, goldens regenerados:
  - `titleLarge` 22/w900 → `headline` 24/w700; `titleMedium` w800 → w700; AppBar w800 → w700.
  - `labelLarge` 13/w800 → 13/w500; chips w700 → w500.
  - Botões: texto 16/w700 em todos (o `FilledButton` era 15/w800) e altura 52 (o `FilledButton` era 50).
  - `headlineMedium` (título das telas) e `bodyLarge`/`bodyMedium` não mudaram.
- **Teste de contraste antecipado do CP7:** `test/theme/app_tokens_test.dart` verifica AA
  (4,5:1) de cada cor de texto sobre `background`, `surface` e `surfaceElevated` nos dois
  temas, `live` só sobre `background`/`surface`, e os pares `on*` sobre seus preenchimentos.
  Todos os valores do `DESIGN.md` passaram.
- `glowShadow` adota o brilho da Splash (`.30`, blur 40, spread 10); o Login (`.25`, 30, 8)
  passa a usá-lo no CP4.
- Resultado: `analyze` só com o aviso conhecido; **95 passando, 4 pulados**; 4/4 goldens ok.

## Checkpoint 4: Migrar telas para os tokens
**Objetivo:** remover valores avulsos das telas, uma tela por vez.
- [x] `login_screen` e `splash_page` (cores `#FFD700`, `#111111`, `#2A2A2A`, `#555555`).
- [x] `predictions_screen` (rosa `#E45CFF` do botão "Salvar dia").
- [x] `models/avatar_option.dart` (cores dos avatares → `AppAvatarPalette`).
- [x] `Colors.white/black` com alpha viram tokens (`border`/`borderSubtle`/`borderStrong`, `onBrand`).
- [x] `fontSize`/`FontWeight` inline viram estilos do `TextTheme` (+ `.numeric`/`.strong`).
- [x] `EdgeInsets`/`SizedBox` viram `AppSpacing`; o `120` virou `AppSpacing.bottomNavClearance`.
- [x] Goldens revisados a cada tela (diferença visual deve ser intencional).
- [x] Extra (previsto para o fim do CP4): `AppColors` e os aliases `AppRadii.card/nav`
      removidos, `ThemeMode.system` ligado, `Inter-ExtraBold.ttf` removido.

**Pronto quando:** `grep "Color(0x"` e `grep "fontSize:"` fora do tema retornam zero. ✅

**Como foi feito**
- Troca mecânica por script (cores `AppColors.*` → `context.tokens.*`, bordas brancas com
  alpha → tokens de borda, raios legados, espaçamentos → `AppSpacing`), depois revisão
  manual de cada uso de lima, vermelho e peso. As regras de escolha ficaram em
  [`DESIGN.md`](DESIGN.md) ("Como escolher a cor certa").
- Espaçamentos fora da escala foram arredondados para o passo mais próximo
  (2-5 → 4, 6-9 → 8, 10-13 → 12, 14-17 → 16, 18-21 → 20, 22-27 → 24, 28+ → 32).
  Medidas de componente (bandeira 48, slot do chaveamento 34, avatar, ícones) e a geometria
  do chaveamento não são espaçamento e ficaram como estão.

**Novos tokens:** `AppTextEmphasis` (`.numeric` w900 para números, `.strong` w700 para
ênfase/status), `AppSizes.spinner` (18) e `AppOpacity.glass` (.78, fundo da barra de navegação).

**Mudanças visíveis (intencionais, seguem o `DESIGN.md`)**
- Margem lateral das telas 20 → 16 (`screen`); Splash/Login 24 → 20 (`screenAuth`).
- Títulos "Palpitero" (Splash 26, Login 24) → `display` 30; "Bem-vindo" 22/w900 → `headline` 24/w700;
  placar do `MatchCard` e do palpite 28 → 30; "PLAYOFF" 26 → 30.
- Botões: textos w800/w900 → `button` 16/w700; botões de login com altura 52 (era 50);
  "Salvar dia" deixa de ser rosa e vira primário (lima).
- Login: card inferior `#111111` → `surface`; botão do Google `surfaceElevated` com borda `border`;
  termos `#555555`/11 → `textDisabled`/12; brilho do troféu usa `glowShadow` (Splash e Login iguais);
  raio do troféu 40/32 → `xl` 32. Erro de login em `error`/`onLoss` (era `live` com texto branco).
- Ranking: troféu e posição do top 3 em `gold` (eram lima); minha linha com `stateFill/stateBorder(brand)`.
- Status de jogo: "Today"/pendente em `pending` (era verde/cinza), ao vivo em `live`, fundo `.14`
  e borda `.70`, texto 12/w700 (era w900). Mesmo visual no mata-mata.
- Resultados e mata-mata: placar exato e palpite que pontuou em `success` (eram lima).
- Chaveamento: slots comuns com borda neutra `borderStrong` (era lima .5); raio 8 → `sm`.
- Faixa da competição na Home: borda neutra (era lima .2).
- Barra de navegação: margem 20 → 16, sombra `floatingShadow` (só no claro), transição 180 → 150 ms.
- Chips de rodada (mata-mata) com peso w500 (eram w900).

**Testes**
- Goldens agora rodam nos dois temas: 4 escuros (mesmos nomes) + 4 claros (`*_light.png`).
  Os 4 escuros foram regenerados (novo baseline).
- Resultado: `analyze` só com o aviso conhecido; **95 passando, 8 pulados** (goldens fora do
  `RUN_GOLDENS`); 8/8 goldens ok.
- Pendente: conferir em aparelho real o tema claro seguindo o sistema.

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
- [x] Teste de contraste das cores de texto sobre as superfícies (acessibilidade). Feito no CP3.

## Checkpoint 8: Guardrails e documentação
**Objetivo:** impedir regressão e orientar quem (ou qual IA) criar telas novas.
- [ ] Regra de lint proibindo `Color(0x…)`, `fontSize:` e `EdgeInsets` numéricos fora do design system (`custom_lint` ou script de CI).
- [ ] `DESIGN.md`: princípios, tokens, quando usar cada componente, o que nunca fazer.
- [ ] Checklist de PR para telas novas.
- [ ] Rodar o lint no CI (`.github/`).
- [x] Ligar `ThemeMode.system` (`AppTheme.mode`) e remover `Inter-ExtraBold.ttf` (feito no CP4).

## Checkpoint 9 (opcional): Performance ligada ao design
**Objetivo:** ganhos de desempenho identificados na auditoria, depois do design estável.
- [ ] `GoRouter` criado uma vez (hoje recriado no `build` de `PalpiteroApp`).
- [ ] Listas de jogos com `ListView.builder`/slivers.
- [ ] Bandeiras SVG (48 arquivos, 484 KB) otimizadas ou convertidas para WebP/PNG.
- [ ] Avaliar o `BackdropFilter` da barra de navegação.
- [ ] Medir antes e depois em aparelho real (DevTools, modo profile).
