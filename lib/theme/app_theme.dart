import 'package:flutter/material.dart';

import 'app_scales.dart';
import 'app_tokens.dart';

export 'app_scales.dart';
export 'app_tokens.dart';

/// Legacy, dark-only colors still read directly by the screens.
///
/// Do not use in new code: read `context.tokens` instead. Screens migrate in
/// Checkpoint 4 and this class is removed then (docs/DESIGN_SYSTEM_PLAN.md).
abstract final class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF222222);
  static const primaryAccent = Color(0xFFC6F135);
  static const secondaryAccent = Color(0xFF00C896);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8A8A);
  static const liveBadge = Color(0xFFFF3B30);
}

/// Builds the Palpitero light and dark themes from the same structure.
///
/// Both themes share layout, radii and typography; only colors change
/// (docs/DESIGN.md, "Os dois temas são iguais em estrutura").
abstract final class AppTheme {
  /// Family declared in pubspec.yaml (assets/fonts).
  static const fontFamily = AppTypography.fontFamily;

  /// Theme mode used by the app.
  ///
  /// Stays [ThemeMode.dark] until the screens stop reading the dark-only
  /// [AppColors] (Checkpoint 4); then it becomes [ThemeMode.system].
  static const mode = ThemeMode.dark;

  static ThemeData dark() => _build(Brightness.dark, AppTokens.dark);

  static ThemeData light() => _build(Brightness.light, AppTokens.light);

  static ThemeData _build(Brightness brightness, AppTokens t) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.brand,
      onPrimary: t.onBrand,
      primaryContainer: t.brand,
      onPrimaryContainer: t.onBrand,
      inversePrimary: t.inverseBrand,
      // Lima is the only brand color: selection (secondaryContainer, used by
      // SegmentedButton and chips) is lima too.
      secondary: t.brand,
      onSecondary: t.onBrand,
      secondaryContainer: t.brand,
      onSecondaryContainer: t.onBrand,
      error: t.loss,
      onError: t.onLoss,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceDim: t.background,
      surfaceBright: t.surfaceElevated,
      surfaceContainerLowest: t.background,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surfaceElevated,
      surfaceContainerHighest: t.surfaceElevated,
      outline: t.borderStrong,
      outlineVariant: t.border,
      inverseSurface: t.textPrimary,
      onInverseSurface: t.background,
      shadow: Colors.black,
      scrim: Colors.black,
      // Elevation comes from surface -> surfaceElevated, never from a tint.
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      fontFamily: fontFamily,
      extensions: [t],
    );

    final textTheme = _textTheme(t);

    final mdShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );
    const buttonSize = Size.fromHeight(AppSizes.buttonHeight);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: AppTypography.title.copyWith(color: t.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: mdShape.copyWith(side: BorderSide(color: t.borderSubtle)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: t.surfaceElevated,
        selectedColor: t.brand,
        labelStyle: AppTypography.label.copyWith(color: t.textPrimary),
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      dividerTheme: DividerThemeData(color: t.borderSubtle, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: t.onBrand,
          minimumSize: buttonSize,
          shape: mdShape,
          textStyle: AppTypography.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: t.onBrand,
          minimumSize: buttonSize,
          shape: mdShape,
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          minimumSize: buttonSize,
          shape: mdShape,
          side: BorderSide(color: t.borderStrong),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceElevated,
        labelStyle: TextStyle(color: t.textSecondary),
        hintStyle: TextStyle(color: t.textSecondary),
        border: _inputBorder(t.border),
        enabledBorder: _inputBorder(t.border),
        disabledBorder: _inputBorder(t.borderSubtle),
        focusedBorder: _inputBorder(t.brand, width: 2),
        errorBorder: _inputBorder(t.loss),
        focusedErrorBorder: _inputBorder(t.loss, width: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surfaceElevated,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: t.textPrimary,
        ),
        actionTextColor: t.brandOnSurface,
        behavior: SnackBarBehavior.floating,
        shape: mdShape,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.brandOnSurface,
        selectionHandleColor: t.brandOnSurface,
        selectionColor: t.brand.withValues(alpha: AppOpacity.selection),
      ),
    );
  }

  /// Maps the closed scale ([AppTypography]) onto every Material role, so no
  /// text style falls outside it.
  ///
  /// | Material role                       | Scale      |
  /// |-------------------------------------|------------|
  /// | display*, headlineLarge/Medium      | display    |
  /// | headlineSmall, titleLarge           | headline   |
  /// | titleMedium                         | titleSmall |
  /// | titleSmall, labelLarge              | label      |
  /// | bodyLarge                           | body       |
  /// | bodyMedium (textSecondary)          | bodySmall  |
  /// | bodySmall, labelMedium, labelSmall  | caption    |
  static TextTheme _textTheme(AppTokens t) {
    TextStyle primary(TextStyle s) => s.copyWith(color: t.textPrimary);
    final display = primary(AppTypography.display);
    final headline = primary(AppTypography.headline);
    final label = primary(AppTypography.label);
    final caption = primary(AppTypography.caption);
    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: display,
      headlineMedium: display,
      headlineSmall: headline,
      titleLarge: headline,
      titleMedium: primary(AppTypography.titleSmall),
      titleSmall: label,
      bodyLarge: primary(AppTypography.body),
      bodyMedium: AppTypography.bodySmall.copyWith(color: t.textSecondary),
      bodySmall: caption,
      labelLarge: label,
      labelMedium: caption,
      labelSmall: caption,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
