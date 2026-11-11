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
  depreciado em `playoff_matchups_screen.dart:438` (resolvido no Checkpoint 6).
- `format`: 6 arquivos fora do padrão faziam o CI falhar. Corrigido com `dart format lib test`.
- `pub get`: 1 pacote descontinuado (`golden_toolkit`). Resolvido no Checkpoint 7: trocado
  pelos `matchesGoldenFile` nativos (`test/helpers/goldens.dart`).

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
- [x] `AppButton` (primário, secundário, outline, texto; estados loading/desabilitado).
- [x] `AppCard`, `AppChip`, `AppTextField`, `AppBadge` (ao vivo, status do palpite, pontos).
- [x] `AppSectionHeader` (+ `AppPageHeader`), `AppEmptyState` (`_SurfaceMessage`), `AppLoading`, `AppErrorState`.
- [x] `showAppBottomSheet`/diálogos padronizados (via `dialogTheme`) e `AppSnackBar`.
- [x] Substituir usos nas telas.

**Pasta:** `lib/design_system/` (componentes base) com o barrel `design_system.dart`, que também
reexporta os tokens. `lib/widgets/` fica para os componentes de domínio do CP6.
Guia de uso: seção "Componentes" do [`DESIGN.md`](DESIGN.md).

**Decisões e achados**
- **Os componentes embrulham os botões do Material** (`FilledButton`, `OutlinedButton`,
  `TextButton`) em vez de redesenhar: semântica, foco e ripple continuam nativos, e os testes
  que procuram `FilledButton` seguem valendo. O spinner de `isLoading` pega a cor do
  `IconTheme` do botão, então lê bem em qualquer estado e tema.
- **Diálogos sem componente:** não há nenhum no app; o `dialogTheme` deixa `AlertDialog` no padrão.
  Criar um `showAppConfirmDialog` quando houver o primeiro uso.
- **Removidos das telas:** 5 cópias de `_SurfaceMessage`, `_EmptyState`, `_AuthButton`/
  `_GoogleSignInButton`/`_EmailSignInButton`, `_RoundChip`, `_StatusChip` e a lógica de
  cor do `MatchStatusChip` (agora só mapeia status → `AppBadgeTone`). `lib/` fora de
  `design_system/`: −848/+273 linhas.
- **Ficaram para o CP6** (são de domínio): os 4 paginadores (`_MatchDaysPager` ×3,
  `_LeaderboardPager`, `_RoundPager`, já sobre `AppCard`), `_CompetitionStrip`, `_PredictionPill`,
  `_ScoreStepper`, `LogoutCircleButton`.
- **Bug corrigido de passagem:** o `MatchCard` tocável tinha o ripple escondido atrás do
  `Container` opaco; o `AppCard` usa `Ink`.
- Novos tokens: `AppSizes.iconSm` (18), `spinnerStroke` (2), `dragHandleWidth` (40).

**Mudanças visíveis (intencionais, seguem o `DESIGN.md`)**
- Botões de Splash e Login: pílula → raio `md` 14, como todos os botões. Google em
  `AppButton.secondary`; carregando, mostra spinner + rótulo (antes só o spinner).
- `TextButton` ("Palpites" nos resultados): lima puro → `brandOnSurface` 13/w700. No claro, o
  lima como texto tinha contraste 1,31:1.
- Spinners de tela: lima → `brandOnSurface` (`progressIndicatorTheme`), pelo mesmo motivo.
- Snackbars de falha (carregar/salvar palpite, ranking, perfil, foto, backend) passam a usar
  `AppSnackBar.error`; confirmações seguem neutras.
- Mensagens vazias ganham a borda `borderSubtle` dos cards (antes só o Perfil tinha); padding
  da vazia da Home 20 → 16. Paginadores e o histórico do Perfil também ganham a borda.
- Erro de estatísticas do Perfil e falha da sheet de palpites viram `AppErrorState` (ícone de erro).
- Sheet de palpites: alça de arrasto (`showDragHandle`) e raio `lg` no topo.
- Palpite público sem acerto exato: perde a borda (item dentro da sheet = `AppCard.elevated`).

