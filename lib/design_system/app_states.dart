import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Centered spinner for a section or screen that is loading.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xxxl),
  });

  /// Space around the spinner; use a smaller value inside a section.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// "Nothing here yet" message inside a card (was `_SurfaceMessage`).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      width: double.infinity,
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Something failed to load. Message in a card with an `error` icon and,
/// when [onRetry] is given, a "Tentar novamente" action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AppCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(
                PhosphorIcons.warningCircle(),
                size: AppSizes.iconSm,
                color: t.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(
              label: 'Tentar novamente',
              icon: PhosphorIcon(PhosphorIcons.arrowClockwise()),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
