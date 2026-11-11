import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.icon,
    required this.color,
  });

  final String id;
  final IconData icon;
  final Color color;
}

const avatarOptions = [
  AvatarOption(
    id: 'star',
    icon: PhosphorIconsRegular.star,
    color: AppAvatarPalette.lime,
  ),
  AvatarOption(
    id: 'ball',
    icon: PhosphorIconsRegular.soccerBall,
    color: AppAvatarPalette.green,
  ),
  AvatarOption(
    id: 'cup',
    icon: PhosphorIconsRegular.trophy,
    color: AppAvatarPalette.amber,
  ),
  AvatarOption(
    id: 'target',
    icon: PhosphorIconsRegular.crosshair,
    color: AppAvatarPalette.red,
  ),
  AvatarOption(
    id: 'goal',
    icon: PhosphorIconsRegular.flag,
    color: AppAvatarPalette.blue,
  ),
  AvatarOption(
    id: 'voice',
    icon: PhosphorIconsRegular.megaphone,
    color: AppAvatarPalette.violet,
  ),
];

AvatarOption avatarById(String id) {
  return avatarOptions.firstWhere(
    (avatar) => avatar.id == id,
    orElse: () => avatarOptions.first,
  );
}
