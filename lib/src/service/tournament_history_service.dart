import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prediction_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import '../models/user_tournament_stats.dart';
import '../models/wallet_models.dart';
import '../res/firebase_constants.dart';

/// Service for retrieving user's tournament history and earnings
class TournamentHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get complete tournament history for a user
  static Future<UserTournamentHistory> getUserTournamentHistory({
    required String userId,
    required String tournamentId,
  }) async {
    try {
      // 1. Get tournament details
      final tournamentDoc = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .get();

      if (!tournamentDoc.exists) {
        throw Exception('Tournament not found');
      }

      final tournament = Tournament.fromJson(tournamentDoc.data()!);

      // 2. Get user's tournament stats
      final statsId = '${userId}_$tournamentId';
      final statsDoc = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .doc(statsId)
          .get();

      final stats = statsDoc.exists
          ? UserTournamentStats.fromJson(statsDoc.data()!)
          : null;

      // 3. Get all user's predictions for this tournament
      final predictionsSnapshot = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .where('userId', isEqualTo: userId)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      final predictions = predictionsSnapshot.docs
          .map((doc) => Prediction.fromJson(doc.data()))
          .toList();

      // 4. Get all matches for this tournament
      final matchesSnapshot = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .get();

      final matches = matchesSnapshot.docs
          .map((doc) => Match.fromJson(doc.data()))
          .toList();

      // 5. Get all wallet transactions for this tournament
      final transactionsSnapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: userId)
          .where('source.type', whereIn: [
            'tournamentPrediction',
            'tournamentQualification',
            'tournamentWin',
          ])
          .get();

      final transactions = transactionsSnapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .where((tx) => tx.sourceDetails?['tournamentId'] == tournamentId)
          .toList();

      // 6. Build prediction-match pairs
      final predictionResults = <PredictionResult>[];

      for (var prediction in predictions) {
        final match = matches.firstWhere(
          (m) => m.id == prediction.matchId,
          orElse: () => throw Exception('Match not found'),
        );

        predictionResults.add(PredictionResult(
          prediction: prediction,
          match: match,
        ));
      }

      // 7. Calculate total earnings
      final totalEarnings = transactions
          .where((tx) => tx.type == TransactionType.earn)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      return UserTournamentHistory(
        tournament: tournament,
        stats: stats,
        predictionResults: predictionResults,
        transactions: transactions,
        totalEarnings: totalEarnings.toInt(),
      );
    } catch (e) {
      throw Exception('Failed to get tournament history: $e');
    }
  }

  /// Get all tournaments a user has participated in
  static Future<List<TournamentSummary>> getUserTournamentsList(String userId) async {
    try {
      // Get all user's tournament stats
      final statsSnapshot = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final summaries = <TournamentSummary>[];

      for (var statDoc in statsSnapshot.docs) {
        final stats = UserTournamentStats.fromJson(statDoc.data());

        // Get tournament details
        final tournamentDoc = await _firestore
            .collection(FirebaseConstants.tournamentsCollection)
            .doc(stats.tournamentId)
            .get();

        if (tournamentDoc.exists) {
          final tournament = Tournament.fromJson(tournamentDoc.data()!);

          // Get earnings for this tournament
          final transactionsSnapshot = await _firestore
              .collection('wallet_transactions')
              .where('user_id', isEqualTo: userId)
              .where('source.type', whereIn: [
                'tournamentPrediction',
                'tournamentQualification',
                'tournamentWin',
              ])
              .get();

          final tournamentTransactions = transactionsSnapshot.docs
              .map((doc) => WalletTransaction.fromFirestore(doc))
              .where((tx) => tx.sourceDetails?['tournamentId'] == stats.tournamentId)
              .toList();

          final earnings = tournamentTransactions
              .where((tx) => tx.type == TransactionType.earn)
              .fold<double>(0, (sum, tx) => sum + tx.amount);

          summaries.add(TournamentSummary(
            tournament: tournament,
            stats: stats,
            totalEarnings: earnings.toInt(),
            transactionCount: tournamentTransactions.length,
          ));
        }
      }

      // Sort by most recent first
      summaries.sort((a, b) => b.tournament.startDate.compareTo(a.tournament.startDate));

      return summaries;
    } catch (e) {
      throw Exception('Failed to get tournaments list: $e');
    }
  }

  /// Get earnings breakdown for a tournament
  static Future<TournamentEarningsBreakdown> getTournamentEarnings({
    required String userId,
    required String tournamentId,
  }) async {
    try {
      // Get all transactions for this tournament
      final transactionsSnapshot = await _firestore
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: userId)
          .get();

      final tournamentTransactions = transactionsSnapshot.docs
          .map((doc) => WalletTransaction.fromFirestore(doc))
          .where((tx) {
            if (tx.sourceDetails == null) return false;
            return tx.sourceDetails!['tournamentId'] == tournamentId;
          })
          .toList();

      // Calculate breakdown
      int predictionPoints = 0;
      int qualificationBonus = 0;
      int winnerBonus = 0;

      for (var tx in tournamentTransactions) {
        if (tx.type != TransactionType.earn) continue;

        switch (tx.source) {
          case TransactionSource.tournamentPrediction:
            predictionPoints += tx.amount.toInt();
            break;
          case TransactionSource.tournamentQualification:
            qualificationBonus += tx.amount.toInt();
            break;
          case TransactionSource.tournamentWin:
            winnerBonus += tx.amount.toInt();
            break;
          default:
            break;
        }
      }

      return TournamentEarningsBreakdown(
        predictionPoints: predictionPoints,
        qualificationBonus: qualificationBonus,
        winnerBonus: winnerBonus,
        total: predictionPoints + qualificationBonus + winnerBonus,
        transactions: tournamentTransactions,
      );
    } catch (e) {
      throw Exception('Failed to get earnings breakdown: $e');
    }
  }
}

