class UserTournamentStats {
  final String userId;
  final String tournamentId;
  final int totalPredictions;
  final int correctPredictions;
  final double accuracyPercentage;
  final int totalPointsEarned;
  final bool isQualified;
  final DateTime? qualifiedAt;
  final int purchasedPoints;
  final int? rank;

  UserTournamentStats({
    required this.userId,
    required this.tournamentId,
    required this.totalPredictions,
    required this.correctPredictions,
    required this.accuracyPercentage,
    required this.totalPointsEarned,
    required this.isQualified,
    this.qualifiedAt,
    required this.purchasedPoints,
    this.rank,
  });

  factory UserTournamentStats.fromJson(Map<String, dynamic> json) {
    return UserTournamentStats(
      userId: json['userId'] as String,
      tournamentId: json['tournamentId'] as String,
      totalPredictions: json['totalPredictions'] as int,
      correctPredictions: json['correctPredictions'] as int,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      totalPointsEarned: json['totalPointsEarned'] as int,
      isQualified: json['isQualified'] as bool,
      // qualifiedAt: json['qualifiedAt'] != null ? json['qualifiedAt'] is Timestamp ?
      //     ? DateTime.parse(json['qualifiedAt'] as String)
      //     : null,
      purchasedPoints: json['purchasedPoints'] as int,
      rank: json['rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tournamentId': tournamentId,
      'totalPredictions': totalPredictions,
      'correctPredictions': correctPredictions,
      'accuracyPercentage': accuracyPercentage,
      'totalPointsEarned': totalPointsEarned,
      'isQualified': isQualified,
      'qualifiedAt': qualifiedAt?.toIso8601String(),
      'purchasedPoints': purchasedPoints,
      'rank': rank,
    };
  }

  UserTournamentStats copyWith({
    String? userId,
    String? tournamentId,
    int? totalPredictions,
    int? correctPredictions,
    double? accuracyPercentage,
    int? totalPointsEarned,
    bool? isQualified,
    DateTime? qualifiedAt,
    int? purchasedPoints,
    int? rank,
  }) {
    return UserTournamentStats(
      userId: userId ?? this.userId,
      tournamentId: tournamentId ?? this.tournamentId,
      totalPredictions: totalPredictions ?? this.totalPredictions,
      correctPredictions: correctPredictions ?? this.correctPredictions,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      isQualified: isQualified ?? this.isQualified,
      qualifiedAt: qualifiedAt ?? this.qualifiedAt,
      purchasedPoints: purchasedPoints ?? this.purchasedPoints,
      rank: rank ?? this.rank,
    );
  }
}
