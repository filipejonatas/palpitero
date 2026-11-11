import '../models/leaderboard_entry.dart';
import '../models/match_prediction.dart';
import '../models/playoff.dart';
import '../widgets/widgets.dart';

/// Fixed sample data for the catalog. Widgets read status from the data,
/// not the clock, so goldens stay stable. Group-stage kickoffs must be
/// before 2026-06-28: from then on `isPlayoffMatch` treats a match as
/// knockout (and the form asks for penalties).
abstract final class CatalogSamples {
  static const scheduledMatch = MatchPrediction(
    fixtureId: 1,
    round: 'Group Stage - 1',
    kickoffLabel: '11 jun, 16:00',
    kickoffAt: '2026-06-11T19:00:00Z',
    homeTeam: 'Brazil',
    awayTeam: 'Germany',
    status: 'NS',
  );

  static const liveMatch = MatchPrediction(
    fixtureId: 2,
    round: 'Group Stage - 1',
    kickoffLabel: '11 jun, 19:00',
    kickoffAt: '2026-06-11T22:00:00Z',
    homeTeam: 'Argentina',
    awayTeam: 'France',
    status: 'LIVE',
    homeScore: 1,
    awayScore: 0,
  );

  static const finishedMatch = MatchPrediction(
    fixtureId: 3,
    round: 'Group Stage - 1',
    kickoffLabel: '11 jun, 13:00',
    kickoffAt: '2026-06-11T16:00:00Z',
    homeTeam: 'Mexico',
    awayTeam: 'South Africa',
    status: 'FT',
    homeScore: 2,
    awayScore: 1,
  );

  /// Knockout match: a draw asks for the penalty winner.
  static const knockoutMatch = MatchPrediction(
    fixtureId: 4,
    round: 'Round of 32',
    kickoffLabel: '28 jun, 16:00',
    kickoffAt: '2099-06-28T19:00:00Z',
    homeTeam: 'Spain',
    awayTeam: 'Portugal',
    status: 'NS',
  );

  static const savedPrediction = UserMatchPrediction(
    pick: MatchPick.home,
    homeScore: 2,
    awayScore: 1,
  );

  static const drawPrediction = UserMatchPrediction(
    pick: MatchPick.draw,
    qualifiedPick: MatchPick.away,
    homeScore: 1,
    awayScore: 1,
  );

  static const podiumEntry = LeaderboardEntry(
    position: 1,
    userId: 'canarinho',
    nick: 'Canarinho',
    avatarId: 'cup',
    points: 128,
    predictionsCount: 24,
    exactScores: 7,
  );

  static const entry = LeaderboardEntry(
    position: 5,
    userId: 'var',
    nick: 'VAR Amigo',
    avatarId: 'voice',
    points: 84,
    predictionsCount: 16,
    exactScores: 2,
  );

  static const myEntry = LeaderboardEntry(
    position: 6,
    userId: 'me',
    nick: 'Você',
    avatarId: 'star',
    points: 72,
    predictionsCount: 14,
    exactScores: 2,
    isCurrentUser: true,
  );

  static PublicPredictionResult publicPrediction({
    required String nick,
    required int points,
    bool exactScore = false,
  }) {
    return PublicPredictionResult(
      userId: nick,
      nick: nick,
      avatarId: 'cup',
      pick: MatchPick.home,
      predictedHomeScore: 2,
      predictedAwayScore: 1,
      points: points,
      exactScore: exactScore,
      correctPick: points > 0,
    );
  }

  static const participantA = PlayoffParticipant(
    userId: 'a',
    seed: 1,
    nick: 'Canarinho',
    avatarId: 'cup',
    rankingPoints: 128,
  );

  static const participantB = PlayoffParticipant(
    userId: 'b',
    seed: 32,
    nick: 'Hexa',
    avatarId: 'ball',
    rankingPoints: 31,
  );

  static const finishedDuel = PlayoffMatch(
    id: 'rd32-1',
    round: 'RD32',
    roundIndex: 0,
    position: 1,
    status: 'finished',
    isBye: false,
    participantA: participantA,
    participantB: participantB,
    winnerParticipantId: 'a',
  );

  static const pendingDuel = PlayoffMatch(
    id: 'rd32-2',
    round: 'RD32',
    roundIndex: 0,
    position: 2,
    status: 'pending',
    isBye: false,
    participantA: participantA,
    participantB: participantB,
  );

  static final duelResults = [
    MatchPredictionResults(
      fixtureId: 1,
      round: 'Round of 32',
      homeTeam: 'Brazil',
      awayTeam: 'France',
      status: 'FT',
      homeScore: 2,
      awayScore: 1,
      predictions: [publicPrediction(nick: 'Canarinho', points: 5)],
    ),
  ];

  /// Ranking seeds for the bracket preview: 12 of 32 places, so some
  /// players face a bye.
  static const bracketParticipants = [
    BracketParticipant(seed: 1, nick: 'Canarinho', score: 128),
    BracketParticipant(seed: 2, nick: 'HexaVem', score: 116),
    BracketParticipant(seed: 3, nick: 'Mestre', score: 104),
    BracketParticipant(seed: 4, nick: 'Zebra Hunter', score: 91),
    BracketParticipant(seed: 5, nick: 'VAR Amigo', score: 84),
    BracketParticipant(seed: 6, nick: 'Você', score: 72),
    BracketParticipant(seed: 7, nick: 'Craque', score: 66),
    BracketParticipant(seed: 8, nick: 'Golaço', score: 60),
    BracketParticipant(seed: 9, nick: 'Lateral', score: 52),
    BracketParticipant(seed: 10, nick: 'Pênalti', score: 47),
    BracketParticipant(seed: 11, nick: 'Escanteio', score: 40),
    BracketParticipant(seed: 12, nick: 'Impedido', score: 33),
  ];
}