**Testes**
- Novo `test/design_system/components_test.dart`: 19 casos × 2 temas (cores de cada variante,
  loading/desabilitado, estados, snackbar, sheet, campo).
- Goldens de Splash e Login regenerados (botões); `MatchCard` e Ranking ficaram idênticos
  pixel a pixel, confirmando que `AppCard`/`AppBadge` reproduzem o visual anterior.
- Resultado: `analyze` só com o aviso conhecido; **133 passando, 8 pulados**; 8/8 goldens ok.

## Checkpoint 6: Componentes de domínio
**Objetivo:** extrair os widgets privados das telas gigantes.
- [x] `MatchCard` (revisar `lib/widgets/match_card.dart`): separado em `MatchCard`, `TeamFlag`
      (com a tabela de bandeiras) e `MatchStatusChip`/`PlayoffStatusBadge`; + `MatchInfoRow`.
- [x] `ScoreStepper` (palpite de 0 a 9), `PredictionTile` (+ `PredictionCard`).
- [x] `LeaderboardRow` + `AvatarBadge` (revisar).
- [x] `RoundHeader`, `BracketMatchup`, `DaySelector` (+ `RoundSelector`, `PlayoffBracketView`).
- [x] Reduzir `playoff_matchups_screen`, `playoff_screen` e `predictions_screen` a composição de componentes.

**Pronto quando:** nenhuma tela passa de ~400 linhas e não há widget visual duplicado. ✅

**Pasta:** `lib/widgets/` com o barrel `widgets.dart` (mata-mata em `lib/widgets/playoff/`).
Guia: seção "Componentes de domínio" do [`DESIGN.md`](DESIGN.md).

| Tela | Antes | Depois |
|---|---|---|
| `playoff_screen` | 1006 | 210 |
| `playoff_matchups_screen` | 942 | 306 |
| `predictions_screen` | 708 | 279 |
| `profile_screen` | 471 | 324 |
| `results_screen` | 411 | 270 |
| `home_screen` | 326 | 171 |
| `leaderboard_screen` | 300 | 178 |

Só sobram widgets privados específicos de uma tela (`_UserSummary`, `_ResultActions`, a sheet de
resultados, os blocos do Login e o item da barra de navegação). `login_screen` (433) não mudou:
não tem duplicação e não fazia parte do escopo.

**Decisões e achados**
- **Duplicações removidas:** 4 paginadores (`_MatchDaysPager` ×3, `_LeaderboardPager`) e o
  `_RoundPager` viram `AppPager` (base) + `DaySelector`/`RoundSelector`; `_PreviewBracket` e
  `_OfficialBracket` repetiam o canvas inteiro e viram `PlayoffBracketView.preview/.official`;
  `LeaderboardTile` e `_CompetitorScoreCard` eram o mesmo desenho e viram `LeaderboardRow`;
  `_PublicPredictionTile` e `_HistoryTile` viram `PredictionTile`; `_ProfilePhoto` e o avatar de
  inicial entram no `AvatarBadge`; o botão "Perfil" e o `LogoutCircleButton` viram `HeaderActionButton`;
  a ordem de seeds estava copiada em duas telas.
- **Lógica sem visual tirada das telas** (não muda comportamento): agrupamento por dia
  (`groupMatchesByKickoffLabel`/`ByKickoffDate` em `utils/match_day_selector.dart`) e rodadas do
  mata-mata (`utils/playoff_rounds.dart`).
- **Base ampliada** (regra "amplie o componente antes de desenhar à mão"): `AppCard.inset`
  (`background` + `borderSubtle`, para a pílula de palpite dentro de card elevado) e `AppPager`.
- **Aviso do CP0 resolvido:** `DropdownButtonFormField.value` → `initialValue` com `key` que
  reinicia o campo quando a rodada ou a seleção muda. `flutter analyze` agora sem nenhum aviso.
- `LeaderboardTile` foi renomeado para `LeaderboardRow` (o teste do Ranking foi ajustado).

