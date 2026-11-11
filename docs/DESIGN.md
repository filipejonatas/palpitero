# Design do Palpitero

Fonte de verdade da identidade visual. Os tokens em código (`lib/theme/`) seguem este
documento; se os dois divergirem, este arquivo vence e o código é corrigido.

Plano de implementação: [DESIGN_SYSTEM_PLAN.md](DESIGN_SYSTEM_PLAN.md).

---

## Identidade

Decidida no Checkpoint 1 (2026-11-09).

### Princípios
1. **Esporte, não cassino.** Visual escuro e direto, com uma única cor de marca (lima).
   Cor forte serve para ação ou estado, nunca para decorar.
2. **Lima é a marca.** Só o lima `#C6F135` representa o Palpitero: ação primária,
   seleção, foco e destaque do usuário. Nenhuma outra cor compete com ele.
3. **Cor semântica tem um significado só.** Verde é acerto, vermelho é erro/derrota,
   vermelho vivo é ao vivo, azul é pendente, dourado é pódio. Não reaproveitar.
4. **Peso conta a hierarquia.** Peso máximo só em números e títulos de destaque;
   o resto respira.
5. **Os dois temas são iguais em estrutura.** Claro e escuro mudam cor, nunca layout,
   raio, espaçamento ou tipografia.

### Modo de tema
- **Claro e escuro**, com o mesmo conjunto de tokens.
- Padrão: seguir o sistema (`ThemeMode.system`). Uma opção manual no Perfil fica para
  depois do design system estável, porque é mudança de comportamento.
- O escuro continua sendo a referência visual principal (é como o app nasceu).

### Paleta

Neutros e marca:

| Token | Escuro | Claro | Uso |
|---|---|---|---|
| `background` | `#0D0D0D` | `#F5F6F2` | Fundo das telas |
| `surface` | `#1A1A1A` | `#FFFFFF` | Cards, listas |
| `surfaceElevated` | `#222222` | `#ECEEE8` | Inputs, chips, itens dentro de card, snackbar |
| `textPrimary` | `#FFFFFF` | `#0D0D0D` | Texto principal |
| `textSecondary` | `#8A8A8A` | `#5C5C5C` | Texto de apoio, legendas |
| `textDisabled` | `#5C5C5C` | `#A3A3A3` | Desabilitado (não precisa de contraste AA) |
| `border` | branco `.08` | preto `.08` | Borda padrão de card/input |
| `borderSubtle` | branco `.06` | preto `.06` | Divisores, borda de item interno |
| `borderStrong` | branco `.12` | preto `.12` | Botão outline, borda em destaque |
| `brand` | `#C6F135` | `#C6F135` | Preenchimento: botão primário, chip selecionado, foco |
| `onBrand` | `#0D0D0D` | `#0D0D0D` | Texto/ícone sobre `brand` |
| `brandOnSurface` | `#C6F135` | `#4A6300` | Lima como **texto ou ícone** sobre superfície |

O lima tem contraste 1,31:1 sobre branco. No tema claro ele é só preenchimento; texto
e ícone "da marca" usam `brandOnSurface`.

Semânticas (texto/ícone sobre superfície):

| Token | Escuro | Claro | Significado |
|---|---|---|---|
| `success` / `win` | `#00C896` | `#007A55` | Palpite certo, acerto exato, confirmação |
| `loss` / `error` | `#FF6B5E` | `#B42318` | Palpite errado, erro de formulário/rede |
| `live` | `#FF3B30` | `#C01F14` | Jogo ao vivo (badge, indicador pulsante) |
| `pending` | `#49A7FF` | `#1A62BA` | Aguardando resultado, jogo agendado, histórico |
| `gold` | `#FFD700` | `#8A6500` | 1º lugar, pódio, brilho de splash/login |

- Fundo tonal de um estado = a própria cor com alpha `.14` (ex.: card de acerto exato).
  A borda do estado usa a cor com alpha `.70`.
- No claro, o dourado preenchido (medalha, brilho) continua `#FFD700` com texto `onBrand`;
  `#8A6500` é só para texto.
