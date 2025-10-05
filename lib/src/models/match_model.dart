class Match {
  final String id;
  final String tournamentId;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchDate;
  final String matchTime;
  final String venue;
  final DateTime createdAt;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final DateTime predictionCloseTime;
  final String? winner; // 'home', 'away', or 'draw'

  Match({
    required this.id,
    required this.tournamentId,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.matchTime,
    required this.venue,
    required this.createdAt,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.predictionCloseTime,
    this.winner,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      matchDate: DateTime.parse(json['matchDate'] as String),
      matchTime: json['matchTime'] as String,
      venue: json['venue'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchStatus.upcoming,
      ),
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      predictionCloseTime: DateTime.parse(json['predictionCloseTime'] as String),
      winner: json['winner'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'matchDate': matchDate.toIso8601String(),
      'matchTime': matchTime,
      'venue': venue,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'predictionCloseTime': predictionCloseTime.toIso8601String(),
      'winner': winner,
    };
  }

  Match copyWith({
    String? id,
    String? tournamentId,
    String? homeTeam,
    String? awayTeam,
    DateTime? matchDate,
    String? matchTime,
    String? venue,
    DateTime? createdAt,
    MatchStatus? status,
    int? homeScore,
    int? awayScore,
    DateTime? predictionCloseTime,
    String? winner,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      matchDate: matchDate ?? this.matchDate,
      matchTime: matchTime ?? this.matchTime,
      venue: venue ?? this.venue,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      predictionCloseTime: predictionCloseTime ?? this.predictionCloseTime,
      winner: winner ?? this.winner,
    );
  }

  bool get isPredictionOpen {
    return DateTime.now().isBefore(predictionCloseTime);
  }

  Duration get timeUntilClose {
    return predictionCloseTime.difference(DateTime.now());
  }
}

enum MatchStatus {
  upcoming,
  live,
  completed,
}
