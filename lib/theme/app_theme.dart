import 'package:flutter/material.dart';

/// Shared design tokens for the Palpitero dark sports UI.
///
/// Legacy, dark-only values still read directly by the screens. They are
/// replaced by per-theme tokens in Checkpoint 3 and removed from the screens
/// in Checkpoint 4 (see docs/DESIGN_SYSTEM_PLAN.md).
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

/// Radius tokens used across cards, chips, and navigation surfaces.
abstract final class AppRadii {
  static const card = 14.0;
  static const nav = 24.0;
  static const pill = 100.0;
}

/// Builds the Palpitero light and dark themes from the same structure.
///
/// Both themes share layout, radii and typography; only colors change
/// (docs/DESIGN.md, "Os dois temas são iguais em estrutura").
abstract final class AppTheme {
  /// Family declared in pubspec.yaml (assets/fonts).
  static const fontFamily = 'Inter';

  /// Theme mode used by the app.
  ///
  /// Stays [ThemeMode.dark] until the screens stop reading the dark-only
  /// [AppColors] (Checkpoint 4); then it becomes [ThemeMode.system].
  static const mode = ThemeMode.dark;

  static ThemeData dark() => _build(_Palette.dark);

  static ThemeData light() => _build(_Palette.light);

  static ThemeData _build(_Palette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brand,
      onPrimaryContainer: p.onBrand,
      inversePrimary: p.inverseBrand,
      // Lima is the only brand color: selection (secondaryContainer, used by
      // SegmentedButton and chips) is lima too.
      secondary: p.brand,
      onSecondary: p.onBrand,
      secondaryContainer: p.brand,
      onSecondaryContainer: p.onBrand,
      error: p.loss,
      onError: p.onLoss,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceDim: p.background,
      surfaceBright: p.surfaceElevated,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceElevated,
      surfaceContainerHighest: p.surfaceElevated,
      outline: p.borderStrong,
      outlineVariant: p.border,
      inverseSurface: p.textPrimary,
      onInverseSurface: p.background,
      shadow: Colors.black,
      scrim: Colors.black,
      // Elevation comes from surface -> surfaceElevated, never from a tint.
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: fontFamily,
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape.copyWith(side: BorderSide(color: p.borderSubtle)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.surfaceElevated,
        selectedColor: p.brand,
        labelStyle: TextStyle(
          color: p.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.borderSubtle, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          minimumSize: const Size.fromHeight(52),
          shape: cardShape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          minimumSize: const Size.fromHeight(50),
          shape: cardShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: cardShape,
          side: BorderSide(color: p.borderStrong),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textSecondary),
        border: _inputBorder(p.border),
        enabledBorder: _inputBorder(p.border),
        disabledBorder: _inputBorder(p.borderSubtle),
        focusedBorder: _inputBorder(p.brand, width: 2),
        errorBorder: _inputBorder(p.loss),
        focusedErrorBorder: _inputBorder(p.loss, width: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: p.textPrimary,
        ),
        actionTextColor: p.brandOnSurface,
        behavior: SnackBarBehavior.floating,
        shape: cardShape,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brandOnSurface,
        selectionHandleColor: p.brandOnSurface,
        selectionColor: p.brand.withValues(alpha: .35),
      ),
      textTheme: base.textTheme
          .apply(
            fontFamily: fontFamily,
            bodyColor: p.textPrimary,
            displayColor: p.textPrimary,
          )
          .copyWith(
            headlineMedium: TextStyle(
              fontFamily: fontFamily,
              color: p.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
            titleLarge: TextStyle(
              fontFamily: fontFamily,
              color: p.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            titleMedium: TextStyle(
              fontFamily: fontFamily,
              color: p.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            bodyLarge: TextStyle(
              fontFamily: fontFamily,
              color: p.textPrimary,
              fontSize: 16,
            ),
            bodyMedium: TextStyle(
              fontFamily: fontFamily,
              color: p.textSecondary,
              fontSize: 14,
            ),
            labelLarge: TextStyle(
              fontFamily: fontFamily,
              color: p.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Color values per theme, as defined in docs/DESIGN.md ("Paleta").
///
/// Private on purpose: Checkpoint 3 exposes them as a ThemeExtension
/// (`context.tokens`). Screens must not depend on this class.
@immutable
final class _Palette {
  const _Palette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.brandOnSurface,
    required this.inverseBrand,
    required this.loss,
    required this.onLoss,
  });

  static const dark = _Palette(
    brightness: Brightness.dark,
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF222222),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A8A8A),
    border: Color(0x14FFFFFF), // branco .08
    borderSubtle: Color(0x0FFFFFFF), // branco .06
    borderStrong: Color(0x1FFFFFFF), // branco .12
    brandOnSurface: Color(0xFFC6F135),
    inverseBrand: Color(0xFF4A6300),
    loss: Color(0xFFFF6B5E),
    onLoss: Color(0xFF0D0D0D),
  );

  static const light = _Palette(
    brightness: Brightness.light,
    background: Color(0xFFF5F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFECEEE8),
    textPrimary: Color(0xFF0D0D0D),
    textSecondary: Color(0xFF5C5C5C),
    border: Color(0x14000000), // preto .08
    borderSubtle: Color(0x0F000000), // preto .06
    borderStrong: Color(0x1F000000), // preto .12
    brandOnSurface: Color(0xFF4A6300),
    inverseBrand: Color(0xFFC6F135),
    loss: Color(0xFFB42318),
    onLoss: Color(0xFFFFFFFF),
  );

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;

  /// Lima as text or icon on a surface (lima has 1.31:1 on white).
  final Color brandOnSurface;
  final Color inverseBrand;
  final Color loss;
  final Color onLoss;

  /// Brand fill, identical in both themes.
  Color get brand => const Color(0xFFC6F135);

  /// Text/icon on [brand].
  Color get onBrand => const Color(0xFF0D0D0D);
}
