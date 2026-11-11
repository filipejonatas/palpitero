import '../models/playoff.dart';

/// Seed order of the 32 first-round slots, top to bottom (left half, then
/// right half). Consecutive pairs play each other.
const playoffSeedOrder = <int>[
  1, 32, 16, 17, 8, 25, 9, 24, //
  4, 29, 13, 20, 5, 28, 12, 21, //
  2, 31, 15, 18, 7, 26, 10, 23, //
  3, 30, 14, 19, 6, 27, 11, 22, //
];

/// One knockout round and its matches, sorted by position.
class PlayoffRound {
  const PlayoffRound({
    required this.code,
    required this.label,
    required this.matches,
  });

  final String code;
  final String label;
  final List<PlayoffMatch> matches;
}

/// Groups [matches] by round, in bracket order (RD32 first).
List<PlayoffRound> groupPlayoffRounds(List<PlayoffMatch> matches) {
  final grouped = <String, List<PlayoffMatch>>{};
  for (final match in matches) {
    grouped.putIfAbsent(match.round, () => []).add(match);
  }

  return grouped.entries
      .map(
        (entry) => PlayoffRound(
          code: entry.key,
          label: playoffRoundLabel(entry.key),
          matches: entry.value
            ..sort((a, b) => a.position.compareTo(b.position)),
        ),
      )
      .toList()
    ..sort(
      (a, b) => playoffRoundOrder(a.code).compareTo(playoffRoundOrder(b.code)),
    );
}

/// First round built from seeds, for a bracket that has no matches yet.
List<PlayoffMatch> buildFirstRoundFallback(
  List<PlayoffParticipant> participants,
) {
  final bySeed = {
    for (final participant in participants) participant.seed: participant,
  };
  final matches = <PlayoffMatch>[];
  for (var index = 0; index < playoffSeedOrder.length; index += 2) {
    matches.add(
      PlayoffMatch(
        id: 'rd32-${index ~/ 2 + 1}',
        round: 'RD32',
        roundIndex: 0,
        position: index ~/ 2 + 1,
        participantA: bySeed[playoffSeedOrder[index]],
        participantB: bySeed[playoffSeedOrder[index + 1]],
        status: 'pending',
        isBye: bySeed[playoffSeedOrder[index + 1]] == null,
      ),
    );
  }
  return matches;
}

String playoffRoundLabel(String round) {
  final normalized = round.trim().toUpperCase();
  return switch (normalized) {
    'RD32' || 'R32' || 'ROUND_OF_32' => 'RD32',
    'RD16' || 'R16' || 'ROUND_OF_16' => 'RD16',
    'QF' || 'QUARTER' || 'QUARTER_FINAL' => 'Quartas',
    'SF' || 'SEMI' || 'SEMI_FINAL' => 'Semis',
    'F' || 'FINAL' => 'Final',
    _ => round,
  };
}

int playoffRoundOrder(String round) {
  final normalized = round.trim().toUpperCase();
  return switch (normalized) {
    'RD32' || 'R32' || 'ROUND_OF_32' => 0,
    'RD16' || 'R16' || 'ROUND_OF_16' => 1,
    'QF' || 'QUARTER' || 'QUARTER_FINAL' => 2,
    'SF' || 'SEMI' || 'SEMI_FINAL' => 3,
    'F' || 'FINAL' => 4,
    _ => 99,
  };
}

/// Whether a fixture round name and a bracket round code are the same round.
bool isSamePlayoffRound(String matchRound, String selectedRound) {
  return _roundKey(matchRound) == _roundKey(selectedRound);
}

String _roundKey(String round) {
  final normalized = round.trim().toUpperCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  return switch (normalized) {
    'RD32' || 'R32' || 'ROUND_OF_32' || '1/16' || '16_AVOS' => 'round_of_32',
    'RD16' || 'R16' || 'ROUND_OF_16' || '1/8' || 'OITAVAS' => 'round_of_16',
    'QF' ||
    'QUARTER' ||
    'QUARTER_FINAL' ||
    'QUARTER_FINALS' ||
    'QUARTAS' => 'quarter_final',
    'SF' || 'SEMI' || 'SEMI_FINAL' || 'SEMI_FINALS' || 'SEMIS' => 'semi_final',
    'F' || 'FINAL' => 'final',
    _ => normalized.toLowerCase(),
  };
}

/// "RD32 #3 - Nick x Nick", used in the matchup picker and status bar.
String playoffMatchLabel(PlayoffMatch match) {
  final participantA = match.participantA?.nick ?? 'A definir';
  final participantB = match.participantB?.nick ?? 'A definir';
  return '${match.round} #${match.position} - $participantA x $participantB';
}
