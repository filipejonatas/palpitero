import 'package:flutter/material.dart';

/// Opens a modal bottom sheet with the app's look (`surface`, top radius
/// `lg`, drag handle), all set in the theme's `bottomSheetTheme`.
///
/// Content should pad itself with `AppSpacing.screen` on the sides; the
/// drag handle already gives the top space.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: builder,
  );
}
