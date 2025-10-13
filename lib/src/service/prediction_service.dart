import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prediction_model.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';
import '../models/user_tournament_stats.dart';
import '../models/flixbit_transaction_model.dart';
import '../res/firebase_constants.dart';
import 'flixbit_points_manager.dart';

class PredictionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a prediction for a match
  static Future<bool> submitPrediction({
    required String userId,
    required String tournamentId,
    required Match match,
    required String predictedWinner,
    int? predictedHomeScore,
    int? predictedAwayScore,
  }) async {
    try {
      // Check if prediction window is still open
      if (!match.isPredictionOpen) {
        throw Exception('Prediction window has closed for this match');
      }

      // Check if user already predicted this match
      final predictionId = '${userId}_${match.id}';
      final existing = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .doc(predictionId)
          .get();

      if (existing.exists) {
        throw Exception('You have already predicted this match');
      }

      // Create prediction
      final prediction = Prediction(
        id: predictionId,
        userId: userId,
        tournamentId: tournamentId,
        matchId: match.id,
        predictedWinner: predictedWinner,
        predictedHomeScore: predictedHomeScore,
        predictedAwayScore: predictedAwayScore,
        submittedAt: DateTime.now(),
        isCorrect: null,
        pointsEarned: 0,
      );

      await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .doc(predictionId)
          .set(prediction.toJson());

      // Update user tournament stats (increment total predictions)
      await _updateUserStats(
        userId: userId,
        tournamentId: tournamentId,
        incrementPredictions: true,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to submit prediction: $e');
    }
  }

  /// Evaluate all predictions for a completed match
  static Future<void> evaluateMatchPredictions({
    required String matchId,
    required Tournament tournament,
    required Match match,
  }) async {
    try {
      // Get all predictions for this match
      final predictionsSnapshot = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .where('matchId', isEqualTo: matchId)
          .get();

      for (var predDoc in predictionsSnapshot.docs) {
        final prediction = Prediction.fromJson(predDoc.data());

        // Calculate points earned
        final pointsEarned = _calculatePoints(
          tournament: tournament,
          prediction: prediction,
          actualResult: match,
        );

        // Update prediction document
        await predDoc.reference.update({
          'isCorrect': pointsEarned > 0,
          'pointsEarned': pointsEarned,
          'evaluatedAt': FieldValue.serverTimestamp(),
        });

        // Update user tournament stats
        await _updateUserStats(
          userId: prediction.userId,
          tournamentId: tournament.id,
          pointsEarned: pointsEarned,
          wasCorrect: pointsEarned > 0,
        );

        // Award Flixbit points to wallet if prediction was correct
        if (pointsEarned > 0) {
          await FlixbitPointsManager.awardPoints(
            userId: prediction.userId,
            pointsEarned: pointsEarned,
            source: TransactionSource.tournamentPrediction,
            description: 'Correct prediction: ${match.homeTeam} vs ${match.awayTeam}',
            metadata: {
              'tournamentId': tournament.id,
              'matchId': match.id,
              'pointsEarned': pointsEarned,
            },
          );
        }
      }

      // Recalculate tournament leaderboard
      await _updateTournamentLeaderboard(tournament.id);
    } catch (e) {
      throw Exception('Failed to evaluate predictions: $e');
    }
  }

  /// Calculate points earned for a prediction
  static int _calculatePoints({
    required Tournament tournament,
    required Prediction prediction,
    required Match actualResult,
  }) {
    int points = 0;

    // Check if winner prediction is correct
    if (prediction.predictedWinner == actualResult.winner) {
      points += tournament.pointsPerCorrectPrediction;

      // Bonus for exact score prediction
      if (prediction.predictedHomeScore != null &&
          prediction.predictedAwayScore != null &&
          prediction.predictedHomeScore == actualResult.homeScore &&
          prediction.predictedAwayScore == actualResult.awayScore) {
        points += tournament.bonusPointsForExactScore;
      }
    }

    return points;
  }

  /// Update user tournament statistics
  static Future<void> _updateUserStats({
    required String userId,
    required String tournamentId,
    int pointsEarned = 0,
    bool wasCorrect = false,
    bool incrementPredictions = false,
  }) async {
    try {
      final statsId = '${userId}_$tournamentId';
      final statsRef = _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .doc(statsId);

      final statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        // Update existing stats
        final data = statsDoc.data()!;
        final totalPredictions =
            (data['totalPredictions'] as int? ?? 0) + (incrementPredictions ? 1 : 0);
        final correctPredictions =
            (data['correctPredictions'] as int? ?? 0) + (wasCorrect ? 1 : 0);
        final totalPoints = (data['totalPointsEarned'] as int? ?? 0) + pointsEarned;

        // Calculate accuracy
        final accuracy = totalPredictions > 0
            ? (correctPredictions / totalPredictions) * 100
            : 0.0;

        // Get tournament to check qualification
        final tournamentDoc = await _firestore
            .collection(FirebaseConstants.tournamentsCollection)
            .doc(tournamentId)
            .get();

        final threshold =
            tournamentDoc.data()?['qualificationThreshold'] as double? ?? 0.80;
        final isQualified = accuracy >= (threshold * 100);

        await statsRef.update({
          if (incrementPredictions) 'totalPredictions': totalPredictions,
          if (wasCorrect) 'correctPredictions': correctPredictions,
          if (pointsEarned > 0) 'totalPointsEarned': totalPoints,
          'accuracyPercentage': accuracy,
          'isQualified': isQualified,
          if (isQualified && !(data['isQualified'] as bool? ?? false))
            'qualifiedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // If newly qualified, award bonus points
        if (isQualified && !(data['isQualified'] as bool? ?? false)) {
          await FlixbitPointsManager.awardPoints(
            userId: userId,
            pointsEarned: 50,
            source: TransactionSource.tournamentQualification,
            description: 'Qualified for tournament final draw',
            metadata: {'tournamentId': tournamentId},
          );
        }
      } else {
        // Create new stats entry
        final stats = UserTournamentStats(
          userId: userId,
          tournamentId: tournamentId,
          totalPredictions: incrementPredictions ? 1 : 0,
          correctPredictions: wasCorrect ? 1 : 0,
          accuracyPercentage: wasCorrect ? 100.0 : 0.0,
          totalPointsEarned: pointsEarned,
          isQualified: false,
          qualifiedAt: null,
          purchasedPoints: 0,
        );

        await statsRef.set(stats.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Update tournament leaderboard
  static Future<void> _updateTournamentLeaderboard(String tournamentId) async {
    try {
      // Get all user stats for this tournament
      final statsSnapshot = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .where('tournamentId', isEqualTo: tournamentId)
          .orderBy('accuracyPercentage', descending: true)
          .orderBy('totalPointsEarned', descending: true)
          .get();

      // Update ranks
      int rank = 1;
      for (var statDoc in statsSnapshot.docs) {
        await statDoc.reference.update({'rank': rank});
        rank++;
      }
    } catch (e) {
      // Leaderboard update is not critical, just log error
      print('Failed to update leaderboard: $e');
    }
  }

  /// Get user's predictions for a tournament
  static Future<List<Prediction>> getUserPredictions({
    required String userId,
    required String tournamentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .where('userId', isEqualTo: userId)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      return snapshot.docs
          .map((doc) => Prediction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user predictions: $e');
    }
  }

  /// Check if user has predicted a specific match
  static Future<bool> hasPredicted({
    required String userId,
    required String matchId,
  }) async {
    try {
      final predictionId = '${userId}_$matchId';
      final doc = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .doc(predictionId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get prediction statistics for a match
  static Future<Map<String, int>> getMatchPredictionStats(
      String matchId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.predictionsCollection)
          .where('matchId', isEqualTo: matchId)
          .get();

      int homeVotes = 0;
      int awayVotes = 0;
      int drawVotes = 0;

      for (var doc in snapshot.docs) {
        final prediction = Prediction.fromJson(doc.data());
        switch (prediction.predictedWinner) {
          case 'home':
            homeVotes++;
            break;
          case 'away':
            awayVotes++;
            break;
          case 'draw':
            drawVotes++;
            break;
        }
      }

      return {
        'total': snapshot.docs.length,
        'home': homeVotes,
        'away': awayVotes,
        'draw': drawVotes,
      };
    } catch (e) {
      return {'total': 0, 'home': 0, 'away': 0, 'draw': 0};
    }
  }
}

