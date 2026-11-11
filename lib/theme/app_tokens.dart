import 'package:flutter/material.dart';

import 'app_scales.dart';

/// Per-theme color and shadow tokens (docs/DESIGN.md, "Paleta").
///
/// Registered in both themes as a [ThemeExtension]. Read it in widgets with
/// `context.tokens`:
///
/// ```dart
/// Container(color: context.tokens.surface)
/// ```
@immutable
final class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.brand,
    required this.onBrand,
    required this.brandOnSurface,
    required this.inverseBrand,
    required this.success,
    required this.loss,
    required this.onLoss,
    required this.live,
    required this.onLive,
    required this.pending,
    required this.gold,
    required this.goldFill,
    required this.onGold,
    required this.floatingShadow,
    required this.glowShadow,
  });

  static const _brand = Color(0xFFC6F135);
  static const _ink = Color(0xFF0D0D0D);
  static const _goldFill = Color(0xFFFFD700);

  static const dark = AppTokens(
    background: _ink,
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF222222),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A8A8A),
    textDisabled: Color(0xFF5C5C5C),
    border: Color(0x14FFFFFF), // white .08
    borderSubtle: Color(0x0FFFFFFF), // white .06
    borderStrong: Color(0x1FFFFFFF), // white .12
    brand: _brand,
    onBrand: _ink,
    brandOnSurface: _brand,
    inverseBrand: Color(0xFF4A6300),
    success: Color(0xFF00C896),
    loss: Color(0xFFFF6B5E),
    onLoss: _ink,
    live: Color(0xFFFF3B30),
    onLive: _ink, // never white on live (3.6:1)
    pending: Color(0xFF49A7FF),
    gold: _goldFill,
    goldFill: _goldFill,
    onGold: _ink,
    floatingShadow: [],
    glowShadow: [
      BoxShadow(color: Color(0x4DFFD700), blurRadius: 40, spreadRadius: 10),
    ],
  );

  static const light = AppTokens(
    background: Color(0xFFF5F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFECEEE8),
    textPrimary: _ink,
    textSecondary: Color(0xFF5C5C5C),
    textDisabled: Color(0xFFA3A3A3),
    border: Color(0x14000000), // black .08
    borderSubtle: Color(0x0F000000), // black .06
    borderStrong: Color(0x1F000000), // black .12
    brand: _brand,
    onBrand: _ink,
    brandOnSurface: Color(0xFF4A6300),
    inverseBrand: _brand,
    success: Color(0xFF007A55),
    loss: Color(0xFFB42318),
    onLoss: Color(0xFFFFFFFF),
    live: Color(0xFFC01F14),
    onLive: Color(0xFFFFFFFF),
    pending: Color(0xFF1A62BA),
    gold: Color(0xFF8A6500),
    goldFill: _goldFill,
    onGold: _ink,
    floatingShadow: [
      BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    glowShadow: [
      BoxShadow(color: Color(0x4DFFD700), blurRadius: 40, spreadRadius: 10),
    ],
  );

  /// Screen background.
  final Color background;

  /// Cards, lists.
  final Color surface;

  /// Inputs, chips, items inside a card, snackbar.
  final Color surfaceElevated;

  final Color textPrimary;

  /// Supporting text, captions.
  final Color textSecondary;

  /// Disabled text (no AA requirement).
  final Color textDisabled;

  /// Default card/input border.
  final Color border;

  /// Dividers, inner item borders.
  final Color borderSubtle;

  /// Outline buttons, highlighted borders.
  final Color borderStrong;

  /// Brand fill: primary button, selected chip, focus. Never text on light.
  final Color brand;

  /// Text/icon on [brand].
  final Color onBrand;

  /// Brand as text or icon on a surface.
  final Color brandOnSurface;
  final Color inverseBrand;

  /// Correct prediction, exact hit, confirmation.
  final Color success;

  /// Wrong prediction, form/network error.
  final Color loss;
  final Color onLoss;

  /// Live match. As text, only on [background] or [surface].
  final Color live;

  /// Text on a filled [live] badge.
  final Color onLive;

  /// Awaiting result, scheduled match, history.
  final Color pending;

  /// 1st place, podium (as text/icon).
  final Color gold;

  /// Gold as a fill (medal, glow). Same in both themes.
  final Color goldFill;

  /// Text/icon on [goldFill].
  final Color onGold;

  /// Floating elements (nav bar, bottom sheet, snackbar). Empty in dark:
  /// elevation there comes from surface + border.
  final List<BoxShadow> floatingShadow;

  /// Gold glow behind the splash/login logo.
  final List<BoxShadow> glowShadow;

  /// Error is the same token as [loss].
  Color get error => loss;

  /// Win is the same token as [success].
  Color get win => success;

  /// Tonal background of a state color (e.g. `stateFill(success)`).
  Color stateFill(Color state) => state.withValues(alpha: AppOpacity.stateFill);

  /// Border of a state color (e.g. `stateBorder(success)`).
  Color stateBorder(Color state) =>
      state.withValues(alpha: AppOpacity.stateBorder);

  @override
  AppTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? borderStrong,
    Color? brand,
    Color? onBrand,
    Color? brandOnSurface,
    Color? inverseBrand,
    Color? success,
    Color? loss,
    Color? onLoss,
    Color? live,
    Color? onLive,
    Color? pending,
    Color? gold,
    Color? goldFill,
    Color? onGold,
    List<BoxShadow>? floatingShadow,
    List<BoxShadow>? glowShadow,
  }) {
    return AppTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandOnSurface: brandOnSurface ?? this.brandOnSurface,
      inverseBrand: inverseBrand ?? this.inverseBrand,
      success: success ?? this.success,
      loss: loss ?? this.loss,
      onLoss: onLoss ?? this.onLoss,
      live: live ?? this.live,
      onLive: onLive ?? this.onLive,
      pending: pending ?? this.pending,
      gold: gold ?? this.gold,
      goldFill: goldFill ?? this.goldFill,
      onGold: onGold ?? this.onGold,
      floatingShadow: floatingShadow ?? this.floatingShadow,
      glowShadow: glowShadow ?? this.glowShadow,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textDisabled: c(textDisabled, other.textDisabled),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      brand: c(brand, other.brand),
      onBrand: c(onBrand, other.onBrand),
      brandOnSurface: c(brandOnSurface, other.brandOnSurface),
      inverseBrand: c(inverseBrand, other.inverseBrand),
      success: c(success, other.success),
      loss: c(loss, other.loss),
      onLoss: c(onLoss, other.onLoss),
      live: c(live, other.live),
      onLive: c(onLive, other.onLive),
      pending: c(pending, other.pending),
      gold: c(gold, other.gold),
      goldFill: c(goldFill, other.goldFill),
      onGold: c(onGold, other.onGold),
      floatingShadow: BoxShadow.lerpList(
        floatingShadow,
        other.floatingShadow,
        t,
      )!,
      glowShadow: BoxShadow.lerpList(glowShadow, other.glowShadow, t)!,
    );
  }
}

/// Short access to the design tokens: `context.tokens.surface`.
extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.dark;
}
