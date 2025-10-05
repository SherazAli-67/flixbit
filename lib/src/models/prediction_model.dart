class Prediction {
  final String id;
  final String userId;
  final String tournamentId;
  final String matchId;
  final String predictedWinner; // 'home', 'away', or 'draw'
  final int? predictedHomeScore;
  final int? predictedAwayScore;
  final DateTime submittedAt;
  final bool? isCorrect;
  final int pointsEarned;

  Prediction({
    required this.id,
    required this.userId,
    required this.tournamentId,
    required this.matchId,
    required this.predictedWinner,
    this.predictedHomeScore,
    this.predictedAwayScore,
    required this.submittedAt,
    this.isCorrect,
    required this.pointsEarned,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tournamentId: json['tournamentId'] as String,
      matchId: json['matchId'] as String,
      predictedWinner: json['predictedWinner'] as String,
      predictedHomeScore: json['predictedHomeScore'] as int?,
      predictedAwayScore: json['predictedAwayScore'] as int?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isCorrect: json['isCorrect'] as bool?,
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tournamentId': tournamentId,
      'matchId': matchId,
      'predictedWinner': predictedWinner,
      'predictedHomeScore': predictedHomeScore,
      'predictedAwayScore': predictedAwayScore,
      'submittedAt': submittedAt.toIso8601String(),
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }

  Prediction copyWith({
    String? id,
    String? userId,
    String? tournamentId,
    String? matchId,
    String? predictedWinner,
    int? predictedHomeScore,
    int? predictedAwayScore,
    DateTime? submittedAt,
    bool? isCorrect,
    int? pointsEarned,
  }) {
    return Prediction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tournamentId: tournamentId ?? this.tournamentId,
      matchId: matchId ?? this.matchId,
      predictedWinner: predictedWinner ?? this.predictedWinner,
      predictedHomeScore: predictedHomeScore ?? this.predictedHomeScore,
      predictedAwayScore: predictedAwayScore ?? this.predictedAwayScore,
      submittedAt: submittedAt ?? this.submittedAt,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}
