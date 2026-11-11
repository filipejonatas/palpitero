import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../widgets/widgets.dart';

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
                LeaderboardRow.entry(userEntry),
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
                    child: LeaderboardRow.entry(
                      entry,
                    ).animate().fadeIn(duration: 220.ms).slideY(begin: .04),
                  ),
              if (topEntries.length > _entriesPerPage) ...[
                const SizedBox(height: AppSpacing.xs),
                AppPager(
                  label: 'Pagina ${safePageIndex + 1} de $totalPages',
                  previousTooltip: 'Pagina anterior',
                  nextTooltip: 'Proxima pagina',
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
