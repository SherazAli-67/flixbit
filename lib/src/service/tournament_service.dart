import '../models/tournament_model.dart';
import '../models/match_model.dart';
import '../models/user_tournament_stats.dart';

class TournamentService {
  // Dummy data for tournaments
  static List<Tournament> getDummyTournaments() {
    final now = DateTime.now();
    
    return [
      Tournament(
        id: 'tour_001',
        name: 'Premier League 2024',
        description: 'Predict match outcomes and win exciting prizes',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 23)),
        createdAt: now.subtract(const Duration(days: 10)),
        status: TournamentStatus.ongoing,
        pointsPerCorrectPrediction: 10,
        qualificationThreshold: 0.80,
        totalMatches: 15,
        prizeDescription: '\$500 Cash Prize + Gift Vouchers',
        numberOfWinners: 5,
      ),
      Tournament(
        id: 'tour_002',
        name: 'Champions League',
        description: 'European football championship predictions',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 45)),
        createdAt: now.subtract(const Duration(days: 5)),
        status: TournamentStatus.upcoming,
        pointsPerCorrectPrediction: 15,
        qualificationThreshold: 0.75,
        totalMatches: 12,
        prizeDescription: '\$1000 Grand Prize',
        numberOfWinners: 3,
      ),
      Tournament(
        id: 'tour_003',
        name: 'La Liga Spring Season',
        description: 'Spanish football league predictions',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 17)),
        createdAt: now.subtract(const Duration(days: 8)),
        status: TournamentStatus.ongoing,
        pointsPerCorrectPrediction: 10,
        qualificationThreshold: 0.80,
        totalMatches: 10,
        prizeDescription: '\$300 + Merchandise',
        numberOfWinners: 10,
      ),
    ];
  }

  // Dummy user stats for tournaments
  static Map<String, UserTournamentStats> getDummyUserStats() {
    return {
      'tour_001': UserTournamentStats(
        userId: 'currentUser',
        tournamentId: 'tour_001',
        totalPredictions: 10,
        correctPredictions: 7,
        accuracyPercentage: 70.0,
        totalPointsEarned: 70,
        isQualified: false,
        qualifiedAt: null,
        purchasedPoints: 0,
      ),
      'tour_002': UserTournamentStats(
        userId: 'currentUser',
        tournamentId: 'tour_002',
        totalPredictions: 0,
        correctPredictions: 0,
        accuracyPercentage: 0.0,
        totalPointsEarned: 0,
        isQualified: false,
        qualifiedAt: null,
        purchasedPoints: 0,
      ),
      'tour_003': UserTournamentStats(
        userId: 'currentUser',
        tournamentId: 'tour_003',
        totalPredictions: 5,
        correctPredictions: 4,
        accuracyPercentage: 80.0,
        totalPointsEarned: 40,
        isQualified: true,
        qualifiedAt: DateTime.now().subtract(const Duration(days: 1)),
        purchasedPoints: 0,
      ),
    };
  }

  // Dummy matches for a tournament
  static List<Match> getDummyMatches(String tournamentId) {
    final now = DateTime.now();
    
    if (tournamentId == 'tour_001') {
      return [
        Match(
          id: 'match_001',
          tournamentId: tournamentId,
          homeTeam: 'Manchester City',
          awayTeam: 'Arsenal',
          matchDate: now.add(const Duration(days: 2)),
          matchTime: '19:00',
          venue: 'Etihad Stadium',
          createdAt: now.subtract(const Duration(days: 5)),
          status: MatchStatus.upcoming,
          predictionCloseTime: now.add(const Duration(days: 2)).subtract(const Duration(hours: 1)),
        ),
        Match(
          id: 'match_002',
          tournamentId: tournamentId,
          homeTeam: 'Liverpool',
          awayTeam: 'Chelsea',
          matchDate: now.add(const Duration(days: 3)),
          matchTime: '17:30',
          venue: 'Anfield',
          createdAt: now.subtract(const Duration(days: 5)),
          status: MatchStatus.upcoming,
          predictionCloseTime: now.add(const Duration(days: 3)).subtract(const Duration(hours: 1)),
        ),
        Match(
          id: 'match_003',
          tournamentId: tournamentId,
          homeTeam: 'Manchester United',
          awayTeam: 'Tottenham',
          matchDate: now.subtract(const Duration(days: 1)),
          matchTime: '20:00',
          venue: 'Old Trafford',
          createdAt: now.subtract(const Duration(days: 6)),
          status: MatchStatus.completed,
          homeScore: 2,
          awayScore: 1,
          winner: 'home',
          predictionCloseTime: now.subtract(const Duration(days: 1, hours: 1)),
        ),
      ];
    }
    
    return [];
  }
}
