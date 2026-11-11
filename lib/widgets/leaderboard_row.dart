import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import '../models/leaderboard_entry.dart';
import 'avatar_badge.dart';

/// How the rank column ("#3") of a [LeaderboardRow] is colored.
enum LeaderboardRankStyle {
  /// `textPrimary`.
  normal,

  /// Top 3: trophy + rank in `gold` (docs/DESIGN.md, "Pódio").
  podium,

  /// Winner of a matchup: rank in `brandOnSurface`.
  winner,
}

/// One line of stats under the player's nick: small icon + text.
class LeaderboardStat {
  const LeaderboardStat({required this.icon, required this.label});

  final PhosphorIconData icon;
  final String label;
}

/// A player in a ranking: rank, avatar, nick, stat lines and points.
/// Used by the leaderboard (one per entry) and by the knockout matchup
/// (each competitor).
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.nick,
    required this.points,
    this.avatarId,
    this.photoUrl,
    this.stats = const [],
    this.rankStyle = LeaderboardRankStyle.normal,
    this.highlighted = false,
    this.pointsHighlighted = true,
  });

  /// A leaderboard entry: podium for the top 3, highlighted when it is
  /// the current user.
  LeaderboardRow.entry(LeaderboardEntry entry, {Key? key})
    : this(
        key: key,
        rank: '#${entry.position}',
        nick: entry.nick,
        points: entry.points,
        avatarId: entry.avatarId,
        photoUrl: entry.photoUrl,
        rankStyle: entry.position <= 3
            ? LeaderboardRankStyle.podium
            : LeaderboardRankStyle.normal,
        highlighted: entry.isCurrentUser,
        stats: [
          LeaderboardStat(
            icon: PhosphorIcons.target(),
            label:
                '${entry.predictionsCount} palpites - ${entry.exactScores} exatos',
          ),
        ],
      );

  /// Rank text, e.g. "#3" or "BYE".
  final String rank;
  final String nick;
  final int points;
  final String? avatarId;
  final String? photoUrl;
  final List<LeaderboardStat> stats;
  final LeaderboardRankStyle rankStyle;

  /// "Me" / winner: `stateFill(brand)` card.
  final bool highlighted;

  /// `false` shows the points pill neutral (nothing scored yet).
  final bool pointsHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final rankColor = switch (rankStyle) {
      LeaderboardRankStyle.normal => t.textPrimary,
      LeaderboardRankStyle.podium => t.gold,
      LeaderboardRankStyle.winner => t.brandOnSurface,
    };

    return AppCard(
      highlight: highlighted ? t.brand : null,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Row(
              children: [
                if (rankStyle == LeaderboardRankStyle.podium) ...[
                  Tooltip(
                    message: 'Top 3',
                    child: PhosphorIcon(
                      PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      size: 14,
                      color: t.gold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  rank,
                  style: theme.textTheme.titleMedium?.numeric.copyWith(
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
          AvatarBadge(avatarId: avatarId ?? 'target', photoUrl: photoUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nick,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                for (final stat in stats) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _StatLine(stat: stat),
                ],
              ],
            ),
          ),
          AppBadge.points(points, highlighted: pointsHighlighted),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.stat});

  final LeaderboardStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(stat.icon, size: 14, color: context.tokens.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
