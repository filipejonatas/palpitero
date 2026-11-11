import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual weight of an [AppButton] (docs/DESIGN.md, "Componentes").
enum AppButtonVariant {
  /// The screen's main action: lima fill. One per area.
  primary,

  /// Alternative action with the same weight as primary but no brand
  /// (e.g. "Continuar com o Google"): `surfaceElevated` + `border`.
  secondary,

  /// Lower-priority action next to a primary one: `borderStrong` outline.
  outline,

  /// Inline action, link-like: `brandOnSurface` text, no container.
  text,
}

/// The app's only button. Wraps the Material buttons, so semantics, focus
/// and ripple stay native; shape, height and text come from the theme.
///
/// - Disabled: `onPressed: null`.
/// - Loading: `isLoading: true` disables the button and shows a spinner in
///   place of the icon. Pass a loading label if the text should change.
///
/// ```dart
/// AppButton(
///   label: isSaving ? 'Salvando...' : 'Salvar',
///   icon: PhosphorIcon(PhosphorIcons.floppyDisk()),
///   isLoading: isSaving,
///   onPressed: save,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.isLoading = false,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Usually a `PhosphorIcon`; any widget works (e.g. a brand logo).
  final Widget? icon;

  /// `IconAlignment.end` puts the icon after the label ("Começar →").
  final IconAlignment iconAlignment;
  final bool isLoading;

  /// Fills the available width. Text buttons default to their own width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final leading = isLoading ? const _ButtonSpinner() : icon;
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        onPressed: callback,
        icon: leading,
        iconAlignment: iconAlignment,
        label: text,
      ),
      AppButtonVariant.secondary => FilledButton.icon(
        onPressed: callback,
        style: _secondaryStyle(context.tokens),
        icon: leading,
        iconAlignment: iconAlignment,
        label: text,
      ),
      AppButtonVariant.outline => OutlinedButton.icon(
        onPressed: callback,
        icon: leading,
        iconAlignment: iconAlignment,
        label: text,
      ),
      AppButtonVariant.text => TextButton.icon(
        onPressed: callback,
        icon: leading,
        iconAlignment: iconAlignment,
        label: text,
      ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  static ButtonStyle _secondaryStyle(AppTokens t) {
    return FilledButton.styleFrom(
      backgroundColor: t.surfaceElevated,
      foregroundColor: t.textPrimary,
      side: BorderSide(color: t.border),
    );
  }
}

/// Spinner that takes the button's current foreground color (Material
/// buttons expose it through [IconTheme]), so it reads in every state.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.spinner,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.spinnerStroke,
        color: IconTheme.of(context).color,
      ),
    );
  }
}
