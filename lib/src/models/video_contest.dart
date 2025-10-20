import 'package:cloud_firestore/cloud_firestore.dart';

class VideoContest {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime voteWindowStart;
  final DateTime voteWindowEnd;
  final String? category;
  final String? region;
  final int maxWinners; // e.g., top 3, top 5
  final Map<String, dynamic> prizeStructure; // {1: 500, 2: 300, 3: 100} points
  final List<String> participatingVideoIds;
  final int totalParticipants;
  final int totalVotes;
  final bool isActive;
  final bool winnersAnnounced;
  final String createdBy; // admin/sub-admin ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFeatured;
  final bool isSponsored;

  const VideoContest({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.voteWindowStart,
    required this.voteWindowEnd,
    this.category,
    this.region,
    required this.maxWinners,
    required this.prizeStructure,
    required this.participatingVideoIds,
    this.totalParticipants = 0,
    this.totalVotes = 0,
    this.isActive = true,
    this.winnersAnnounced = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isFeatured = false,
    this.isSponsored = false,
  });

  bool get isVotingOpen {
    final now = DateTime.now();
    return now.isAfter(voteWindowStart) && now.isBefore(voteWindowEnd);
  }

  bool get hasEnded {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }

  // Factory method to create from Firestore
  factory VideoContest.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoContest(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      voteWindowStart: (data['voteWindowStart'] as Timestamp).toDate(),
      voteWindowEnd: (data['voteWindowEnd'] as Timestamp).toDate(),
      category: data['category'] as String?,
      region: data['region'] as String?,
      maxWinners: data['maxWinners'] as int,
      prizeStructure: Map<String, dynamic>.from(data['prizeStructure'] as Map),
      participatingVideoIds: List<String>.from(data['participatingVideoIds'] as List),
      totalParticipants: data['totalParticipants'] as int? ?? 0,
      totalVotes: data['totalVotes'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      winnersAnnounced: data['winnersAnnounced'] as bool? ?? false,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isFeatured: data['isFeatured'] as bool? ?? false,
      isSponsored: data['isSponsored'] as bool? ?? false,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'voteWindowStart': Timestamp.fromDate(voteWindowStart),
      'voteWindowEnd': Timestamp.fromDate(voteWindowEnd),
      'category': category,
      'region': region,
      'maxWinners': maxWinners,
      'prizeStructure': prizeStructure,
      'participatingVideoIds': participatingVideoIds,
      'totalParticipants': totalParticipants,
      'totalVotes': totalVotes,
      'isActive': isActive,
      'winnersAnnounced': winnersAnnounced,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFeatured': isFeatured,
      'isSponsored': isSponsored,
    };
  }

  // CopyWith method
  VideoContest copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? voteWindowStart,
    DateTime? voteWindowEnd,
    String? category,
    String? region,
    int? maxWinners,
    Map<String, dynamic>? prizeStructure,
    List<String>? participatingVideoIds,
    int? totalParticipants,
    int? totalVotes,
    bool? isActive,
    bool? winnersAnnounced,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFeatured,
    bool? isSponsored,
  }) {
    return VideoContest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      voteWindowStart: voteWindowStart ?? this.voteWindowStart,
      voteWindowEnd: voteWindowEnd ?? this.voteWindowEnd,
      category: category ?? this.category,
      region: region ?? this.region,
      maxWinners: maxWinners ?? this.maxWinners,
      prizeStructure: prizeStructure ?? this.prizeStructure,
      participatingVideoIds: participatingVideoIds ?? this.participatingVideoIds,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      totalVotes: totalVotes ?? this.totalVotes,
      isActive: isActive ?? this.isActive,
      winnersAnnounced: winnersAnnounced ?? this.winnersAnnounced,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isSponsored: isSponsored ?? this.isSponsored,
    );
  }
}

class ContestLeaderboardEntry {
  final String videoId;
  final String videoTitle;
  final String uploadedBy;
  final int voteCount;
  final int rank;

  const ContestLeaderboardEntry({
    required this.videoId,
    required this.videoTitle,
    required this.uploadedBy,
    required this.voteCount,
    required this.rank,
  });
}

