import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Knockout scoring and tie-break rules, as bullet lines in a card.
class PlayoffRulesCard extends StatelessWidget {
  const PlayoffRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pontuação do mata-mata',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const _RuleLine(text: 'Base: 5 / 7 / 10 pts'),
          const _RuleLine(text: 'Semifinal: 10 / 14 / 20 pts'),
          const _RuleLine(
            text: 'Terceiro: 13 / 18 / 25 pts; final: 15 / 21 / 30 pts',
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: context.tokens.border, height: 18),
          const _RuleLine(
            text:
                'Seed é a posição no ranking geral no fechamento da chave. Se faltar player, os melhores seeds recebem bye e avançam direto.',
          ),
          const _RuleLine(
            text: 'Em empate de pontos no confronto, passa o seed mais alto.',
          ),
          const _RuleLine(
            text: 'A disputa começa a contar em 28/06, na fase 1/16 da Copa.',
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  static const _bulletSize = 6.0;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _bulletSize,
            height: _bulletSize,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.tokens.brandOnSurface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