- `live` e `loss` são vermelhos próximos de propósito, mas não se misturam: `live` é sempre
  badge com rótulo "Ao vivo"; `loss` aparece em resultado de palpite e mensagens de erro.

Contraste mínimo (WCAG, pior caso entre `background`, `surface` e `surfaceElevated`):

| Cor | Escuro | Claro |
|---|---|---|
| `textPrimary` | 15,9 | 16,6 |
| `textSecondary` | 4,6 | 5,7 |
| `brand` / `brandOnSurface` | 12,2 | 5,8 |
| `success` | 7,4 | 4,6 |
| `loss` | 5,7 | 5,6 |
| `live` | 4,5 ⚠️ | 5,2 |
| `pending` | 6,3 | 5,1 |
| `gold` | 11,3 | 4,6 |

⚠️ `live` no escuro sobre `surfaceElevated` fica em 4,49. Regras: texto `live` só sobre
`background` ou `surface`; badge preenchido de `live` usa texto `#0D0D0D` (5,5:1),
**nunca branco** (3,6:1). O snackbar de erro passa a usar `loss`, não `live`.

### O que sai da paleta
| Cor avulsa | Onde | Destino |
|---|---|---|
| `#E45CFF` rosa | Botão "Salvar dia" (`predictions_screen`) | Removida. Vira botão primário (`brand`). |
| `#FFD700` | Brilho em `splash_page` e `login_screen` | Vira token `gold`. |
| `#111111` | `login_screen` | `background` ou `surface` (o mais próximo no contexto). |
| `#2A2A2A` | `login_screen` | `surfaceElevated`. |
| `#555555` | `login_screen` | `textDisabled`. |
| `secondaryAccent` `#00C896` | Status "Today" do `MatchCard`, ícone de histórico do Perfil | Deixa de ser "acento". Vira `success`; os dois usos atuais passam para `pending` (agendado/histórico não é acerto). |
| `liveBadge` | Ao vivo e snackbar de erro | Renomeado para `live`; erros passam para `loss`/`error`. |

As 6 cores de avatar (`avatar_option.dart`) não são cores de interface: viram um grupo
próprio `avatarPalette` e não podem ser usadas fora do avatar.

### Tipografia
- Família: **Inter** (declarada no Checkpoint 2).
- **Três níveis de peso** (mais um intermediário para rótulos):

| Peso | Uso |
|---|---|
| `w900` | Só placar, números de ranking/pontos e o título de maior destaque da tela |
| `w700` | Títulos de seção, títulos de card, botões, AppBar |
| `w500` | Rótulos, chips, abas, legendas com ênfase |
| `w400` | Texto corrido e descrições |

Hoje são 22 usos de `w900`; a meta é que sobrem apenas os casos da primeira linha.

- **Escala fechada de tamanhos** (12 tamanhos atuais viram 6):

| Estilo | Tamanho / peso | Substitui |
|---|---|---|
| `display` | 30 / w900 | 30, 28, 26 (placar, título de splash/login) |
| `headline` | 24 / w700 | 24, 22 |
| `title` | 20 / w700 | 20 (AppBar, título de seção) |
| `titleSmall` | 16 / w700 | 16 com ênfase (título de card) |
| `body` | 16 / w400 · `bodySmall` 14 / w400 | 16, 15, 14 |
| `label` | 13 / w500 · `caption` 12 / w500 | 13, 12, 11 |

Mapeamento para o `TextTheme` do Material (todos os papéis caem na escala):

| Papel do Material | Estilo |
|---|---|
| `display*`, `headlineLarge`, `headlineMedium` | `display` |
| `headlineSmall`, `titleLarge` | `headline` |
| `titleMedium` | `titleSmall` |
| `titleSmall`, `labelLarge` | `label` |
| `bodyLarge` | `body` |
| `bodyMedium` (cor `textSecondary`) | `bodySmall` |
| `bodySmall`, `labelMedium`, `labelSmall` | `caption` |

O estilo `title` (20/w700) é usado pela AppBar. Texto de botão = `titleSmall`.

