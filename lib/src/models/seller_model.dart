import 'package:flixbit/src/models/review_model.dart';

class Seller {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String category;
  final String? location;
  final String? phone;
  final String? email;
  final String? website;
  final List<String> socialMediaLinks;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final ReviewSummary? reviewSummary;
  final int followersCount;
  final List<String> badges;
  final Map<String, dynamic>? businessHours;
  final String? qrCodeData;

  Seller({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    required this.category,
    this.location,
    this.phone,
    this.email,
    this.website,
    this.socialMediaLinks = const [],
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.lastActiveAt,
    this.reviewSummary,
    this.followersCount = 0,
    this.badges = const [],
    this.businessHours,
    this.qrCodeData,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
      coverImageUrl: json['coverImageUrl'],
      category: json['category'] ?? '',
      location: json['location'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      socialMediaLinks: List<String>.from(json['socialMediaLinks'] ?? []),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : null,
      reviewSummary: json['reviewSummary'] != null 
          ? ReviewSummary.fromJson(json['reviewSummary']) 
          : null,
      followersCount: json['followersCount'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      businessHours: json['businessHours'],
      qrCodeData: json['qrCodeData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'category': category,
      'location': location,
      'phone': phone,
      'email': email,
      'website': website,
      'socialMediaLinks': socialMediaLinks,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'reviewSummary': reviewSummary?.toJson(),
      'followersCount': followersCount,
      'badges': badges,
      'businessHours': businessHours,
      'qrCodeData': qrCodeData,
    };
  }

  Seller copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? category,
    String? location,
    String? phone,
    String? email,
    String? website,
    List<String>? socialMediaLinks,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    ReviewSummary? reviewSummary,
    int? followersCount,
    List<String>? badges,
    Map<String, dynamic>? businessHours,
    String? qrCodeData,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      reviewSummary: reviewSummary ?? this.reviewSummary,
      followersCount: followersCount ?? this.followersCount,
      badges: badges ?? this.badges,
      businessHours: businessHours ?? this.businessHours,
      qrCodeData: qrCodeData ?? this.qrCodeData,
    );
  }

  // Helper methods
  bool get hasGoodRating => reviewSummary?.averageRating != null && reviewSummary!.averageRating >= 4.0;
  bool get isTopRated => reviewSummary?.averageRating != null && reviewSummary!.averageRating >= 4.5;
  bool get hasManyReviews => reviewSummary?.totalReviews != null && reviewSummary!.totalReviews >= 50;
  
  String get displayRating {
    if (reviewSummary?.averageRating == null) return 'No ratings';
    return '${reviewSummary!.averageRating.toStringAsFixed(1)} ⭐';
  }
}

class SellerCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  SellerCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory SellerCategory.fromJson(Map<String, dynamic> json) {
    return SellerCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}

