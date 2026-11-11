import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import 'catalog_section.dart';

void _noop() {}

final baseSections = <CatalogSection>[
  CatalogSection(
    id: 'app_button',
    title: 'AppButton',
    group: CatalogGroup.base,
    description: 'Primário (um por área), secundário, outline e texto.',
    specimens: () => [
      for (final variant in AppButtonVariant.values)
        CatalogSpecimen(
          '${variant.name}: normal, desabilitado, carregando',
          _ButtonStates(variant),
        ),
    ],
  ),
  CatalogSection(
    id: 'app_card',
    title: 'AppCard',
    group: CatalogGroup.base,
    description:
        'Card solto (surface), dentro de card (elevated, inset) e '
        'card de estado (highlight).',
    specimens: () => [
      const CatalogSpecimen(
        'surface (padrão)',
        AppCard(width: double.infinity, child: Text('Card na tela')),
      ),
      const CatalogSpecimen(
        'elevated > inset',
        AppCard(
          width: double.infinity,
          child: AppCard.elevated(
            width: double.infinity,
            child: AppCard.inset(
              width: double.infinity,
              child: Text('Item dentro de item'),
            ),
          ),
        ),
      ),
      CatalogSpecimen(
        'highlight: brand (minha linha) e success (acerto)',
        Builder(
          builder: (context) {
            final t = context.tokens;
            return Column(
              children: [
                AppCard(
                  width: double.infinity,
                  highlight: t.brand,
                  child: const Text('Minha posição'),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                AppCard(
                  width: double.infinity,
                  highlight: t.success,
                  child: const Text('Placar exato'),
                ),
              ],
            );
          },
        ),
      ),
      const CatalogSpecimen(
        'tocável (onTap)',
        AppCard(
          width: double.infinity,
          onTap: _noop,
          child: Text('Toque para abrir'),
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_chip',
    title: 'AppChip',
    group: CatalogGroup.base,
    description: 'Seleção em pílula. Para status somente leitura, AppBadge.',
    specimens: () => [
      const CatalogSpecimen(
        'selecionado, normal, somente leitura',
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(label: 'RD32', selected: true, onTap: _noop),
            AppChip(label: 'RD16', onTap: _noop),
            AppChip(label: 'Quartas'),
          ],
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_badge',
    title: 'AppBadge',
    group: CatalogGroup.base,
    description: 'Status somente leitura. Cada tom tem um significado só.',
    specimens: () => [
      CatalogSpecimen(
        'tons',
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tone in AppBadgeTone.values)
              AppBadge(label: tone.name, tone: tone),
          ],
        ),
      ),
      const CatalogSpecimen(
        'pontos: pontuou e não pontuou',
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            AppBadge.points(12),
            AppBadge.points(0, highlighted: false),
          ],
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_text_field',
    title: 'AppTextField',
    group: CatalogGroup.base,
    description: 'Campo de uma linha. Borda, foco e erro vêm do tema.',
    specimens: () => [
      const CatalogSpecimen('vazio (hint)', AppTextField(hintText: 'Seu nick')),
      const CatalogSpecimen(
        'preenchido (label)',
        _FilledField(labelText: 'Nick'),
      ),
      const CatalogSpecimen(
        'erro',
        _FilledField(labelText: 'Nick', errorText: 'Use de 3 a 24 caracteres.'),
      ),
      const CatalogSpecimen(
        'desabilitado',
        _FilledField(labelText: 'E-mail', enabled: false),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_pager',
    title: 'AppPager',
    group: CatalogGroup.base,
    description: 'Anterior / próximo. Seta null = desabilitada.',
    specimens: () => [
      const CatalogSpecimen(
        'meio (as duas setas)',
        AppPager(
          label: 'Página 2 de 5',
          previousTooltip: 'Anterior',
          nextTooltip: 'Próxima',
          onPrevious: _noop,
          onNext: _noop,
        ),
      ),
      const CatalogSpecimen(
        'primeira página (anterior desabilitada)',
        AppPager(
          label: 'Página 1 de 5',
          previousTooltip: 'Anterior',
          nextTooltip: 'Próxima',
          onPrevious: null,
          onNext: _noop,
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_headers',
    title: 'AppPageHeader e AppSectionHeader',
    group: CatalogGroup.base,
    description: 'Topo do conteúdo da tela e título de bloco.',
    specimens: () => [
      const CatalogSpecimen(
        'AppPageHeader (eyebrow + subtítulo)',
        AppPageHeader(
          eyebrow: 'Mata-mata',
          title: 'Confrontos',
          subtitle: 'Quem fizer mais pontos na rodada passa.',
        ),
      ),
      CatalogSpecimen(
        'AppSectionHeader (ícone + trailing)',
        AppSectionHeader(
          title: 'Sua posição',
          icon: PhosphorIcons.trophy(),
          trailing: const AppBadge.points(72),
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_states',
    title: 'Carregando, vazio e erro',
    group: CatalogGroup.base,
    description: 'AppLoading, AppEmptyState e AppErrorState.',
    specimens: () => [
      const CatalogSpecimen(
        'AppLoading',
        AppLoading(padding: EdgeInsets.all(AppSpacing.lg)),
      ),
      const CatalogSpecimen(
        'AppEmptyState',
        AppEmptyState(message: 'Nenhum jogo para hoje.'),
      ),
      const CatalogSpecimen(
        'AppErrorState',
        AppErrorState(message: 'Não foi possível carregar o ranking.'),
      ),
      const CatalogSpecimen(
        'AppErrorState com onRetry',
        AppErrorState(
          message: 'Não foi possível carregar o ranking.',
          onRetry: _noop,
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'app_feedback',
    title: 'AppSnackBar e showAppBottomSheet',
    group: CatalogGroup.base,
    description: 'Mensagens e sheets abrem por cima da tela: toque para ver.',
    specimens: () => [const CatalogSpecimen('abrir', _FeedbackLaunchers())],
  ),
];

class _ButtonStates extends StatelessWidget {
  const _ButtonStates(this.variant);

  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isText = variant == AppButtonVariant.text;
    final buttons = [
      AppButton(
        variant: variant,
        label: 'Confirmar',
        icon: PhosphorIcon(PhosphorIcons.checkCircle()),
        expand: !isText,
        onPressed: _noop,
      ),
      AppButton(
        variant: variant,
        label: 'Confirmar',
        icon: PhosphorIcon(PhosphorIcons.checkCircle()),
        expand: !isText,
        onPressed: null,
      ),
      AppButton(
        variant: variant,
        label: 'Confirmando...',
        expand: !isText,
        isLoading: true,
        onPressed: _noop,
      ),
    ];

    if (isText) {
      return Wrap(spacing: AppSpacing.sm, children: buttons);
    }
    return Column(
      children: [
        for (final (index, button) in buttons.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          button,
        ],
      ],
    );
  }
}

/// Field with a fixed value; owns its controller.
class _FilledField extends StatefulWidget {
  const _FilledField({
    required this.labelText,
    this.errorText,
    this.enabled = true,
  });

  final String labelText;
  final String? errorText;
  final bool enabled;

  @override
  State<_FilledField> createState() => _FilledFieldState();
}

class _FilledFieldState extends State<_FilledField> {
  final _controller = TextEditingController(text: 'Canarinho');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      labelText: widget.labelText,
      errorText: widget.errorText,
      enabled: widget.enabled,
    );
  }
}

class _FeedbackLaunchers extends StatelessWidget {
  const _FeedbackLaunchers();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton.outline(
          label: 'AppSnackBar.info',
          onPressed: () => AppSnackBar.info(context, 'Palpite salvo.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.outline(
          label: 'AppSnackBar.error',
          onPressed: () =>
              AppSnackBar.error(context, 'Não foi possível salvar o palpite.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.outline(
          label: 'showAppBottomSheet',
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            builder: (context) => const CatalogSheetContent(),
          ),
        ),
      ],
    );
  }
}

/// What the catalog's bottom sheet shows; also used by its golden.
class CatalogSheetContent extends StatelessWidget {
  const CatalogSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Palpites', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          const AppCard.elevated(
            width: double.infinity,
            child: Text('Item dentro da sheet usa AppCard.elevated.'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
