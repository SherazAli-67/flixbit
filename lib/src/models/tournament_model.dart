class Tournament {
  // Basic Info
  final String id;
  final String name;
  final String description;
  final String sportType;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final TournamentStatus status;
  
  // Game Rules & Scoring
  final int totalMatches;
  final PredictionType predictionType;
  final int pointsPerCorrectPrediction;
  final int bonusPointsForExactScore;
  final double qualificationThreshold;
  
  // Entry & Pricing
  final EntryType entryType;
  final int entryFee;
  final int? maxParticipants;
  
  // Rewards & Prizes
  final String prizeDescription;
  final int numberOfWinners;
  final List<PrizeTier> prizeTiers;
  final List<String> rewardIds; // IDs of rewards that can be won
  
  // Sponsorship
  final bool isSponsored;
  final String? sponsorId;
  final String? sponsorName;
  final bool showSponsorLogo;
  
  // Targeting & Visibility
  final String region;
  final List<String> categoryTags;
  final TournamentVisibility visibility;
  
  // Notification Settings
  final bool sendPushOnCreation;
  final bool notifyBeforeMatches;
  final bool notifyOnScoreUpdates;
  
  // Management
  final String createdBy;
  final DateTime? updatedAt;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.sportType,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.status,
    required this.totalMatches,
    this.predictionType = PredictionType.winnerOnly,
    this.pointsPerCorrectPrediction = 10,
    this.bonusPointsForExactScore = 20,
    this.qualificationThreshold = 0.80,
    this.entryType = EntryType.free,
    this.entryFee = 0,
    this.maxParticipants,
    required this.prizeDescription,
    required this.numberOfWinners,
    this.prizeTiers = const [],
    this.rewardIds = const [],
    this.isSponsored = false,
    this.sponsorId,
    this.sponsorName,
    this.showSponsorLogo = true,
    this.region = 'Global',
    this.categoryTags = const [],
    this.visibility = TournamentVisibility.public,
    this.sendPushOnCreation = true,
    this.notifyBeforeMatches = true,
    this.notifyOnScoreUpdates = true,
    required this.createdBy,
    this.updatedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sportType: json['sportType'] as String? ?? 'Football',
      imageUrl: json['imageUrl'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TournamentStatus.upcoming,
      ),
      totalMatches: json['totalMatches'] as int,
      predictionType: PredictionType.values.firstWhere(
        (e) => e.name == json['predictionType'],
        orElse: () => PredictionType.winnerOnly,
      ),
      pointsPerCorrectPrediction: json['pointsPerCorrectPrediction'] as int? ?? 10,
      bonusPointsForExactScore: json['bonusPointsForExactScore'] as int? ?? 20,
      qualificationThreshold: (json['qualificationThreshold'] as num?)?.toDouble() ?? 0.80,
      entryType: EntryType.values.firstWhere(
        (e) => e.name == json['entryType'],
        orElse: () => EntryType.free,
      ),
      entryFee: json['entryFee'] as int? ?? 0,
      maxParticipants: json['maxParticipants'] as int?,
      prizeDescription: json['prizeDescription'] as String,
      numberOfWinners: json['numberOfWinners'] as int,
      prizeTiers: (json['prizeTiers'] as List?)?.map((e) => PrizeTier.fromJson(e)).toList() ?? [],
      rewardIds: List<String>.from(json['rewardIds'] ?? []),
      isSponsored: json['isSponsored'] as bool? ?? false,
      sponsorId: json['sponsorId'] as String?,
      sponsorName: json['sponsorName'] as String?,
      showSponsorLogo: json['showSponsorLogo'] as bool? ?? true,
      region: json['region'] as String? ?? 'Global',
      categoryTags: List<String>.from(json['categoryTags'] ?? []),
      visibility: TournamentVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => TournamentVisibility.public,
      ),
      sendPushOnCreation: json['sendPushOnCreation'] as bool? ?? true,
      notifyBeforeMatches: json['notifyBeforeMatches'] as bool? ?? true,
      notifyOnScoreUpdates: json['notifyOnScoreUpdates'] as bool? ?? true,
      createdBy: json['createdBy'] as String,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sportType': sportType,
      'imageUrl': imageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'totalMatches': totalMatches,
      'predictionType': predictionType.name,
      'pointsPerCorrectPrediction': pointsPerCorrectPrediction,
      'bonusPointsForExactScore': bonusPointsForExactScore,
      'qualificationThreshold': qualificationThreshold,
      'entryType': entryType.name,
      'entryFee': entryFee,
      'maxParticipants': maxParticipants,
      'prizeDescription': prizeDescription,
      'numberOfWinners': numberOfWinners,
      'prizeTiers': prizeTiers.map((e) => e.toJson()).toList(),
      'rewardIds': rewardIds,
      'isSponsored': isSponsored,
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'showSponsorLogo': showSponsorLogo,
      'region': region,
      'categoryTags': categoryTags,
      'visibility': visibility.name,
      'sendPushOnCreation': sendPushOnCreation,
      'notifyBeforeMatches': notifyBeforeMatches,
      'notifyOnScoreUpdates': notifyOnScoreUpdates,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    String? sportType,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    TournamentStatus? status,
    int? totalMatches,
    PredictionType? predictionType,
    int? pointsPerCorrectPrediction,
    int? bonusPointsForExactScore,
    double? qualificationThreshold,
    EntryType? entryType,
    int? entryFee,
    int? maxParticipants,
    String? prizeDescription,
    int? numberOfWinners,
    List<PrizeTier>? prizeTiers,
    List<String>? rewardIds,
    bool? isSponsored,
    String? sponsorId,
    String? sponsorName,
    bool? showSponsorLogo,
    String? region,
    List<String>? categoryTags,
    TournamentVisibility? visibility,
    bool? sendPushOnCreation,
    bool? notifyBeforeMatches,
    bool? notifyOnScoreUpdates,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sportType: sportType ?? this.sportType,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalMatches: totalMatches ?? this.totalMatches,
      predictionType: predictionType ?? this.predictionType,
      pointsPerCorrectPrediction: pointsPerCorrectPrediction ?? this.pointsPerCorrectPrediction,
      bonusPointsForExactScore: bonusPointsForExactScore ?? this.bonusPointsForExactScore,
      qualificationThreshold: qualificationThreshold ?? this.qualificationThreshold,
      entryType: entryType ?? this.entryType,
      entryFee: entryFee ?? this.entryFee,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      numberOfWinners: numberOfWinners ?? this.numberOfWinners,
      prizeTiers: prizeTiers ?? this.prizeTiers,
      rewardIds: rewardIds ?? this.rewardIds,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
      showSponsorLogo: showSponsorLogo ?? this.showSponsorLogo,
      region: region ?? this.region,
      categoryTags: categoryTags ?? this.categoryTags,
      visibility: visibility ?? this.visibility,
      sendPushOnCreation: sendPushOnCreation ?? this.sendPushOnCreation,
      notifyBeforeMatches: notifyBeforeMatches ?? this.notifyBeforeMatches,
      notifyOnScoreUpdates: notifyOnScoreUpdates ?? this.notifyOnScoreUpdates,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enums
enum TournamentStatus {
  upcoming,
  ongoing,
  completed,
}

enum PredictionType {
  winnerOnly,
  scoreline,
  both,
}

enum EntryType {
  free,
  paid,
}

// RewardType enum moved to reward_model.dart

enum TournamentVisibility {
  public,
  private,
  byInvitation,
}

// Prize Tier Model
class PrizeTier {
  final int tier;
  final String prize;
  final String description;
  final int numberOfWinners;

  PrizeTier({
    required this.tier,
    required this.prize,
    required this.description,
    this.numberOfWinners = 1,
  });

  factory PrizeTier.fromJson(Map<String, dynamic> json) {
    return PrizeTier(
      tier: json['tier'] as int,
      prize: json['prize'] as String,
      description: json['description'] as String,
      numberOfWinners: json['numberOfWinners'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'prize': prize,
      'description': description,
      'numberOfWinners': numberOfWinners,
    };
  }
}