**Mudanças visíveis (intencionais)**
- Rótulo do dia em Palpites e Resultados: `AppSectionHeader` (à esquerda) → `RoundHeader`
  (centralizado entre divisores), como já era na Home. Um só estilo para o mesmo conceito.
- Botão "Perfil" da Home: fundo `surface` sem borda → `surfaceElevated` + `border`, igual ao "Sair".
- Faixa da competição na Home: `Container` à mão (`surfaceElevated` + `border`) → `AppCard`
  (`surface` + `borderSubtle`), pela regra do `DESIGN.md` para card solto na tela.
- Estatísticas do Perfil: espaço entre os cards 10 → 12 (`cardGap`).
- Foto do Perfil e avatares com foto: enquanto a imagem carrega mostram o ícone de reserva.

**Testes**
- Novo `test/widgets/domain_components_test.dart`: 15 casos × 2 temas (stepper nos limites,
  seletores, pódio/minha linha, acerto exato, avatar, status do mata-mata, pênaltis no empate,
  bye no preview, chave oficial, vencedor do confronto) + 3 testes de `playoff_rounds`.
  `match_day_selector_test` ganhou os 2 agrupamentos por dia.
- Goldens de `MatchCard` e Ranking idênticos pixel a pixel (sem regenerar): `LeaderboardRow` e o
  `MatchCard` dividido reproduzem o visual anterior.
- Resultado: `analyze` limpo; **168 passando, 8 pulados**; 8/8 goldens ok.

## Checkpoint 7: Catálogo e testes visuais
**Objetivo:** ver e proteger cada componente em todos os estados.
- [x] Widgetbook (ou tela `/design-system` só em debug) com todos os componentes.
- [x] Goldens por componente (normal, desabilitado, carregando, erro).
- [x] Teste de contraste das cores de texto sobre as superfícies (acessibilidade). Feito no CP3.

**Pasta:** `lib/catalog/`. Guia: seção "Catálogo e goldens" do [`DESIGN.md`](DESIGN.md).

**Decisões e achados**
- **Tela `/design-system` em vez de Widgetbook:** sem dependência nem app separado, usa o
  tema e as fontes do próprio app, e as seções são widgets públicos que os goldens reaproveitam
  (catálogo e golden não divergem). Só existe em debug (`kDebugMode`), não pede login
  (`redirect` libera a rota) e abre direto com `--dart-define=DESIGN_SYSTEM=true`.
- **Conteúdo:** 3 seções de tokens (cores, tipografia, espaçamento/raios), 9 de base e 10 de
  domínio. Os rótulos da tipografia são lidos do próprio `TextStyle`, então não ficam
  desatualizados. Só o `LogoutCircleButton` ficou de fora (precisa de `SessionController`;
  o visual é o do `HeaderActionButton`, que está no catálogo).
- **`golden_toolkit` removido** (pendência do CP0, pacote descontinuado): virou
  `test/helpers/goldens.dart` (~130 linhas, `matchesGoldenFile` nativo) com o mesmo
  comportamento (fontes do `FontManifest`, DPR 1, `MaterialApp` + `Material`, imagens
  pré-carregadas). Os 8 goldens de tela passaram **idênticos pixel a pixel** sem regenerar.
- **Spinners não assentam:** `pumpGolden(settleFor:)` avança um tempo fixo (1 s) em vez de
  `pumpAndSettle`, então o quadro do spinner é determinístico.
- **Achado:** `MatchPrediction.isPlayoffMatch` trata qualquer jogo a partir de 28/06/2026
  como mata-mata, mesmo com `round: 'Group Stage'`. O `futureMatch` dos testes (2099) cai
  nesse caso. Não mudei (é comportamento); as amostras do catálogo usam datas anteriores.
- O chaveamento abre centralizado e, na largura de celular, mostra só as linhas; por isso o
  `BracketSlot` (normal, avançou, bye, lado direito) tem exemplar próprio.

