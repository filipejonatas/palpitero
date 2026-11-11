import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'catalog_section.dart';

final tokenSections = <CatalogSection>[
  CatalogSection(
    id: 'tokens_colors',
    title: 'Cores',
    group: CatalogGroup.tokens,
    description: 'context.tokens.*, por tema. Nunca Color(0x...) nas telas.',
    specimens: () => [
      CatalogSpecimen(
        'Neutros',
        _Swatches(
          (t) => {
            'background': t.background,
            'surface': t.surface,
            'surfaceElevated': t.surfaceElevated,
            'textPrimary': t.textPrimary,
            'textSecondary': t.textSecondary,
            'textDisabled': t.textDisabled,
            'border': t.border,
            'borderSubtle': t.borderSubtle,
            'borderStrong': t.borderStrong,
          },
        ),
      ),
      CatalogSpecimen(
        'Marca',
        _Swatches(
          (t) => {
            'brand': t.brand,
            'onBrand': t.onBrand,
            'brandOnSurface': t.brandOnSurface,
          },
        ),
      ),
      CatalogSpecimen(
        'Semânticas',
        _Swatches(
          (t) => {
            'success': t.success,
            'loss / error': t.loss,
            'live': t.live,
            'pending': t.pending,
            'gold': t.gold,
            'goldFill': t.goldFill,
          },
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'tokens_typography',
    title: 'Tipografia',
    group: CatalogGroup.tokens,
    description:
        'Inter, escala fechada via TextTheme. Ênfase: .numeric / .strong.',
    specimens: () => [
      CatalogSpecimen(
        'Escala',
        Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            // Role in the TextTheme; size and weight are read from the
            // style itself, so the label can't drift from the theme.
            final styles = <String, TextStyle>{
              'headlineMedium': text.headlineMedium!,
              'titleLarge': text.titleLarge!,
              'titleMedium': text.titleMedium!,
              'bodyLarge': text.bodyLarge!,
              'bodyMedium': text.bodyMedium!,
              'labelLarge': text.labelLarge!,
              'labelMedium': text.labelMedium!,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final MapEntry(key: role, value: style)
                    in styles.entries) ...[
                  Text(
                    '$role ${style.fontSize!.round()}/w${style.fontWeight!.value}',
                    style: style,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
      CatalogSpecimen(
        'Ênfase',
        Builder(
          builder: (context) {
            final body = Theme.of(context).textTheme.bodyMedium!;
            return Wrap(
              spacing: AppSpacing.lg,
              children: [
                Text('regular', style: body),
                Text('.strong', style: body.strong),
                Text('.numeric 2 x 1', style: body.numeric),
              ],
            );
          },
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'tokens_spacing_radii',
    title: 'Espaçamento e raios',
    group: CatalogGroup.tokens,
    description:
        'AppSpacing (4/8/12/16/20/24/32) e AppRadii (8/14/24/32/pill).',
    specimens: () => [
      const CatalogSpecimen(
        'AppSpacing',
        _Scale({
          'xs 4': AppSpacing.xs,
          'sm 8': AppSpacing.sm,
          'md 12': AppSpacing.md,
          'lg 16': AppSpacing.lg,
          'xl 20': AppSpacing.xl,
          'xxl 24': AppSpacing.xxl,
          'xxxl 32': AppSpacing.xxxl,
        }),
      ),
      const CatalogSpecimen('AppRadii', _Radii()),
    ],
  ),
];

/// Grid of named color chips, three per row.
class _Swatches extends StatelessWidget {
  const _Swatches(this.colors);

  final Map<String, Color> Function(AppTokens t) colors;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final caption = Theme.of(context).textTheme.labelMedium;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        for (final MapEntry(key: name, value: color) in colors(t).entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: t.borderStrong),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: caption,
              ),
            ],
          ),
      ],
    );
  }
}

/// Spacing steps as lima bars of that width.
class _Scale extends StatelessWidget {
  const _Scale(this.steps);

  final Map<String, double> steps;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final caption = Theme.of(context).textTheme.labelMedium;

    return Column(
      children: [
        for (final MapEntry(key: name, value: size) in steps.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.xxxl * 2,
                  child: Text(name, style: caption),
                ),
                Container(width: size, height: AppSpacing.md, color: t.brand),
              ],
            ),
          ),
      ],
    );
  }
}

class _Radii extends StatelessWidget {
  const _Radii();

  static const _radii = {
    'sm 8': AppRadii.sm,
    'md 14': AppRadii.md,
    'lg 24': AppRadii.lg,
    'xl 32': AppRadii.xl,
    'pill': AppRadii.pill,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final caption = Theme.of(context).textTheme.labelMedium;

    return Row(
      children: [
        for (final MapEntry(key: name, value: radius) in _radii.entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surfaceElevated,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: t.borderStrong),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(name, style: caption),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
