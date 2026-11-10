class UserModel {
  final String id;
  final String? name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? dob;
  final String? city;
  final bool isCompanion;
  final bool isVerified;
  final bool isActive;
  final bool isPaymentVerified;
  final String role;
  final CompanionProfileModel? companionProfile;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dob,
    this.city,
    required this.isCompanion,
    required this.isVerified,
    required this.isActive,
    required this.isPaymentVerified,
    required this.role,
    this.companionProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      gender: json['gender'],
      dob: json['dob'],
      city: json['city'],
      isCompanion: json['is_companion'] == true,
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] != false,
      isPaymentVerified: json['is_payment_verified'] == true,
      role: json['role'] ?? 'user',
      companionProfile: json['companion_profile'] != null
          ? CompanionProfileModel.fromJson(json['companion_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'gender': gender,
      'dob': dob,
      'city': city,
      'is_companion': isCompanion,
      'is_verified': isVerified,
      'is_active': isActive,
      'is_payment_verified': isPaymentVerified,
      'role': role,
      if (companionProfile != null) 'companion_profile': companionProfile!.toJson(),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? gender,
    String? dob,
    String? city,
    bool? isCompanion,
    bool? isVerified,
    bool? isPaymentVerified,
    CompanionProfileModel? companionProfile,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      city: city ?? this.city,
      isCompanion: isCompanion ?? this.isCompanion,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive,
      isPaymentVerified: isPaymentVerified ?? this.isPaymentVerified,
      role: role,
      companionProfile: companionProfile ?? this.companionProfile,
    );
  }
}

class CompanionProfileModel {
  final String id;
  final String userId;
  final double hourlyRate;
  final double eventRate;
  final List<String> languages;
  final List<String> interests;
  final List<String> availableDays;
  final String? availableHoursStart;
  final String? availableHoursEnd;
  final String? tagline;
  final double avgRating;
  final int totalBookings;
  final bool isListed;

  CompanionProfileModel({
    required this.id,
    required this.userId,
    required this.hourlyRate,
    required this.eventRate,
    required this.languages,
    required this.interests,
    required this.availableDays,
    this.availableHoursStart,
    this.availableHoursEnd,
    this.tagline,
    required this.avgRating,
    required this.totalBookings,
    required this.isListed,
  });

  factory CompanionProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanionProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      hourlyRate: (json['hourly_rate'] != null) ? double.parse(json['hourly_rate'].toString()) : 0.0,
      eventRate: (json['event_rate'] != null) ? double.parse(json['event_rate'].toString()) : 0.0,
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : [],
      availableDays: json['available_days'] != null ? List<String>.from(json['available_days']) : [],
      availableHoursStart: json['available_hours_start'],
      availableHoursEnd: json['available_hours_end'],
      tagline: json['tagline'],
      avgRating: (json['avg_rating'] != null) ? double.parse(json['avg_rating'].toString()) : 5.0,
      totalBookings: json['total_bookings'] ?? 0,
      isListed: json['is_listed'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'hourly_rate': hourlyRate,
      'event_rate': eventRate,
      'languages': languages,
      'interests': interests,
      'available_days': availableDays,
      'available_hours_start': availableHoursStart,
      'available_hours_end': availableHoursEnd,
      'tagline': tagline,
      'avg_rating': avgRating,
      'total_bookings': totalBookings,
      'is_listed': isListed,
    };
  }
}
