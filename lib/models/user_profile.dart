
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? currentRole;
  final String? industry;
  final int? yearsOfExperience;
  final List<String>? skills;
  final List<String> interests;
  final DateTime? lastActive;
  final bool hasCompletedOnboarding;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.currentRole,
    this.industry,
    this.yearsOfExperience,
    this.skills,
    this.interests = const [],
    this.lastActive,
    this.hasCompletedOnboarding = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'currentRole': currentRole,
      'industry': industry,
      'yearsOfExperience': yearsOfExperience,
      'skills': skills,
      'interests': interests,
      'lastActive': lastActive?.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      currentRole: json['currentRole'] as String?,
      industry: json['industry'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>(),
      interests:
          (json['interests'] as List<dynamic>?)?.cast<String>() ?? const [],
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  static UserProfile fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile.fromJson({
      ...data,
      'id': id,
    });
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? currentRole,
    String? industry,
    int? yearsOfExperience,
    List<String>? skills,
    List<String>? interests,
    DateTime? lastActive,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currentRole: currentRole ?? this.currentRole,
      industry: industry ?? this.industry,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      lastActive: lastActive ?? this.lastActive,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
