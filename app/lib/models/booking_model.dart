class BookingModel {
  final String id;
  final String clientId;
  final String companionId;
  final String status; // pending, accepted, ongoing, completed, cancelled, declined
  final String bookingType; // hourly, event
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? notes;
  final double amount;
  final double platformFee;
  final double companionPayout;
  final DateTime createdAt;
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? companion;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.companionId,
    required this.status,
    required this.bookingType,
    required this.startTime,
    required this.endTime,
    this.location,
    this.notes,
    required this.amount,
    required this.platformFee,
    required this.companionPayout,
    required this.createdAt,
    this.client,
    this.companion,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      companionId: json['companion_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      bookingType: json['booking_type']?.toString() ?? 'hourly',
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString()) ?? DateTime.now().add(const Duration(hours: 2))
          : DateTime.now().add(const Duration(hours: 2)),
      location: json['location']?.toString(),
      notes: json['notes']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      platformFee: double.tryParse(json['platform_fee']?.toString() ?? '0') ?? 0.0,
      companionPayout: double.tryParse(json['companion_payout']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      client: json['client'] is Map<String, dynamic> ? json['client'] : null,
      companion: json['companion'] is Map<String, dynamic> ? json['companion'] : null,
    );
  }

  String get otherPartyName {
    if (companion != null && companion!['name'] != null) {
      return companion!['name'];
    }
    if (client != null && client!['name'] != null) {
      return client!['name'];
    }
    return 'User';
  }

  String? get otherPartyAvatar {
    if (companion != null) return companion!['avatar_url'];
    if (client != null) return client!['avatar_url'];
    return null;
  }
}
