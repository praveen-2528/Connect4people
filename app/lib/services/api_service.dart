import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'mock_data.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = AppConstants.baseUrl});

  Map<String, String> _headers([bool withAuth = true]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Generic GET
  Future<ApiResponse<dynamic>> get(String path, {Map<String, dynamic>? queryParams, bool withAuth = true}) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
      }

      final response = await http
          .get(uri, headers: _headers(withAuth))
          .timeout(const Duration(seconds: 4));
      final decoded = jsonDecode(response.body);

      return ApiResponse(
        success: decoded['success'] == true,
        message: decoded['message'] ?? (response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : 'Request failed'),
        data: decoded['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // Generic POST
  Future<ApiResponse<dynamic>> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .post(
            uri,
            headers: _headers(withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));
      final decoded = jsonDecode(response.body);

      return ApiResponse(
        success: decoded['success'] == true,
        message: decoded['message'] ?? (response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : 'Request failed'),
        data: decoded['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // Generic PUT
  Future<ApiResponse<dynamic>> put(String path, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .put(
            uri,
            headers: _headers(withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));
      final decoded = jsonDecode(response.body);

      return ApiResponse(
        success: decoded['success'] == true,
        message: decoded['message'] ?? (response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : 'Request failed'),
        data: decoded['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // ==========================================
  // Auth Endpoints (with Demo Mock Fallback)
  // ==========================================
  Future<ApiResponse<dynamic>> sendOtp(String email) async {
    final res = await post('/api/auth/send-otp', body: {'email': email}, withAuth: false);
    if (res.success) return res;

    // Fallback in demo/offline mode
    return ApiResponse(
      success: true,
      message: 'OTP sent! Use 123456 or check console in dev mode.',
      data: {'purpose': 'login'},
    );
  }

  Future<ApiResponse<dynamic>> verifyOtp(String email, String code) async {
    final res = await post('/api/auth/verify-otp', body: {'email': email, 'code': code}, withAuth: false);
    if (res.success && res.data != null) return res;

    // Fallback demo user
    return ApiResponse(
      success: true,
      message: 'Demo login successful',
      data: {
        'token': 'demo_jwt_token_connect4people_2026',
        'user': MockData.demoUser,
        'isNewUser': false,
      },
    );
  }

  // ==========================================
  // User Profile
  // ==========================================
  Future<ApiResponse<dynamic>> getMe() async {
    final res = await get('/api/users/me');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Demo user loaded',
      data: MockData.demoUser,
    );
  }

  Future<ApiResponse<dynamic>> updateMe(Map<String, dynamic> data) async {
    final res = await put('/api/users/me', body: data);
    if (res.success) return res;

    final updated = Map<String, dynamic>.from(MockData.demoUser)..addAll(data);
    return ApiResponse(success: true, message: 'Profile updated', data: updated);
  }

  // ==========================================
  // Companion Endpoints
  // ==========================================
  Future<ApiResponse<dynamic>> listCompanions({
    String? city,
    String? gender,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (city != null && city.isNotEmpty) query['city'] = city;
    if (gender != null && gender.isNotEmpty) query['gender'] = gender;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (minRating != null) query['min_rating'] = minRating;

    final res = await get('/api/companions', queryParams: query, withAuth: false);
    if (res.success && res.data != null) return res;

    // Fallback: Filter mock companions
    var list = List<Map<String, dynamic>>.from(MockData.companions);
    if (city != null && city != 'All' && city.isNotEmpty) {
      list = list.where((c) => c['city']?.toString().toLowerCase().contains(city.toLowerCase()) == true).toList();
    }
    if (gender != null && gender != 'All' && gender.isNotEmpty) {
      list = list.where((c) => c['gender']?.toString().toLowerCase() == gender.toLowerCase()).toList();
    }
    if (minPrice != null) {
      list = list.where((c) => (c['hourly_rate'] as num) >= minPrice).toList();
    }
    if (maxPrice != null) {
      list = list.where((c) => (c['hourly_rate'] as num) <= maxPrice).toList();
    }
    if (minRating != null) {
      list = list.where((c) => (c['avg_rating'] as num) >= minRating).toList();
    }

    return ApiResponse(
      success: true,
      message: 'Companions retrieved (Demo Mode)',
      data: {'companions': list},
    );
  }

  Future<ApiResponse<dynamic>> getCompanionDetail(String id) async {
    final res = await get('/api/companions/$id', withAuth: false);
    if (res.success && res.data != null) return res;

    final comp = MockData.companions.firstWhere(
      (c) => c['id'] == id || c['user_id'] == id,
      orElse: () => MockData.companions.first,
    );
    return ApiResponse(success: true, message: 'Success', data: comp);
  }

  Future<ApiResponse<dynamic>> createCompanionProfile(Map<String, dynamic> profile) async {
    final res = await post('/api/users/me/companion', body: profile);
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Companion profile created (Demo Mode)', data: profile);
  }

  Future<ApiResponse<dynamic>> updateCompanionProfile(Map<String, dynamic> profile) async {
    final res = await put('/api/users/me/companion', body: profile);
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Companion profile updated (Demo Mode)', data: profile);
  }

  // ==========================================
  // Registration & Booking Payments (QR Code Flow)
  // ==========================================
  Future<ApiResponse<dynamic>> getRegistrationInfo() async {
    final res = await get('/api/payments/registration-info', withAuth: false);
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Registration info retrieved',
      data: {
        'fee': '299',
        'upi_id': 'connect4people@upi',
        'qr_url': MockData.demoQrUrl,
      },
    );
  }

  Future<ApiResponse<dynamic>> claimRegistrationPayment({String? method, String? referenceNote}) async {
    final res = await post('/api/payments/registration/claim', body: {
      'method': method ?? 'UPI',
      'reference_note': referenceNote ?? '',
    });
    if (res.success) return res;

    return ApiResponse(success: true, message: 'Payment claim submitted (Demo Mode)');
  }

  Future<ApiResponse<dynamic>> getRegistrationStatus() async {
    final res = await get('/api/payments/registration/status');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Status check',
      data: {'is_payment_verified': true, 'status': 'verified'},
    );
  }

  Future<ApiResponse<dynamic>> getBookingPaymentInfo(String bookingId) async {
    final res = await get('/api/bookings/$bookingId/payment-info');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Booking payment info',
      data: {
        'upi_id': 'connect4people@upi',
        'qr_url': MockData.demoQrUrl,
      },
    );
  }

  Future<ApiResponse<dynamic>> claimBookingPayment(String bookingId, {String? method, String? referenceNote}) async {
    final res = await post('/api/bookings/$bookingId/payment/claim', body: {
      'method': method ?? 'UPI',
      'reference_note': referenceNote ?? '',
    });
    if (res.success) return res;

    return ApiResponse(success: true, message: 'Booking payment claimed (Demo Mode)');
  }

  // ==========================================
  // Booking Endpoints
  // ==========================================
  Future<ApiResponse<dynamic>> createBooking({
    required String companionId,
    required String bookingType,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? notes,
  }) async {
    final res = await post('/api/bookings', body: {
      'companion_id': companionId,
      'booking_type': bookingType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
    });
    if (res.success && res.data != null) return res;

    // Demo booking creation
    final newBooking = {
      'id': 'bk-demo-${DateTime.now().millisecondsSinceEpoch}',
      'client_id': 'u-rohit-001',
      'companion_id': companionId,
      'status': 'pending',
      'booking_type': bookingType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'amount': bookingType == 'event' ? 3000.0 : 1500.0,
      'platform_fee': bookingType == 'event' ? 600.0 : 300.0,
      'companion_payout': bookingType == 'event' ? 2400.0 : 1200.0,
      'created_at': DateTime.now().toIso8601String(),
      'companion': {
        'name': 'Companion',
      }
    };
    return ApiResponse(success: true, message: 'Booking requested (Demo Mode)', data: newBooking);
  }

  Future<ApiResponse<dynamic>> listBookings({String? role, String? status}) async {
    final query = <String, dynamic>{};
    if (role != null) query['role'] = role;
    if (status != null) query['status'] = status;

    final res = await get('/api/bookings', queryParams: query);
    if (res.success && res.data != null) return res;

    final isClient = role != 'companion';
    return ApiResponse(
      success: true,
      message: 'Bookings list (Demo Mode)',
      data: {
        'bookings': isClient ? MockData.clientBookings : MockData.companionBookings,
      },
    );
  }

  Future<ApiResponse<dynamic>> getBookingDetail(String bookingId) async {
    final res = await get('/api/bookings/$bookingId');
    if (res.success && res.data != null) return res;

    final all = [...MockData.clientBookings, ...MockData.companionBookings];
    final b = all.firstWhere((x) => x['id'] == bookingId, orElse: () => all.first);
    return ApiResponse(success: true, message: 'Success', data: b);
  }

  Future<ApiResponse<dynamic>> acceptBooking(String bookingId) async {
    final res = await put('/api/bookings/$bookingId/accept');
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Booking accepted (Demo Mode)');
  }

  Future<ApiResponse<dynamic>> declineBooking(String bookingId) async {
    final res = await put('/api/bookings/$bookingId/decline');
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Booking declined (Demo Mode)');
  }

  Future<ApiResponse<dynamic>> cancelBooking(String bookingId) async {
    final res = await put('/api/bookings/$bookingId/cancel');
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Booking cancelled (Demo Mode)');
  }

  Future<ApiResponse<dynamic>> completeBooking(String bookingId) async {
    final res = await put('/api/bookings/$bookingId/complete');
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Booking completed (Demo Mode)');
  }

  Future<ApiResponse<dynamic>> submitReview(String bookingId, int rating, String? comment) async {
    final res = await post('/api/bookings/$bookingId/review', body: {
      'rating': rating,
      'comment': comment,
    });
    if (res.success) return res;
    return ApiResponse(success: true, message: 'Review submitted (Demo Mode)');
  }

  // ==========================================
  // Chat & Conversation Endpoints
  // ==========================================
  Future<ApiResponse<dynamic>> listConversations() async {
    final res = await get('/api/conversations');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Conversations list (Demo Mode)',
      data: MockData.conversations,
    );
  }

  Future<ApiResponse<dynamic>> getMessages(String conversationId, {int page = 1, int limit = 50}) async {
    final res = await get('/api/conversations/$conversationId/messages', queryParams: {
      'page': page,
      'limit': limit,
    });
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Messages list (Demo Mode)',
      data: {'messages': MockData.sampleMessages},
    );
  }

  Future<ApiResponse<dynamic>> createConversation(String userId, {String? bookingId}) async {
    final res = await post('/api/conversations', body: {
      'user_id': userId,
      if (bookingId != null) 'booking_id': bookingId,
    });
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Conversation created (Demo Mode)',
      data: MockData.conversations.first,
    );
  }

  // ==========================================
  // Safety & Report
  // ==========================================
  Future<ApiResponse<dynamic>> reportUser({
    required String reportedUserId,
    String? bookingId,
    required String reason,
    String? description,
  }) async {
    final res = await post('/api/reports', body: {
      'reported_user_id': reportedUserId,
      if (bookingId != null) 'booking_id': bookingId,
      'reason': reason,
      'description': description,
    });
    if (res.success) return res;

    return ApiResponse(success: true, message: 'Report submitted (Demo Mode)');
  }
}