**Testes**
- `test/goldens/components_golden_test.dart`: 22 seções + snackbar info/erro + bottom sheet,
  × 2 temas = 48 imagens novas em `test/goldens/goldens/components/`. Revisadas uma a uma.
- `test/catalog/design_system_catalog_test.dart` (roda no CI): ids únicos, cada seção monta
  sem exceção nos dois temas a 390 px, filtro por grupo e alternância de tema.
- Resultado: `analyze` limpo; **215 passando, 56 pulados** (goldens fora do `RUN_GOLDENS`);
  56/56 goldens ok.

## Checkpoint 8: Guardrails e documentação
**Objetivo:** impedir regressão e orientar quem (ou qual IA) criar telas novas.
- [x] Regra de lint proibindo `Color(0x…)`, `fontSize:` e `EdgeInsets` numéricos fora do design system (`custom_lint` ou script de CI).
- [x] `DESIGN.md`: princípios, tokens, quando usar cada componente, o que nunca fazer.
- [x] Checklist de PR para telas novas.
- [x] Rodar o lint no CI (`.github/`).
- [x] Ligar `ThemeMode.system` (`AppTheme.mode`) e remover `Inter-ExtraBold.ttf` (feito no CP4).

**Arquivos:** `tool/design_lint.dart`, `test/tool/design_lint_test.dart`,
`.github/workflows/flutter-ci-cd.yml`, `.github/pull_request_template.md`. Guia: seções
"Tela nova, passo a passo", "Guardrails" e "O que nunca fazer" do [`DESIGN.md`](DESIGN.md).

**Decisões e achados**
- **Script Dart em vez de `custom_lint`:** sem dependência nova (o `custom_lint` prende a versão
  do `analyzer` e pesa no `pub get`), roda com `dart run` e cabe em ~300 linhas. O preço é não
  sublinhar no editor; o teste `test/tool/design_lint_test.dart` cobre isso fazendo o
  `flutter test` local falhar antes do push.
- **11 regras**, além das 3 pedidas: `Colors.*`, `FontWeight`, `fontFamily`, `SizedBox` de
  espaço, raio, opacidade, `BoxShadow` e widgets do Material crus fora de `lib/design_system/`
  (a regra "tela não usa `FilledButton`…" do CP5, que até aqui só estava escrita).
  `lib/theme/` fica de fora; comentários e strings são ignorados.
- **Números só contam quando são literais ≠ 0** nos argumentos (inclusive em chamadas de várias
  linhas): `EdgeInsets.only(top: 0)` e `AppSpacing.*` passam; `SizedBox(height: 220, child: …)`
  é medida, não espaço, e também passa.
- **Exceção explícita** com `// design-lint: ignore <regra> (motivo)`. Só uma no código: a
  proporção `size * .22` do `TeamFlag`.
- **O código já estava limpo:** a primeira rodada só achou o `TeamFlag`. O lint agora impede a
  volta.
- **`CLAUDE.md` na raiz** aponta assistentes de IA para o `DESIGN.md`, resume as regras e lista
  a verificação antes do commit.
- **Checklist de PR** em `.github/pull_request_template.md`: lint, tokens, tipografia, lima no
  claro, componentes, catálogo/golden, dois temas, goldens locais.
- Resultado: `analyze` limpo; lint limpo; **224 passando, 56 pulados**; 56/56 goldens ok.

## Checkpoint 9 (opcional): Performance ligada ao design
**Objetivo:** ganhos de desempenho identificados na auditoria, depois do design estável.
- [x] `GoRouter` criado uma vez (hoje recriado no `build` de `PalpiteroApp`).
- [x] Listas de jogos com `ListView.builder`/slivers.
- [x] Bandeiras SVG (48 arquivos, 484 KB) otimizadas ou convertidas para WebP/PNG.
- [x] Avaliar o `BackdropFilter` da barra de navegação.
- [ ] Medir antes e depois em aparelho real (DevTools, modo profile). Exige aparelho; roteiro abaixo.

