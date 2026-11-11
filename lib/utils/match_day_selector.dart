import '../models/match_prediction.dart';

int initialMatchDayIndex(
  List<List<MatchPrediction>> matchDays, {
  DateTime? now,
}) {
  if (matchDays.isEmpty) return 0;

  final reference = now ?? DateTime.now();
  final today = _dateOnly(reference.toLocal());

  for (var index = 0; index < matchDays.length; index++) {
    if (matchDays[index].any((match) => _matchDate(match) == today)) {
      return index;
    }
  }

  for (var index = 0; index < matchDays.length; index++) {
    final hasFutureMatch = matchDays[index].any((match) {
      final date = _matchDate(match);
      return date != null && date.isAfter(today);
    });
    if (hasFutureMatch) return index;
  }

  for (var index = matchDays.length - 1; index >= 0; index--) {
    if (matchDays[index].any((match) => _matchDate(match) != null)) {
      return index;
    }
  }

  return 0;
}

DateTime? _matchDate(MatchPrediction match) {
  final kickoff = DateTime.tryParse(match.kickoffAt);
  if (kickoff == null) return null;
  return _dateOnly(kickoff.toLocal());
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

/// Matches played on the same day, with the label shown above them.
class MatchDay {
  const MatchDay({required this.label, required this.matches});

  final String label;
  final List<MatchPrediction> matches;
}

/// Groups by the date part of `kickoffLabel` ("11 jun, 16:00" -> "11 jun").
List<MatchDay> groupMatchesByKickoffLabel(List<MatchPrediction> matches) {
  final days = <String, List<MatchPrediction>>{};
  for (final match in matches) {
    days.putIfAbsent(_kickoffLabelDay(match), () => []).add(match);
  }
  return [
    for (final entry in days.entries)
      MatchDay(label: entry.key, matches: entry.value),
  ];
}

/// Groups by the local calendar day of `kickoffAt`, falling back to the
/// label when the date is missing. Labels read "11 jun".
List<MatchDay> groupMatchesByKickoffDate(List<MatchPrediction> matches) {
  final days = <String, MatchDay>{};
  for (final match in matches) {
    final kickoff = DateTime.tryParse(match.kickoffAt)?.toLocal();
    final key = kickoff == null
        ? _kickoffLabelDay(match)
        : '${kickoff.year}-${_twoDigits(kickoff.month)}-${_twoDigits(kickoff.day)}';
    final label = kickoff == null
        ? _kickoffLabelDay(match)
        : '${_twoDigits(kickoff.day)} ${_monthLabel(kickoff.month)}';
    days
        .putIfAbsent(key, () => MatchDay(label: label, matches: []))
        .matches
        .add(match);
  }
  return days.values.toList();
}

String _kickoffLabelDay(MatchPrediction match) {
  final labelParts = match.kickoffLabel.split(',');
  if (labelParts.isEmpty) return 'Dia do jogo';
  return labelParts.first.trim();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _monthLabel(int month) {
  return switch (month) {
    1 => 'jan',
    2 => 'fev',
    3 => 'mar',
    4 => 'abr',
    5 => 'mai',
    6 => 'jun',
    7 => 'jul',
    8 => 'ago',
    9 => 'set',
    10 => 'out',
    11 => 'nov',
    12 => 'dez',
    _ => '',
  };
}
