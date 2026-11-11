import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/session_controller.dart';
import '../theme/app_theme.dart';

/// App shell with floating glass bottom navigation for the main tabs.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.sessionController,
    required this.navigationShell,
  });

  final SessionController sessionController;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: t.floatingShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            // Kept after the CP9 review (docs/DESIGN_SYSTEM_PLAN.md): one
            // filter, clipped to the bar. Swap for an opaque surface only if
            // profiling shows raster jank.
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: t.surface.withValues(alpha: AppOpacity.glass),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    _BottomNavItem(
                      tooltip: 'Home',
                      icon: PhosphorIcons.house(),
                      activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                      isActive: navigationShell.currentIndex == 0,
                      onTap: () => _goBranch(0),
                    ),
                    _BottomNavItem(
                      tooltip: 'Matches',
                      icon: PhosphorIcons.calendar(),
                      activeIcon: PhosphorIcons.calendar(
                        PhosphorIconsStyle.fill,
                      ),
                      isActive: navigationShell.currentIndex == 1,
                      onTap: () => _goBranch(1),
                    ),
                    _BottomNavItem(
                      tooltip: 'Ranking',
                      icon: PhosphorIcons.trophy(),
                      activeIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      isActive: navigationShell.currentIndex == 2,
                      onTap: () => _goBranch(2),
                    ),
                    _BottomNavItem(
                      tooltip: 'Mata-Mata',
                      icon: PhosphorIcons.target(),
                      activeIcon: PhosphorIcons.target(PhosphorIconsStyle.fill),
                      isActive: navigationShell.currentIndex == 3,
                      onTap: () => _goBranch(3),
                    ),
                    _BottomNavItem(
                      tooltip: 'Resultados',
                      icon: PhosphorIcons.chartBar(),
                      activeIcon: PhosphorIcons.chartBar(
                        PhosphorIconsStyle.fill,
                      ),
                      isActive: navigationShell.currentIndex == 4,
                      onTap: () => _goBranch(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final String tooltip;
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            height: AppSizes.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? t.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: PhosphorIcon(
              isActive ? activeIcon : icon,
              color: isActive ? t.onBrand : t.textSecondary,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}
