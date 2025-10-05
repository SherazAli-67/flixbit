class Tournament {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final TournamentStatus status;
  final int pointsPerCorrectPrediction;
  final double qualificationThreshold;
  final int totalMatches;
  final String prizeDescription;
  final int numberOfWinners;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.status,
    required this.pointsPerCorrectPrediction,
    required this.qualificationThreshold,
    required this.totalMatches,
    required this.prizeDescription,
    required this.numberOfWinners,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TournamentStatus.upcoming,
      ),
      pointsPerCorrectPrediction: json['pointsPerCorrectPrediction'] as int,
      qualificationThreshold: (json['qualificationThreshold'] as num).toDouble(),
      totalMatches: json['totalMatches'] as int,
      prizeDescription: json['prizeDescription'] as String,
      numberOfWinners: json['numberOfWinners'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'pointsPerCorrectPrediction': pointsPerCorrectPrediction,
      'qualificationThreshold': qualificationThreshold,
      'totalMatches': totalMatches,
      'prizeDescription': prizeDescription,
      'numberOfWinners': numberOfWinners,
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    TournamentStatus? status,
    int? pointsPerCorrectPrediction,
    double? qualificationThreshold,
    int? totalMatches,
    String? prizeDescription,
    int? numberOfWinners,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      pointsPerCorrectPrediction: pointsPerCorrectPrediction ?? this.pointsPerCorrectPrediction,
      qualificationThreshold: qualificationThreshold ?? this.qualificationThreshold,
      totalMatches: totalMatches ?? this.totalMatches,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      numberOfWinners: numberOfWinners ?? this.numberOfWinners,
    );
  }
}

enum TournamentStatus {
  upcoming,
  ongoing,
  completed,
}