**Decisões e achados**
- **`GoRouter` era um bug, não só custo:** `PalpiteroApp` virou `StatefulWidget` e cria o
  router uma vez (`late` no `State`; recria só se o `SessionController` mudar, e faz
  `dispose`). Antes, qualquer rebuild do app (ex.: o `ProviderScope` acima reconstruir) criava
  um router novo e **voltava a navegação para `/splash`**. Novo teste em
  `bottom_navigation_test.dart` (rebuild mantém o Ranking aberto) falha no código antigo.
- **Listas preguiçosas:** Home, Palpites, Resultados, histórico do Perfil e a sheet de palpites
  dos Resultados viram `CustomScrollView` com `SliverList.builder` para os itens. Os de maior
  ganho são o histórico do Perfil e a sheet (crescem com o torneio e com o bolão); as listas
  por dia têm poucos jogos, mas seguem o mesmo esqueleto (documentado no `DESIGN.md`, "Tela
  nova"). Ranking e mata-mata ficaram como estão: o Ranking já pagina e o mata-mata mostra um
  confronto por vez.
  - Risco tratado: o `PredictionCard` tem estado (placar em edição). Com o builder, o card que
    sai da tela é descartado; o rascunho sobrevive porque cada edição já ia para `_drafts`.
    Novo teste em `predictions_screen_test.dart` edita, rola até o card ser descartado, volta
    e confere o placar.
  - A animação de entrada (`fadeIn`/`slideY`) roda de novo quando um card descartado volta à
    tela. Com poucos jogos por dia, quase não acontece.
- **Bandeiras pré-compiladas, não WebP/PNG:** o `pubspec.yaml` passa `assets/flags/` pelo
  transformer do `vector_graphics_compiler` (formato binário, sem parse de XML em runtime);
  o `TeamFlag` carrega com `AssetBytesLoader`. Continua vetorial (nítido em qualquer DPR) e
  bandeira nova é só soltar o `.svg`. Novas dependências: `vector_graphics` (já vinha pelo
  `flutter_svg`) e `vector_graphics_compiler` (dev).
  - `--use-half-precision-control-points`: sem ele, o binário ficava **maior** que o SVG
    (640 KB vs 429 KB). Com ele, os goldens só mudam no anti-aliasing da borda das bandeiras.
  - `svgo` testado e descartado: −6% no SVG, não muda o binário.

  | Bandeiras (48) | SVG (antes) | Compilado (depois) |
  |---|---|---|
  | Tamanho bruto | 429 KB | 365 KB |
  | Comprimido (gzip, aprox. APK/web) | 126 KB | 181 KB |
  | Carregar as 48 (teste, JIT, desktop) | 106 ms | 73 ms |

  O tempo é do ambiente de teste e serve só de comparação; o número real sai da medição em
  aparelho. O preço é +55 KB comprimidos no pacote.
- **`BackdropFilter` mantido:** um só filtro, recortado pelo `ClipRRect` na área da barra
  (~360×70), com blur 10. Com `AppOpacity.glass` (.78), sem o blur o conteúdo que passa por
  baixo fica nítido e ruidoso através da barra; trocar por fundo opaco é mudança visual. Fica
  como está até a medição: se no Android de entrada o thread de raster passar de ~8 ms por
  quadro ao rolar a Home, trocar o blur por `surface` opaco (sem `BackdropFilter`).

**Medição em aparelho (pendente)**
```sh
flutter run --profile   # Android de entrada, de preferência
```
- DevTools → Performance: rolar Home e Palpites com o overlay de desempenho ligado
  (raster/UI por quadro; meta < 16 ms, alvo de folga 8 ms) e abrir a aba Palpites a frio
  (primeiras bandeiras na tela).
- Comparar com o commit anterior ao CP9 (`0308b00`) nos mesmos passos.
- `flutter build apk --analyze-size` para o tamanho real das bandeiras no pacote.

**Testes**
- Resultado: `analyze` limpo; lint limpo; **226 passando, 56 pulados**; 56/56 goldens ok
  (8 regenerados: `MatchCard`, `PredictionCard` e status, só borda das bandeiras).
