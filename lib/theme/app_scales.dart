/// Theme-independent design scales (docs/DESIGN.md, "Forma e densidade").
///
/// Light and dark share structure: these values never change with the theme.
/// Per-theme colors live in `AppTokens` (app_tokens.dart).
library;

import 'package:flutter/material.dart';

/// Spacing scale: multiples of 4.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Side margin of regular screens.
  static const screen = lg;

  /// Side margin of authentication screens (splash, login).
  static const screenAuth = xl;

  /// Vertical gap between cards in a list.
  static const cardGap = md;

  /// Bottom space a scrollable leaves so content clears the floating
  /// navigation bar.
  static const bottomNavClearance = 120.0;
}

/// Corner radius scale.
abstract final class AppRadii {
  /// Badges, small fields.
  static const sm = 8.0;

  /// Cards, buttons, inputs, snackbar.
  static const md = 14.0;

  /// Navigation bar, bottom sheets.
  static const lg = 24.0;

  /// Highlight containers on login/splash.
  static const xl = 32.0;

  /// Chips, status pills.
  static const pill = 100.0;

  /// Legacy alias of [md]; screens migrate in Checkpoint 4.
  static const card = md;

  /// Legacy alias of [lg]; screens migrate in Checkpoint 4.
  static const nav = lg;
}

/// Fixed component sizes.
abstract final class AppSizes {
  /// Minimum touch target.
  static const minTouchTarget = 48.0;

  /// Height of primary/secondary/outline buttons.
  static const buttonHeight = 52.0;
}

/// Motion durations: short and functional.
abstract final class AppDurations {
  /// State changes (selection, press, toggle).
  static const fast = Duration(milliseconds: 150);

  /// Transitions (expand, slide, page elements).
  static const medium = Duration(milliseconds: 250);

  /// Upper bound for any animation.
  static const slow = Duration(milliseconds: 400);
}

/// Standard alpha values. Use with `color.withValues(alpha: ...)`.
abstract final class AppOpacity {
  /// Dividers, inner item borders (`borderSubtle`).
  static const borderSubtle = .06;

  /// Default card/input border (`border`).
  static const border = .08;

  /// Outline buttons, highlighted borders (`borderStrong`).
  static const borderStrong = .12;

  /// Tonal background of a state (e.g. exact-hit card).
  static const stateFill = .14;

  /// Text selection highlight.
  static const selection = .35;

  /// Disabled content.
  static const disabled = .38;

  /// Border of a state (e.g. exact-hit card).
  static const stateBorder = .70;
}

/// Closed type scale (docs/DESIGN.md, "Tipografia").
///
/// Styles carry no color: the theme applies `textPrimary`/`textSecondary`.
/// Screens read them through `Theme.of(context).textTheme`; the mapping to
/// Material roles is in `AppTheme`.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  /// Score, ranking numbers, the screen's main title. 30 / w900.
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );

  /// Large section headings. 24 / w700.
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  /// AppBar, section titles. 20 / w700.
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// Card titles, buttons. 16 / w700.
  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Running text. 16 / w400.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Secondary text, descriptions. 14 / w400.
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Labels, chips, tabs. 13 / w500.
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Captions, metadata. 12 / w500.
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Button text (same as [titleSmall]).
  static const button = titleSmall;
}

/// Avatar colors. Not interface colors: use only inside the avatar.
///
/// Same values in both themes (they are fills under an icon).
abstract final class AppAvatarPalette {
  static const lime = Color(0xFFC6F135);
  static const green = Color(0xFF00C896);
  static const amber = Color(0xFFD79222);
  static const red = Color(0xFFFF3B30);
  static const blue = Color(0xFF49A7FF);
  static const violet = Color(0xFFB58CFF);

  static const all = [lime, green, amber, red, blue, violet];
}