### Forma e densidade
- **Raios** (escala): `sm 8` (badges, campos pequenos) · `md 14` (cards, botões, inputs,
  snackbar) · `lg 24` (barra de navegação, bottom sheets) · `xl 32` (containers de
  destaque do login/splash) · `pill` (chips, status). O `40` avulso vira `xl` ou `pill`.
- **Espaçamento**: múltiplos de 4: `4, 8, 12, 16, 20, 24, 32`. Margem lateral das telas: 16
  (20 em telas de autenticação). Espaço entre cards: 12.
- **Densidade**: confortável. Alvo de toque mínimo de 48. Botões principais com 52 de altura.
- **Sombras**: quase nenhuma. Elevação é feita com `surface` → `surfaceElevated` e borda,
  não com sombra. No claro, permitida uma sombra suave só em elementos flutuantes
  (barra de navegação, bottom sheet, snackbar).
- **Movimento**: curto e funcional (150 ms para estados, 250 ms para transições,
  400 ms no máximo). Pulsar só o indicador "ao vivo".

### Tokens em código
Desde o Checkpoint 3, um único import: `package:palpitero/theme/app_theme.dart`.

| Onde | O quê | Como usar |
|---|---|---|
| `AppTokens` (`app_tokens.dart`) | Cores e sombras, por tema | `context.tokens.surface`, `context.tokens.stateFill(t.success)` |
| `AppTypography` | Escala de texto | Pelo tema: `Theme.of(context).textTheme.titleMedium` |
| `AppSpacing` | 4…32, `screen`, `cardGap`, `bottomNavClearance` | `EdgeInsets.all(AppSpacing.lg)` |
| `AppRadii` | `sm`, `md`, `lg`, `xl`, `pill` | `BorderRadius.circular(AppRadii.md)` |
| `AppSizes` | `buttonHeight` 52, `minTouchTarget` 48, `spinner` 18 | |
| `AppDurations` | `fast` 150, `medium` 250, `slow` 400 ms | |
| `AppOpacity` | `.06` `.08` `.12` `.14` `.35` `.38` `.70` `.78` (`glass`, barra de navegação) | `color.withValues(alpha: AppOpacity.stateFill)` |
| `AppTextEmphasis` | `.numeric` (w900), `.strong` (w700) | `textTheme.labelLarge?.numeric`: única forma de mudar peso |
| `AppAvatarPalette` | 6 cores de avatar | Só dentro do avatar |

Desde o Checkpoint 4 as telas leem cor só por `context.tokens` (o `AppColors` legado foi
removido) e o app segue o tema do sistema.

### Como escolher a cor certa (decisões do Checkpoint 4)
- **Lima como preenchimento** (botão, chip ativo, aba ativa, pílula de pontos): `brand` com
  texto `onBrand`. **Lima como texto ou ícone**: `brandOnSurface`.
- **Destaque do usuário/vencedor** (minha linha no ranking, vencedor do confronto, slot da
  final): `stateFill(brand)` + `stateBorder(brand)`.
- **Acerto** (placar exato, palpite que pontuou, resultado confirmado): `success` e seus
  `stateFill`/`stateBorder`. Não é lima.
- **Pódio** (troféu e posição do top 3): `gold`.
- **Status de jogo**: ao vivo = `live`; agendado/pendente = `pending`; encerrado = neutro
  (`textSecondary` no fundo/borda, `textPrimary` no texto). Mesmo mapeamento no `MatchCard` e
  no mata-mata.
- **Erro** (snackbar, mensagem): `error` com texto `onLoss`, nunca `live`.
- Borda de lima "decorativa" (faixa da competição, slots comuns do chaveamento) virou borda
  neutra (`border`/`borderStrong`): lima não decora.

### O que nunca fazer
- Usar lima como texto no tema claro.
- Introduzir uma cor nova numa tela sem antes criar o token aqui.
- Usar cor semântica fora do seu significado (ex.: verde para um botão comum).
- Texto branco sobre `live`.
- Peso `w900` em texto corrido ou rótulo.
