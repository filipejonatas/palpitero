import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/design_system.dart';
import '../models/match_prediction.dart';
import '../widgets/widgets.dart';
import 'catalog_samples.dart';
import 'catalog_section.dart';

void _noop() {}
void _ignore(Object? _) {}

PredictionCard _predictionCard({
  MatchPrediction match = CatalogSamples.scheduledMatch,
  UserMatchPrediction? draft,
  UserMatchPrediction? saved,
  bool isSaving = false,
  bool isLocked = false,
}) {
  return PredictionCard(
    match: match,
    draftPrediction: draft,
    savedPrediction: saved,
    isSaving: isSaving,
    isLocked: isLocked,
    onDraftChanged: _ignore,
    onSave: _ignore,
  );
}

Widget _gap(List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0) const SizedBox(height: AppSpacing.cardGap),
        child,
      ],
    ],
  );
}

final domainSections = <CatalogSection>[
  CatalogSection(
    id: 'match_card',
    title: 'MatchCard',
    group: CatalogGroup.domain,
    description: 'Qualquer jogo. O que muda por tela vai no footer.',
    specimens: () => [
      const CatalogSpecimen(
        'agendado (VS, pending)',
        MatchCard(match: CatalogSamples.scheduledMatch),
      ),
      const CatalogSpecimen(
        'ao vivo (live)',
        MatchCard(match: CatalogSamples.liveMatch),
      ),
      CatalogSpecimen(
        'encerrado, tocável, com footer (MatchInfoRow)',
        MatchCard(
          match: CatalogSamples.finishedMatch,
          onTap: _noop,
          footer: MatchInfoRow(
            icon: PhosphorIcons.calendarBlank(),
            label: 'Group Stage - 1',
            trailing: const AppBadge.points(5),
          ),
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'prediction_card',
    title: 'PredictionCard',
    group: CatalogGroup.domain,
    description: 'Formulário de palpite: steppers, pênaltis e confirmar.',
    specimens: () => [
      CatalogSpecimen('novo', _predictionCard()),
      CatalogSpecimen(
        'salvo',
        _predictionCard(
          draft: CatalogSamples.savedPrediction,
          saved: CatalogSamples.savedPrediction,
        ),
      ),
      CatalogSpecimen(
        'salvando (carregando)',
        _predictionCard(draft: CatalogSamples.savedPrediction, isSaving: true),
      ),
      CatalogSpecimen(
        'encerrado (desabilitado)',
        _predictionCard(
          match: CatalogSamples.finishedMatch,
          draft: CatalogSamples.savedPrediction,
          saved: CatalogSamples.savedPrediction,
          isLocked: true,
        ),
      ),
      CatalogSpecimen(
        'mata-mata empatado (pênaltis)',
        _predictionCard(
          match: CatalogSamples.knockoutMatch,
          draft: CatalogSamples.drawPrediction,
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'score_stepper',
    title: 'ScoreStepper',
    group: CatalogGroup.domain,
    description: 'Placar de 0 a 9. Nos limites, o botão do lado desabilita.',
    // Two per row, as in the PredictionCard.
    specimens: () => [
      const CatalogSpecimen(
        'no mínimo e no máximo',
        _StepperPair(
          ScoreStepper(label: 'Brasil', value: 0, onChanged: _ignore),
          ScoreStepper(label: 'Alemanha', value: 9, onChanged: _ignore),
        ),
      ),
      const CatalogSpecimen(
        'normal e desabilitado',
        _StepperPair(
          ScoreStepper(label: 'Brasil', value: 2, onChanged: _ignore),
          ScoreStepper(
            label: 'Alemanha',
            value: 1,
            enabled: false,
            onChanged: _ignore,
          ),
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'match_status',
    title: 'Status, bandeiras e rótulos',
    group: CatalogGroup.domain,
    description:
        'MatchStatusChip, PlayoffStatusBadge, TeamFlag, RoundHeader '
        'e CompetitionStrip.',
    specimens: () => [
      const CatalogSpecimen(
        'MatchStatusChip: LIVE, FT, NS',
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            MatchStatusChip(status: 'LIVE'),
            MatchStatusChip(status: 'FT'),
            MatchStatusChip(status: 'NS'),
          ],
        ),
      ),
      const CatalogSpecimen(
        'PlayoffStatusBadge: live, finished, pending',
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            PlayoffStatusBadge(status: 'live'),
            PlayoffStatusBadge(status: 'finished'),
            PlayoffStatusBadge(status: 'pending'),
          ],
        ),
      ),
      const CatalogSpecimen(
        'TeamFlag: com bandeira e reserva (iniciais)',
        Wrap(
          spacing: AppSpacing.md,
          children: [
            TeamFlag(teamName: 'Brazil'),
            TeamFlag(teamName: 'Japan'),
            TeamFlag(teamName: 'Time Desconhecido'),
          ],
        ),
      ),
      const CatalogSpecimen('RoundHeader', RoundHeader(label: '11 jun')),
      const CatalogSpecimen(
        'CompetitionStrip',
        CompetitionStrip(title: 'Copa do Mundo 2026', matchCount: 4),
      ),
    ],
  ),
  CatalogSection(
    id: 'selectors',
    title: 'DaySelector e RoundSelector',
    group: CatalogGroup.domain,
    description: 'Paginação de dias e de rodadas do mata-mata.',
    specimens: () => [
      const CatalogSpecimen(
        'DaySelector: primeiro dia (anterior desabilitado)',
        DaySelector(index: 0, count: 5, onChanged: _ignore),
      ),
      const CatalogSpecimen(
        'DaySelector: meio',
        DaySelector(index: 2, count: 5, onChanged: _ignore),
      ),
      const CatalogSpecimen(
        'RoundSelector',
        RoundSelector(
          labels: ['RD32', 'RD16', 'Quartas'],
          index: 1,
          onChanged: _ignore,
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'leaderboard_row',
    title: 'LeaderboardRow e AvatarBadge',
    group: CatalogGroup.domain,
    description: 'Jogador no ranking e no confronto do mata-mata.',
    specimens: () => [
      CatalogSpecimen(
        'pódio, normal, minha linha',
        _gap([
          LeaderboardRow.entry(CatalogSamples.podiumEntry),
          LeaderboardRow.entry(CatalogSamples.entry),
          LeaderboardRow.entry(CatalogSamples.myEntry),
        ]),
      ),
      CatalogSpecimen(
        'vencedor do confronto (rankStyle: winner)',
        LeaderboardRow(
          rank: '#1',
          nick: 'Canarinho',
          avatarId: 'cup',
          points: 10,
          rankStyle: LeaderboardRankStyle.winner,
          highlighted: true,
          stats: [
            LeaderboardStat(
              icon: PhosphorIcons.target(),
              label: '2 palpites - 1 exato',
            ),
          ],
        ),
      ),
      const CatalogSpecimen(
        'AvatarBadge: avatar, inicial, inicial sobre elevated, vazio',
        Wrap(
          spacing: AppSpacing.md,
          children: [
            AvatarBadge(avatarId: 'cup'),
            AvatarBadge(name: 'Hexa'),
            AvatarBadge(name: 'Hexa', onElevated: true),
            AvatarBadge(),
          ],
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'prediction_tile',
    title: 'PredictionTile',
    group: CatalogGroup.domain,
    description: 'Palpite salvo como item: público (resultados) e histórico.',
    specimens: () => [
      CatalogSpecimen(
        'public: exato, pontuou, errou',
        _gap([
          PredictionTile.public(
            CatalogSamples.publicPrediction(
              nick: 'Canarinho',
              points: 5,
              exactScore: true,
            ),
          ),
          PredictionTile.public(
            CatalogSamples.publicPrediction(nick: 'Hexa', points: 2),
          ),
          PredictionTile.public(
            CatalogSamples.publicPrediction(nick: 'Zebra', points: 0),
          ),
        ]),
      ),
      CatalogSpecimen(
        'history',
        PredictionTile.history(
          match: CatalogSamples.scheduledMatch,
          prediction: CatalogSamples.savedPrediction,
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'profile',
    title: 'ProfileStatsGrid e HeaderActionButton',
    group: CatalogGroup.domain,
    description: 'Números do Perfil e ações redondas do cabeçalho.',
    specimens: () => [
      const CatalogSpecimen(
        'carregado',
        ProfileStatsGrid(entry: CatalogSamples.myEntry, isLoading: false),
      ),
      const CatalogSpecimen(
        'carregando',
        ProfileStatsGrid(entry: null, isLoading: true),
      ),
      CatalogSpecimen(
        'HeaderActionButton: normal e desabilitado',
        Wrap(
          spacing: AppSpacing.md,
          children: [
            HeaderActionButton(
              tooltip: 'Perfil',
              icon: PhosphorIcons.user(),
              onPressed: _noop,
            ),
            HeaderActionButton(
              tooltip: 'Sair',
              icon: PhosphorIcons.signOut(),
              onPressed: null,
            ),
          ],
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'bracket_matchup',
    title: 'Confronto do mata-mata',
    group: CatalogGroup.domain,
    description: 'MatchupStatusBar, BracketMatchup e PredictionPill.',
    specimens: () => [
      const CatalogSpecimen(
        'MatchupStatusBar: encerrado e pendente',
        Column(
          children: [
            MatchupStatusBar(match: CatalogSamples.finishedDuel),
            SizedBox(height: AppSpacing.cardGap),
            MatchupStatusBar(match: CatalogSamples.pendingDuel),
          ],
        ),
      ),
      CatalogSpecimen(
        'BracketMatchup (vencedor e palpites)',
        BracketMatchup(
          match: CatalogSamples.finishedDuel,
          scoresByUserId: const {},
          roundPredictionResults: CatalogSamples.duelResults,
        ),
      ),
      CatalogSpecimen(
        'PredictionPill: pontuou, sem palpite, a definir',
        Row(
          children: [
            Expanded(
              child: PredictionPill(
                nick: 'Canarinho',
                prediction: CatalogSamples.publicPrediction(
                  nick: 'Canarinho',
                  points: 5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: PredictionPill(nick: 'Hexa')),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: PredictionPill()),
          ],
        ),
      ),
    ],
  ),
  CatalogSection(
    id: 'playoff_bracket',
    title: 'PlayoffBracketView e PlayoffRulesCard',
    group: CatalogGroup.domain,
    description:
        'Chaveamento de 32 e regras. O canvas abre centralizado: '
        'role na horizontal para ver os jogadores.',
    specimens: () => [
      const CatalogSpecimen(
        'BracketSlot: normal, avançou, bye, lado direito',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BracketSlot(
              participant: BracketParticipant(
                seed: 5,
                nick: 'VAR Amigo',
                score: 84,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            BracketSlot(
              participant: BracketParticipant(
                seed: 1,
                nick: 'Canarinho',
                score: 128,
              ),
              isAdvanced: true,
            ),
            SizedBox(height: AppSpacing.sm),
            BracketSlot(
              participant: BracketParticipant(
                seed: 32,
                nick: 'BYE',
                score: 0,
                isBye: true,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            BracketSlot(
              participant: BracketParticipant(
                seed: 12,
                nick: 'Impedido',
                score: 33,
              ),
              alignRight: true,
            ),
          ],
        ),
      ),
      CatalogSpecimen(
        'preview com byes (12/32)',
        PlayoffBracketView.preview(
          participants: CatalogSamples.bracketParticipants,
        ),
      ),
      const CatalogSpecimen('PlayoffRulesCard', PlayoffRulesCard()),
    ],
  ),
];

class _StepperPair extends StatelessWidget {
  const _StepperPair(this.home, this.away);

  final ScoreStepper home;
  final ScoreStepper away;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: home),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: away),
      ],
    );
  }
}
