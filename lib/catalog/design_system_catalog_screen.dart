import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import 'catalog_section.dart';
import 'sections_base.dart';
import 'sections_domain.dart';
import 'sections_tokens.dart';

export 'catalog_section.dart';
export 'sections_base.dart' show CatalogSheetContent;

/// Every catalog section, in the order of docs/DESIGN.md.
final List<CatalogSection> catalogSections = [
  ...tokenSections,
  ...baseSections,
  ...domainSections,
];

/// `/design-system`: every token and component in every state, in both
/// themes. Debug builds only (see `main.dart`).
///
/// Open it on the web at `/#/design-system`, or start the app straight
/// into it with `--dart-define=DESIGN_SYSTEM=true`.
class DesignSystemCatalogScreen extends StatefulWidget {
  const DesignSystemCatalogScreen({super.key});

  @override
  State<DesignSystemCatalogScreen> createState() =>
      _DesignSystemCatalogScreenState();
}

class _DesignSystemCatalogScreenState extends State<DesignSystemCatalogScreen> {
  /// `null` = all groups.
  CatalogGroup? _group;

  /// `system` follows the app; light/dark override it for this screen.
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final section in catalogSections)
        if (_group == null || section.group == _group) section,
    ];

    final screen = Scaffold(
      appBar: AppBar(
        title: const Text('Design system'),
        actions: [
          IconButton(
            tooltip: switch (_mode) {
              ThemeMode.system => 'Tema: sistema',
              ThemeMode.light => 'Tema: claro',
              ThemeMode.dark => 'Tema: escuro',
            },
            icon: PhosphorIcon(switch (_mode) {
              ThemeMode.system => PhosphorIcons.circleHalf(),
              ThemeMode.light => PhosphorIcons.sun(),
              ThemeMode.dark => PhosphorIcons.moon(),
            }),
            onPressed: () => setState(() => _mode = _nextMode(_mode)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'Todos',
                selected: _group == null,
                onTap: () => setState(() => _group = null),
              ),
              for (final group in CatalogGroup.values)
                AppChip(
                  label: group.label,
                  selected: _group == group,
                  onTap: () => setState(() => _group = group),
                ),
            ],
          ),
          for (final section in sections) ...[
            const SizedBox(height: AppSpacing.xxl),
            CatalogSectionView(key: ValueKey(section.id), section: section),
            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
          ],
        ],
      ),
    );

    return switch (_mode) {
      ThemeMode.system => screen,
      ThemeMode.light => Theme(data: AppTheme.light(), child: screen),
      ThemeMode.dark => Theme(data: AppTheme.dark(), child: screen),
    };
  }

  static ThemeMode _nextMode(ThemeMode mode) => switch (mode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
}
