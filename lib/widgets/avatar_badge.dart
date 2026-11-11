import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/avatar_option.dart';
import '../theme/app_theme.dart';

/// Circular user avatar. Shows [photoUrl] when there is one; underneath
/// (and while it loads or if it fails) the fallback is, in order:
/// - the chosen avatar icon ([avatarId]) in its avatar color;
/// - the first letter of [name];
/// - a generic user icon in `textSecondary`.
///
/// The circle is `surfaceElevated`; set [onElevated] when it sits on an
/// elevated card, so it steps back to `background` and stays visible.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    this.avatarId,
    this.photoUrl,
    this.name,
    this.radius = 22,
    this.onElevated = false,
  });

  final String? avatarId;
  final String? photoUrl;
  final String? name;
  final double radius;
  final bool onElevated;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final imageUrl = photoUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: onElevated ? t.background : t.surfaceElevated,
      foregroundColor: t.brandOnSurface,
      foregroundImage: imageUrl == null || imageUrl.isEmpty
          ? null
          : NetworkImage(imageUrl),
      child: _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final id = avatarId;
    if (id != null) {
      final avatar = avatarById(id);
      return PhosphorIcon(avatar.icon, color: avatar.color, size: radius);
    }

    final initial = _initial;
    if (initial != null) {
      return Text(initial, style: Theme.of(context).textTheme.titleMedium);
    }

    return PhosphorIcon(
      PhosphorIcons.userCircle(),
      color: context.tokens.textSecondary,
      size: radius,
    );
  }

  String? get _initial {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return name == null ? null : '?';
    return trimmed.characters.first.toUpperCase();
  }
}
