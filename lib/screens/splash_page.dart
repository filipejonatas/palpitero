import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Static trophy splash page shown before entering the app flow.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.isBusy = false, this.errorMessage});

  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenAuth,
            AppSpacing.xxl,
            AppSpacing.screenAuth,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              const Spacer(),
              Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      boxShadow: t.glowShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      child: Image.asset(
                        'assets/images/trophy_icon.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(.8, .8),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 600.ms),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                    'Palpitero',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 420.ms)
                  .slideY(begin: .2, end: 0, duration: 420.ms),
              const SizedBox(height: AppSpacing.sm),
              Text(
                    'Faça seus palpites da Copa 2026',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  )
                  .animate()
                  .fadeIn(delay: 460.ms, duration: 420.ms)
                  .slideY(begin: .2, end: 0, duration: 420.ms),
              const Spacer(),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: t.error),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isBusy ? null : () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isBusy ? 'Carregando...' : 'Começar'),
                      const SizedBox(width: AppSpacing.sm),
                      if (isBusy)
                        SizedBox.square(
                          dimension: AppSizes.spinner,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.onBrand,
                          ),
                        )
                      else
                        PhosphorIcon(PhosphorIcons.arrowRight()),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 420.ms),
            ],
          ),
        ),
      ),
    );
  }
}
