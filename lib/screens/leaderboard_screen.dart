import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/logout_circle_button.dart';

/// Ranking screen with leaderboard positions, avatars, and points badges.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.sessionController,
    this.leaderboardService,
  });

  final SessionController sessionController;
  final LeaderboardService? leaderboardService;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _entriesPerPage = 10;

  late final LeaderboardService _leaderboardService =
      widget.leaderboardService ?? LeaderboardService();
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final userEntry = _currentUserEntry;
    final topEntries = userEntry == null
        ? _entries
        : _entries.where((entry) => entry.userId != userEntry.userId).toList();
    final totalPages = topEntries.isEmpty
        ? 1
        : (topEntries.length / _entriesPerPage).ceil();
    final safePageIndex = _pageIndex.clamp(0, totalPages - 1);
    final pagedEntries = topEntries
        .skip(safePageIndex * _entriesPerPage)
        .take(_entriesPerPage)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: LogoutCircleButton(
              sessionController: widget.sessionController,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            const AppPageHeader(
              title: 'Leaderboard',
              subtitle: '5 pts por placar exato. 3 pts por vencedor ou empate.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isLoading)
              const AppLoading()
            else ...[
              if (userEntry != null) ...[
                const AppSectionHeader(title: 'Sua posicao'),
                const SizedBox(height: AppSpacing.md),
                LeaderboardTile(entry: userEntry),
                const SizedBox(height: AppSpacing.xl),
              ],
              const AppSectionHeader(title: 'Top palpites'),
              const SizedBox(height: AppSpacing.md),
              if (topEntries.isEmpty)
                const AppEmptyState(message: 'Nenhum palpite registrado ainda.')
              else
                for (final entry in pagedEntries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: LeaderboardTile(
                      entry: entry,
                    ).animate().fadeIn(duration: 220.ms).slideY(begin: .04),
                  ),
              if (topEntries.length > _entriesPerPage) ...[
                const SizedBox(height: AppSpacing.xs),
                _LeaderboardPager(
                  currentPage: safePageIndex + 1,
                  totalPages: totalPages,
                  onPrevious: safePageIndex == 0
                      ? null
                      : () => setState(() => _pageIndex = safePageIndex - 1),
                  onNext: safePageIndex >= totalPages - 1
                      ? null
                      : () => setState(() => _pageIndex = safePageIndex + 1),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  LeaderboardEntry? get _currentUserEntry {
    final user = widget.sessionController.currentUser;
    if (user == null) return null;

    for (final entry in _entries) {
      if (entry.userId == user.id) return entry;
    }

    return null;
  }

  Future<void> _loadLeaderboard() async {
    final user = widget.sessionController.currentUser;
    if (user == null) return;

    try {
      final entries = await _leaderboardService.loadLeaderboard(user);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _pageIndex = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = [_fallbackEntry(user)];
        _pageIndex = 0;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackBar.error(
          context,
          'Nao foi possivel carregar o ranking online.',
        );
      });
    }
  }

  LeaderboardEntry _fallbackEntry(AppUser user) {
    return LeaderboardEntry(
      position: 1,
      userId: user.id,
      nick: user.nick,
      avatarId: user.avatarId,
      photoUrl: user.photoUrl,
      points: 0,
      predictionsCount: 0,
      exactScores: 0,
      isCurrentUser: true,
    );
  }
}

class _LeaderboardPager extends StatelessWidget {
  const _LeaderboardPager({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Pagina anterior',
            onPressed: onPrevious,
            icon: PhosphorIcon(PhosphorIcons.caretLeft()),
          ),
          Expanded(
            child: Text(
              'Pagina $currentPage de $totalPages',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Proxima pagina',
            onPressed: onNext,
            icon: PhosphorIcon(PhosphorIcons.caretRight()),
          ),
        ],
      ),
    );
  }
}

/// A reusable leaderboard row with position, avatar, username, and points.
class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile({super.key, required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final isPodium = entry.position <= 3;

    return AppCard(
      highlight: entry.isCurrentUser ? t.brand : null,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Row(
              children: [
                if (isPodium) ...[
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
                  '#${entry.position}',
                  style: theme.textTheme.titleMedium?.numeric.copyWith(
                    color: isPodium ? t.gold : t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          AvatarBadge(avatarId: entry.avatarId, photoUrl: entry.photoUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.nick, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.target(),
                      size: 14,
                      color: context.tokens.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${entry.predictionsCount} palpites - ${entry.exactScores} exatos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppBadge.points(entry.points),
        ],
      ),
    );
  }
}
