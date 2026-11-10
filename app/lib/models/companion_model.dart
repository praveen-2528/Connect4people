class CompanionCardModel {
  final String id; // companion profile id
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? city;
  final double hourlyRate;
  final double eventRate;
  final String? tagline;
  final double avgRating;
  final int totalBookings;
  final List<String> languages;
  final List<String> interests;
  final List<String> availableDays;
  final List<String> photos;

  CompanionCardModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.city,
    required this.hourlyRate,
    required this.eventRate,
    this.tagline,
    required this.avgRating,
    required this.totalBookings,
    required this.languages,
    required this.interests,
    required this.availableDays,
    required this.photos,
  });

  factory CompanionCardModel.fromJson(Map<String, dynamic> json) {
    // Backend can return user with nested companion_profile or flat
    final profile = json['companion_profile'] ?? json;
    final user = json['user'] ?? json;

    List<String> photoList = [];
    if (json['photos'] != null && json['photos'] is List) {
      photoList = (json['photos'] as List)
          .map((p) => (p is Map ? p['url']?.toString() : p.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (photoList.isEmpty && user['avatar_url'] != null) {
      photoList.add(user['avatar_url']);
    }

    return CompanionCardModel(
      id: profile['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? profile['user_id']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Companion',
      avatarUrl: user['avatar_url']?.toString(),
      bio: user['bio']?.toString() ?? profile['bio']?.toString(),
      gender: user['gender']?.toString(),
      city: user['city']?.toString(),
      hourlyRate: profile['hourly_rate'] != null
          ? double.tryParse(profile['hourly_rate'].toString()) ?? 500.0
          : 500.0,
      eventRate: profile['event_rate'] != null
          ? double.tryParse(profile['event_rate'].toString()) ?? 2500.0
          : 2500.0,
      tagline: profile['tagline']?.toString() ?? 'Available for events and social outings',
      avgRating: profile['avg_rating'] != null
          ? double.tryParse(profile['avg_rating'].toString()) ?? 5.0
          : 5.0,
      totalBookings: profile['total_bookings'] != null
          ? int.tryParse(profile['total_bookings'].toString()) ?? 0
          : 0,
      languages: profile['languages'] != null ? List<String>.from(profile['languages']) : ['English', 'Hindi'],
      interests: profile['interests'] != null ? List<String>.from(profile['interests']) : ['Dinner', 'Movies', 'Events'],
      availableDays: profile['available_days'] != null
          ? List<String>.from(profile['available_days'])
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      photos: photoList,
    );
  }
}
