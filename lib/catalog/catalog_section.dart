import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Where a section sits in the catalog (and in docs/DESIGN.md).
enum CatalogGroup {
  tokens('Tokens'),
  base('Base'),
  domain('Domínio');

  const CatalogGroup(this.label);

  final String label;
}

/// One state of a component, shown under a small caption ("Desabilitado",
/// "Carregando"...).
class CatalogSpecimen {
  const CatalogSpecimen(this.label, this.child);

  final String label;
  final Widget child;
}

/// A component (or token family) and every state worth seeing.
///
/// The same section feeds the `/design-system` screen and its golden
/// (`test/goldens/goldens/components/<id>.png`), so what the catalog shows
/// is exactly what the golden protects.
class CatalogSection {
  const CatalogSection({
    required this.id,
    required this.title,
    required this.group,
    required this.specimens,
    this.description,
  });

  /// snake_case; also the golden file name.
  final String id;
  final String title;
  final CatalogGroup group;

  /// One line on when to use it (mirrors the tables in docs/DESIGN.md).
  final String? description;

  /// Built lazily: some specimens (the bracket) are heavy.
  final List<CatalogSpecimen> Function() specimens;
}

/// Renders a [CatalogSection]: title, description and each specimen with
/// its caption.
class CatalogSectionView extends StatelessWidget {
  const CatalogSectionView({super.key, required this.section});

  final CatalogSection section;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: section.title,
          trailing: Text(
            section.group.label,
            style: text.labelMedium?.copyWith(color: t.textSecondary),
          ),
        ),
        if (section.description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(section.description!, style: text.bodyMedium),
        ],
        for (final specimen in section.specimens()) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            specimen.label,
            style: text.labelMedium?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          specimen.child,
        ],
      ],
    );
  }
}