/// Model for tournament history data
class UserTournamentHistory {
  final Tournament tournament;
  final UserTournamentStats? stats;
  final List<PredictionResult> predictionResults;
  final List<WalletTransaction> transactions;
  final int totalEarnings;

  UserTournamentHistory({
    required this.tournament,
    required this.stats,
    required this.predictionResults,
    required this.transactions,
    required this.totalEarnings,
  });

  /// Get predictions by status
  List<PredictionResult> get correctPredictions =>
      predictionResults.where((pr) => pr.prediction.isCorrect == true).toList();

  List<PredictionResult> get wrongPredictions =>
      predictionResults.where((pr) => pr.prediction.isCorrect == false).toList();

  List<PredictionResult> get pendingPredictions =>
      predictionResults.where((pr) => pr.prediction.isCorrect == null).toList();

  /// Get exact score predictions
  List<PredictionResult> get exactScorePredictions =>
      predictionResults.where((pr) {
        return pr.prediction.isCorrect == true &&
            pr.prediction.predictedHomeScore == pr.match.homeScore &&
            pr.prediction.predictedAwayScore == pr.match.awayScore;
      }).toList();
}

/// Model for prediction with actual match result
class PredictionResult {
  final Prediction prediction;
  final Match match;

  PredictionResult({
    required this.prediction,
    required this.match,
  });

  /// Check if prediction was correct
  bool get wasCorrect => prediction.isCorrect == true;

  /// Check if it was exact score
  bool get wasExactScore {
    return wasCorrect &&
        prediction.predictedHomeScore == match.homeScore &&
        prediction.predictedAwayScore == match.awayScore;
  }

  /// Get points earned
  int get pointsEarned => prediction.pointsEarned;

  /// Get readable result
  String get resultText {
    if (prediction.isCorrect == null) return 'Pending';
    if (wasExactScore) return 'Correct (Exact Score!)';
    if (wasCorrect) return 'Correct';
    return 'Wrong';
  }

  /// Get prediction vs actual comparison
  String get comparisonText {
    final predictedScore = prediction.predictedHomeScore != null
        ? '${prediction.predictedHomeScore}-${prediction.predictedAwayScore}'
        : prediction.predictedWinner;

    final actualScore = match.homeScore != null
        ? '${match.homeScore}-${match.awayScore}'
        : match.winner ?? 'TBD';

    return 'Predicted: $predictedScore | Actual: $actualScore';
  }
}

/// Model for tournament summary (list view)
class TournamentSummary {
  final Tournament tournament;
  final UserTournamentStats stats;
  final int totalEarnings;
  final int transactionCount;

  TournamentSummary({
    required this.tournament,
    required this.stats,
    required this.totalEarnings,
    required this.transactionCount,
  });
}

/// Model for earnings breakdown
class TournamentEarningsBreakdown {
  final int predictionPoints;
  final int qualificationBonus;
  final int winnerBonus;
  final int total;
  final List<WalletTransaction> transactions;

  TournamentEarningsBreakdown({
    required this.predictionPoints,
    required this.qualificationBonus,
    required this.winnerBonus,
    required this.total,
    required this.transactions,
  });

  /// Get percentage breakdown
  Map<String, double> get percentageBreakdown {
    if (total == 0) return {};

    return {
      'predictions': (predictionPoints / total) * 100,
      'qualification': (qualificationBonus / total) * 100,
      'winner': (winnerBonus / total) * 100,
    };
  }
}











