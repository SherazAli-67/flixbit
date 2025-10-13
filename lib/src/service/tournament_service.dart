import '../models/tournament_model.dart';
import '../models/match_model.dart';
import '../models/user_tournament_stats.dart';
import 'enhanced_tournament_service.dart';

/// @deprecated Use EnhancedTournamentService instead
/// This class is kept for backward compatibility only
class TournamentService {
  // Redirect to new service
  static Future<List<Tournament>> getDummyTournaments() async {
    return await EnhancedTournamentService.getAllTournaments();
  }

  // Redirect to new service
  static Map<String, UserTournamentStats> getDummyUserStats() {
    // This method is deprecated - user stats should be loaded per user from Firebase
    // Return empty map to avoid breaking existing code
    return {};
  }

  // Redirect to new service
  static Future<List<Match>> getDummyMatches(String tournamentId) async {
    return await EnhancedTournamentService.getTournamentMatches(tournamentId);
  }
}
