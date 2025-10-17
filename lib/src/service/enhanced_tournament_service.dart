import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';
import '../models/user_tournament_stats.dart';
import '../res/firebase_constants.dart';
import 'prediction_service.dart';

class EnhancedTournamentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  /// Create a new tournament
  static Future<String> createTournament(Tournament tournament) async {
    try {
      final tournamentId = tournament.id.isEmpty
          ? _firestore.collection(FirebaseConstants.tournamentsCollection).doc().id
          : tournament.id;

      final tournamentWithId = tournament.copyWith(
        id: tournamentId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .set(tournamentWithId.toJson());

      return tournamentId;
    } catch (e) {
      throw Exception('Failed to create tournament: $e');
    }
  }

  /// Update an existing tournament
  static Future<void> updateTournament(Tournament tournament) async {
    try {
      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournament.id)
          .update(tournament.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw Exception('Failed to update tournament: $e');
    }
  }

  /// Delete a tournament
  static Future<void> deleteTournament(String tournamentId) async {
    try {
      // Delete all matches first
      final matchesSnapshot = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .get();

      for (var doc in matchesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete tournament
      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete tournament: $e');
    }
  }

  /// Get tournament by ID
  static Future<Tournament?> getTournament(String tournamentId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .get();

      if (!doc.exists) return null;
      return Tournament.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get tournament: $e');
    }
  }

  /// Get all tournaments
  static Future<List<Tournament>> getAllTournaments({
    TournamentStatus? status,
    String? region,
    String? sellerId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.tournamentsCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      if (sellerId != null) {
        query = query.where('createdBy', isEqualTo: sellerId);
      }

      query = query.orderBy('startDate', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Tournament.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get tournaments: $e');
      throw Exception('Failed to get tournaments: $e');
    }
  }

  // ==================== MATCH CRUD ====================

  /// Add a match to a tournament
  static Future<String> addMatch({
    required String tournamentId,
    required Match match,
  }) async {
    try {
      final matchId = match.id.isEmpty
          ? _firestore
              .collection(FirebaseConstants.tournamentsCollection)
              .doc(tournamentId)
              .collection(FirebaseConstants.matchesSubcollection)
              .doc()
              .id
          : match.id;

      final matchWithId = match.copyWith(
        id: matchId,
        tournamentId: tournamentId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .doc(matchId)
          .set(matchWithId.toJson());

      // Update tournament total matches count
      await _updateTournamentMatchCount(tournamentId);

      return matchId;
    } catch (e) {
      throw Exception('Failed to add match: $e');
    }
  }

  /// Update a match
  static Future<void> updateMatch({
    required String tournamentId,
    required Match match,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .doc(match.id)
          .update(match.toJson());
    } catch (e) {
      throw Exception('Failed to update match: $e');
    }
  }

  /// Delete a match
  static Future<void> deleteMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .doc(matchId)
          .delete();

      // Update tournament total matches count
      await _updateTournamentMatchCount(tournamentId);
    } catch (e) {
      throw Exception('Failed to delete match: $e');
    }
  }

  /// Get all matches for a tournament
  static Future<List<Match>> getTournamentMatches(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .orderBy('matchDate')
          .get();

      return snapshot.docs
          .map((doc) => Match.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  /// Get a specific match
  static Future<Match?> getMatch({
    required String tournamentId,
    required String matchId,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .doc(matchId)
          .get();

      if (!doc.exists) return null;
      return Match.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get match: $e');
    }
  }

  // ==================== SCORE UPDATE & FINALIZE ====================

  /// Update match score and finalize
  static Future<void> finalizeMatch({
    required String tournamentId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    try {
      // Get the match
      final match = await getMatch(tournamentId: tournamentId, matchId: matchId);
      if (match == null) throw Exception('Match not found');

      // Determine winner
      String winner;
      if (homeScore > awayScore) {
        winner = 'home';
      } else if (awayScore > homeScore) {
        winner = 'away';
      } else {
        winner = 'draw';
      }

      // Update match with final score
      final updatedMatch = match.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        winner: winner,
        status: MatchStatus.completed,
      );

      await updateMatch(tournamentId: tournamentId, match: updatedMatch);

      // Get tournament
      final tournament = await getTournament(tournamentId);
      if (tournament == null) throw Exception('Tournament not found');

      // Evaluate all predictions for this match
      await PredictionService.evaluateMatchPredictions(
        matchId: matchId,
        tournament: tournament,
        match: updatedMatch,
      );
    } catch (e) {
      throw Exception('Failed to finalize match: $e');
    }
  }

  // ==================== TOURNAMENT STATISTICS ====================

  /// Get tournament statistics
  static Future<Map<String, dynamic>> getTournamentStats(
      String tournamentId) async {
    try {
      // Get all user stats
      final statsSnapshot = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      int totalParticipants = statsSnapshot.docs.length;
      int activeParticipants = 0;
      int qualifiedUsers = 0;
      double totalAccuracy = 0;
      int totalPredictions = 0;
      int totalPointsAwarded = 0;

      for (var doc in statsSnapshot.docs) {
        final stats = UserTournamentStats.fromJson(doc.data());
        if (stats.totalPredictions > 0) activeParticipants++;
        if (stats.isQualified) qualifiedUsers++;
        totalAccuracy += stats.accuracyPercentage;
        totalPredictions += stats.totalPredictions;
        totalPointsAwarded += stats.totalPointsEarned;
      }

      double averageAccuracy =
          totalParticipants > 0 ? totalAccuracy / totalParticipants : 0;

      return {
        'totalParticipants': totalParticipants,
        'activeParticipants': activeParticipants,
        'qualifiedUsers': qualifiedUsers,
        'averageAccuracy': averageAccuracy,
        'totalPredictions': totalPredictions,
        'totalPointsAwarded': totalPointsAwarded,
      };
    } catch (e) {
      debugPrint("Failed to get tournament stats: $e");
      throw Exception('Failed to get tournament stats: $e');
    }
  }

  /// Get leaderboard for a tournament
  static Future<List<UserTournamentStats>> getLeaderboard({
    required String tournamentId,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .where('tournamentId', isEqualTo: tournamentId)
          .orderBy('accuracyPercentage', descending: true)
          .orderBy('totalPointsEarned', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserTournamentStats.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  /// Get qualified users for prize draw
  static Future<List<UserTournamentStats>> getQualifiedUsers(
      String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.userTournamentStatsCollection)
          .where('tournamentId', isEqualTo: tournamentId)
          .where('isQualified', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserTournamentStats.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get qualified users: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update tournament match count
  static Future<void> _updateTournamentMatchCount(String tournamentId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .collection(FirebaseConstants.matchesSubcollection)
          .get();

      await _firestore
          .collection(FirebaseConstants.tournamentsCollection)
          .doc(tournamentId)
          .update({'totalMatches': matchesSnapshot.docs.length});
    } catch (e) {
      debugPrint('Failed to update match count: $e');
    }
  }

  /// Update tournament status based on dates
  static Future<void> updateTournamentStatus(String tournamentId) async {
    try {
      final tournament = await getTournament(tournamentId);
      if (tournament == null) return;

      final now = DateTime.now();
      TournamentStatus newStatus;

      if (now.isBefore(tournament.startDate)) {
        newStatus = TournamentStatus.upcoming;
      } else if (now.isAfter(tournament.endDate)) {
        newStatus = TournamentStatus.completed;
      } else {
        newStatus = TournamentStatus.ongoing;
      }

      if (newStatus != tournament.status) {
        await _firestore
            .collection(FirebaseConstants.tournamentsCollection)
            .doc(tournamentId)
            .update({'status': newStatus.name});
      }
    } catch (e) {
      print('Failed to update tournament status: $e');
    }
  }
}

