class UserModel {
  final String userID;
  final String name;
  final String email;
  final String profileImg;
  final String createdAt;
  final String? fcmToken;
  final List<String>? fcmTokens; // Support multiple devices
  final DateTime? fcmTokenUpdatedAt;

  UserModel({
    required this.userID, 
    required this.email, 
    required this.name, 
    required this.profileImg,
    required this.createdAt,
    this.fcmToken,
    this.fcmTokens,
    this.fcmTokenUpdatedAt,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'profileImg': profileImg,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
      'fcmTokens': fcmTokens,
      'fcmTokenUpdatedAt': fcmTokenUpdatedAt?.toIso8601String(),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userID: map['userID'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImg: map['profileImg'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      fcmToken: map['fcmToken'] as String?,
      fcmTokens: map['fcmTokens'] != null ? List<String>.from(map['fcmTokens']) : null,
      fcmTokenUpdatedAt: map['fcmTokenUpdatedAt'] != null 
          ? DateTime.parse(map['fcmTokenUpdatedAt'] as String)
          : null,
    );
  }

  // Create UserModel from Firestore document with document ID
  factory UserModel.fromFirestore(Map<String, dynamic> map, String documentId) {
    return UserModel(
      userID: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImg: map['profileImg'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      fcmToken: map['fcmToken'] as String?,
      fcmTokens: map['fcmTokens'] != null ? List<String>.from(map['fcmTokens']) : null,
      fcmTokenUpdatedAt: map['fcmTokenUpdatedAt'] != null 
          ? DateTime.parse(map['fcmTokenUpdatedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'UserModel(userID: $userID, name: $name, email: $email, profileImg: $profileImg)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.userID == userID &&
        other.name == name &&
        other.email == email &&
        other.profileImg == profileImg &&
    other.createdAt == createdAt
    ;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
        name.hashCode ^
        email.hashCode ^
        profileImg.hashCode ^ createdAt.hashCode;
  }
}