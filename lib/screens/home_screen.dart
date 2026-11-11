import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/match_prediction.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../utils/match_day_selector.dart';
import '../widgets/widgets.dart';

/// Home screen with group stage matches grouped by match date.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.sessionController,
    this.predictionService,
  });

  final SessionController sessionController;
  final PredictionService? predictionService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MatchPrediction> _matches = [];
  late final PredictionService _predictionService =
      widget.predictionService ?? PredictionService();
  bool _isLoading = true;
  int _dayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _matchGroups;
    final visibleGroup = groups.isEmpty ? null : groups[_dayIndex];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.tokens.brandOnSurface,
          backgroundColor: context.tokens.surface,
          onRefresh: _loadMatches,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xl,
                  AppSpacing.screen,
                  AppSpacing.bottomNavClearance,
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverList.list(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bolao 2026',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Fase de grupos',
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                            LogoutCircleButton(
                              sessionController: widget.sessionController,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            HeaderActionButton(
                              tooltip: 'Perfil',
                              icon: PhosphorIcons.user(),
                              onPressed: () => context.push('/profile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        CompetitionStrip(
                          title: 'FIFA World Cup 2026 - Group Stage',
                          matchCount: _matches.length,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_isLoading)
                          const AppLoading()
                        else if (groups.isEmpty)
                          const AppEmptyState(
                            message: 'Nenhum jogo encontrado.',
                          )
                        else ...[
                          RoundHeader(label: visibleGroup!.label),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                    if (!_isLoading && visibleGroup != null) ...[
                      // Lazy: only the cards on screen are built.
                      SliverList.builder(
                        itemCount: visibleGroup.matches.length,
                        itemBuilder: (context, index) {
                          final match = visibleGroup.matches[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child:
                                MatchCard(
                                      match: match,
                                      footer: MatchInfoRow(
                                        icon: PhosphorIcons.clock(),
                                        label: match.kickoffLabel,
                                        trailing: Text(
                                          match.round,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 250.ms)
                                    .slideY(
                                      begin: .08,
                                      end: 0,
                                      duration: 250.ms,
                                    ),
                          );
                        },
                      ),
                      SliverList.list(
                        children: [
                          if (groups.length > 1)
                            DaySelector(
                              index: _dayIndex,
                              count: groups.length,
                              onChanged: (index) =>
                                  setState(() => _dayIndex = index),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MatchDay> get _matchGroups => groupMatchesByKickoffLabel(_matches);

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _predictionService.loadMatches();
      if (!mounted) return;
      final groups = groupMatchesByKickoffLabel(matches);
      setState(() {
        _matches = matches;
        _dayIndex = initialMatchDayIndex(
          groups.map((group) => group.matches).toList(),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (kReleaseMode) {
        setState(() {
          _matches = [];
          _dayIndex = 0;
          _isLoading = false;
        });
        return;
      }
      final groups = groupMatchesByKickoffLabel(mockMatches);
      setState(() {
        _matches = mockMatches;
        _dayIndex = initialMatchDayIndex(
          groups.map((group) => group.matches).toList(),
        );
        _isLoading = false;
      });
    }
  }
}
