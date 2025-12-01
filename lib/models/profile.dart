class UserProfile {
  final String? id;
  final String name;
  final int age;
  final String gender; // 'male', 'female', 'other'
  final String city;
  final String bio;
  final List<String> interests;
  final double? lat;
  final double? lng;
  final List<String> photoUrls;
  final double maxDistanceKm;
  final bool isVerified; // 프로필 인증 여부
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    this.gender = 'other',
    required this.city,
    required this.bio,
    this.interests = const [],
    this.lat,
    this.lng,
    this.photoUrls = const [],
    this.maxDistanceKm = 30,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'city': city,
      'bio': bio,
      'interests': interests,
      'lat': lat,
      'lng': lng,
      'photoUrls': photoUrls,
      'maxDistanceKm': maxDistanceKm,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'other',
      city: map['city'] ?? '',
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      maxDistanceKm: map['maxDistanceKm'] is num
          ? (map['maxDistanceKm'] as num).toDouble()
          : 30,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? city,
    String? bio,
    List<String>? interests,
    double? lat,
    double? lng,
    List<String>? photoUrls,
    double? maxDistanceKm,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photoUrls: photoUrls ?? this.photoUrls,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

