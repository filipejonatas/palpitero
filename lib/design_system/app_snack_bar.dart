import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Feedback messages at the bottom of the screen.
///
/// - [info]: neutral confirmation ("Palpite salvo."), `surfaceElevated`.
/// - [error]: a failure, `error` fill with `onLoss` text. Never `live`
///   (docs/DESIGN.md, "Como escolher a cor certa").
abstract final class AppSnackBar {
  static void info(BuildContext context, String message) {
    _show(context, SnackBar(content: Text(message)));
  }

  static void error(BuildContext context, String message) {
    final t = context.tokens;
    _show(
      context,
      SnackBar(
        backgroundColor: t.error,
        content: Text(message, style: TextStyle(color: t.onLoss)),
      ),
    );
  }

  static void _show(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
