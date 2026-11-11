import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/match_prediction.dart';
import '../design_system/design_system.dart';

/// Premium dark match card with team flags, score, and status chip.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.homeScoreOverride,
    this.awayScoreOverride,
    this.footer,
    this.onTap,
  });

  final MatchPrediction match;
  final int? homeScoreOverride;
  final int? awayScoreOverride;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scoreText = _scoreText;

    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _TeamSide(name: match.homeTeam)),
              const SizedBox(width: AppSpacing.md),
              _ScoreColumn(scoreText: scoreText, status: match.status),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _TeamSide(name: match.awayTeam)),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }

  String get _scoreText {
    final homeScore = homeScoreOverride ?? match.homeScore;
    final awayScore = awayScoreOverride ?? match.awayScore;
    if (homeScore == null || awayScore == null) return 'VS';
    return '$homeScore - $awayScore';
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamFlag(teamName: name),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.scoreText, required this.status});

  final String scoreText;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Text(
            scoreText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          MatchStatusChip(status: status),
        ],
      ),
    );
  }
}

/// Circular national team flag rendered from a team name.
class TeamFlag extends StatelessWidget {
  const TeamFlag({super.key, required this.teamName, this.size = 48});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = countryCodeForTeam(teamName);

    if (code == null) {
      return _FlagFallback(teamName: teamName, size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FlagFallback(teamName: teamName, size: size),
          ClipOval(
            child: SvgPicture.asset(
              flagAssetPathForCode(code),
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholderBuilder: (_) =>
                  _FlagFallback(teamName: teamName, size: size),
              errorBuilder: (_, _, _) =>
                  _FlagFallback(teamName: teamName, size: size),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagFallback extends StatelessWidget {
  const _FlagFallback({required this.teamName, required this.size});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: t.surfaceElevated,
      child: Padding(
        // The label scales with the flag: it fills the inner ~56% of it.
        padding: EdgeInsets.all(size * .22),
        child: FittedBox(
          child: Text(
            _fallbackFlagLabel(teamName),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.strong.copyWith(color: t.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped status chip for live, finished, and upcoming matches.
class MatchStatusChip extends StatelessWidget {
  const MatchStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isLive =
        normalized == 'LIVE' || normalized == '1H' || normalized == '2H';
    // Finished matches are neutral; anything not live or finished is
    // scheduled, which is `pending` (docs/DESIGN.md).
    if (isLive) return const AppBadge(label: 'Live', tone: AppBadgeTone.live);
    if (normalized == 'FT') {
      return const AppBadge(label: 'FT', tone: AppBadgeTone.neutral);
    }
    return AppBadge(
      label: status == 'NS' ? 'Today' : status,
      tone: AppBadgeTone.pending,
    );
  }
}

String flagAssetPathForCode(String code) =>
    'assets/flags/${code.toLowerCase()}.svg';

/// Maps national team names to ISO 3166 country codes for flags.
String? countryCodeForTeam(String teamName) {
  final normalized = _normalizeTeamName(teamName);
  return switch (normalized) {
    '' => null,
    'algeria' || 'argelia' => 'DZ',
    'argentina' => 'AR',
    'australia' => 'AU',
    'austria' => 'AT',
    'belgium' || 'belgica' => 'BE',
    'bolivia' => 'BO',
    'bosnia herzegovina' ||
    'bosnia and herzegovina' ||
    'bosnia e herzegovina' => 'BA',
    'brazil' => 'BR',
    'brasil' => 'BR',
    'cabo verde' || 'cape verde' => 'CV',
    'cameroon' || 'camaroes' => 'CM',
    'canada' => 'CA',
    'chile' => 'CL',
    'china' => 'CN',
    'colombia' => 'CO',
    'congo dr' ||
    'dr congo' ||
    'congo democratic republic' ||
    'democratic republic of congo' ||
    'republica democratica do congo' => 'CD',
    'costa rica' => 'CR',
    'cote d ivoire' ||
    'c te d ivoire' ||
    'ivory coast' ||
    'costa do marfim' => 'CI',
    'croatia' || 'croacia' => 'HR',
    'curacao' || 'cura ao' || 'curacau' => 'CW',
    'czech republic' || 'czechia' || 'republica tcheca' => 'CZ',
    'denmark' || 'dinamarca' => 'DK',
    'ecuador' => 'EC',
    'egypt' || 'egito' => 'EG',
    'england' || 'inglaterra' => 'GB-ENG',
    'france' => 'FR',
    'franca' => 'FR',
    'germany' => 'DE',
    'alemanha' => 'DE',
    'ghana' => 'GH',
    'greece' || 'grecia' => 'GR',
    'haiti' => 'HT',
    'hungary' || 'hungria' => 'HU',
    'iran' || 'ir iran' => 'IR',
    'iraq' || 'iraque' => 'IQ',
    'ireland' || 'irlanda' => 'IE',
    'italy' || 'italia' => 'IT',
    'japan' => 'JP',
    'japao' => 'JP',
    'jordan' || 'jordania' => 'JO',
    'korea republic' ||
    'south korea' ||
    'coreia do sul' ||
    'republica da coreia' => 'KR',
    'mexico' => 'MX',
    'morocco' || 'marrocos' => 'MA',
    'netherlands' || 'holanda' || 'paises baixos' => 'NL',
    'new zealand' || 'nova zelandia' => 'NZ',
    'nigeria' => 'NG',
    'norway' || 'noruega' => 'NO',
    'panama' => 'PA',
    'paraguay' || 'paraguai' => 'PY',
    'peru' => 'PE',
    'poland' || 'polonia' => 'PL',
    'portugal' => 'PT',
    'qatar' || 'catar' => 'QA',
    'romania' || 'romenia' => 'RO',
    'russia' => 'RU',
    'saudi arabia' || 'arabia saudita' => 'SA',
    'scotland' || 'escocia' => 'GB-SCT',
    'senegal' => 'SN',
    'serbia' || 'servia' => 'RS',
    'slovakia' || 'eslovaquia' => 'SK',
    'slovenia' || 'eslovenia' => 'SI',
    'south africa' => 'ZA',
    'africa do sul' => 'ZA',
    'spain' || 'espanha' => 'ES',
    'sweden' || 'suecia' => 'SE',
    'switzerland' || 'suica' => 'CH',
    'tunisia' => 'TN',
    'turkey' || 'turkiye' || 'turquia' => 'TR',
    'ukraine' || 'ucrania' => 'UA',
    'united states' || 'usa' || 'usmnt' || 'estados unidos' => 'US',
    'uruguay' => 'UY',
    'uzbekistan' || 'uzbequistao' => 'UZ',
    'venezuela' => 'VE',
    'wales' || 'pais de gales' => 'GB-WLS',
    _ => null,
  };
}

String _normalizeTeamName(String value) {
  final lower = value.trim().toLowerCase();
  final withoutAccents = lower
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ñ', 'n');
  return withoutAccents
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _fallbackFlagLabel(String teamName) {
  final normalized = _normalizeTeamName(teamName);
  if (normalized.isEmpty) return 'TBD';

  final words = normalized.split(' ');
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
