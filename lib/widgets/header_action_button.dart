import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Round icon action in a screen header or AppBar (Sair, Perfil):
/// `surfaceElevated` with a `border`, icon in `brandOnSurface`.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final PhosphorIconData icon;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: t.surfaceElevated,
        foregroundColor: t.brandOnSurface,
        disabledForegroundColor: t.textDisabled,
        shape: const CircleBorder(),
        side: BorderSide(color: t.border),
      ),
      icon: PhosphorIcon(icon),
    );
  }
}
