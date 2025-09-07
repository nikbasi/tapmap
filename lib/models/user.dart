class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  List<String> favoriteFountainIds;
  List<String> contributedFountainIds;
  List<String> validatedFountainIds;
  int contributionScore;
  final bool isVerified;
  final String? phoneNumber;
  Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLoginAt,
    List<String>? favoriteFountainIds,
    List<String>? contributedFountainIds,
    List<String>? validatedFountainIds,
    int? contributionScore,
    this.isVerified = false,
    this.phoneNumber,
    Map<String, dynamic>? preferences,
  }) : 
    favoriteFountainIds = favoriteFountainIds ?? [],
    contributedFountainIds = contributedFountainIds ?? [],
    validatedFountainIds = validatedFountainIds ?? [],
    contributionScore = contributionScore ?? 0,
    preferences = preferences ?? {};

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null 
          ? DateTime.parse(data['lastLoginAt']) 
          : DateTime.now(),
      favoriteFountainIds: List<String>.from(data['favoriteFountainIds'] ?? []),
      contributedFountainIds: List<String>.from(data['contributedFountainIds'] ?? []),
      validatedFountainIds: List<String>.from(data['validatedFountainIds'] ?? []),
      contributionScore: data['contributionScore'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      phoneNumber: data['phoneNumber'],
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'favoriteFountainIds': favoriteFountainIds,
      'contributedFountainIds': contributedFountainIds,
      'validatedFountainIds': validatedFountainIds,
      'contributionScore': contributionScore,
      'isVerified': isVerified,
      'phoneNumber': phoneNumber,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? favoriteFountainIds,
    List<String>? contributedFountainIds,
    List<String>? validatedFountainIds,
    int? contributionScore,
    bool? isVerified,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      favoriteFountainIds: favoriteFountainIds ?? this.favoriteFountainIds,
      contributedFountainIds: contributedFountainIds ?? this.contributedFountainIds,
      validatedFountainIds: validatedFountainIds ?? this.validatedFountainIds,
      contributionScore: contributionScore ?? this.contributionScore,
      isVerified: isVerified ?? this.isVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper methods
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;
  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;
  
  int get totalContributions => contributedFountainIds.length;
  int get totalValidations => validatedFountainIds.length;
  int get totalFavorites => favoriteFountainIds.length;

  String get displayNameOrEmail => displayName ?? email;
  
  bool get isNewUser => DateTime.now().difference(createdAt).inDays < 7;
  
  String get contributionLevel {
    if (contributionScore >= 100) return 'Expert';
    if (contributionScore >= 50) return 'Advanced';
    if (contributionScore >= 20) return 'Intermediate';
    if (contributionScore >= 5) return 'Beginner';
    return 'New';
  }

  // Preference getters
  bool get prefersDarkMode => preferences['darkMode'] ?? false;
  bool get prefersNotifications => preferences['notifications'] ?? true;
  String get preferredLanguage => preferences['language'] ?? 'en';
  double get preferredSearchRadius => preferences['searchRadius'] ?? 5.0;
  List<String> get preferredFountainTypes => 
      List<String>.from(preferences['fountainTypes'] ?? ['fountain', 'tap', 'refillStation']);

  // Methods to update preferences
  UserModel updatePreference(String key, dynamic value) {
    Map<String, dynamic> newPreferences = Map.from(preferences);
    newPreferences[key] = value;
    return copyWith(preferences: newPreferences);
  }

  UserModel addFavorite(String fountainId) {
    if (!favoriteFountainIds.contains(fountainId)) {
      return copyWith(
        favoriteFountainIds: [...favoriteFountainIds, fountainId],
      );
    }
    return this;
  }

  UserModel removeFavorite(String fountainId) {
    return copyWith(
      favoriteFountainIds: favoriteFountainIds.where((id) => id != fountainId).toList(),
    );
  }

  UserModel addContribution(String fountainId) {
    if (!contributedFountainIds.contains(fountainId)) {
      return copyWith(
        contributedFountainIds: [...contributedFountainIds, fountainId],
        contributionScore: contributionScore + 10,
      );
    }
    return this;
  }

  UserModel addValidation(String fountainId) {
    if (!validatedFountainIds.contains(fountainId)) {
      return copyWith(
        validatedFountainIds: [...validatedFountainIds, fountainId],
        contributionScore: contributionScore + 5,
      );
    }
    return this;
  }

  bool hasFavorited(String fountainId) => favoriteFountainIds.contains(fountainId);
  bool hasContributed(String fountainId) => contributedFountainIds.contains(fountainId);
  bool hasValidated(String fountainId) => validatedFountainIds.contains(fountainId);

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
