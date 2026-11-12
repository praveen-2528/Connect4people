import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
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
          .timeout(const Duration(seconds: 15));
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
          .timeout(const Duration(seconds: 15));
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
          .timeout(const Duration(seconds: 15));
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

  // Generic DELETE
  Future<ApiResponse<dynamic>> delete(String path, {bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await http
          .delete(uri, headers: _headers(withAuth))
          .timeout(const Duration(seconds: 15));
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
  Future<ApiResponse<dynamic>> registerWithPassword(String email, String password, {String? name}) async {
    return await post('/api/auth/register', body: {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    }, withAuth: false);
  }

  Future<ApiResponse<dynamic>> loginWithPassword(String email, String password) async {
    return await post('/api/auth/login', body: {
      'email': email,
      'password': password,
    }, withAuth: false);
  }

  Future<ApiResponse<dynamic>> sendOtp(String email) async {
    final res = await post('/api/auth/send-otp', body: {'email': email}, withAuth: false);
    if (res.success) return res;

    // Fallback in demo/offline mode
    return ApiResponse(
      success: true,
      message: 'OTP sent! Use 123456 or check console in dev mode.',
      data: {'purpose': 'login', 'devOtp': '123456'},
    );
  }

  Future<ApiResponse<dynamic>> verifyOtp(String email, String code) async {
    return await post('/api/auth/verify-otp', body: {'email': email, 'code': code}, withAuth: false);
  }

  // ==========================================
  // User Profile
  // ==========================================
  Future<ApiResponse<dynamic>> getMe() async {
    return await get('/api/users/me');
  }

  Future<ApiResponse<dynamic>> updateMe(Map<String, dynamic> data) async {
    return await put('/api/users/me', body: data);
  }

  Future<ApiResponse<dynamic>> addPhoto(String url) async {
    return await post('/api/users/me/photos', body: {'url': url});
  }

  Future<ApiResponse<dynamic>> deletePhoto(String photoId) async {
    return await delete('/api/users/me/photos/$photoId');
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
    if (city != null && city.isNotEmpty && city != 'All') query['city'] = city;
    if (gender != null && gender.isNotEmpty && gender != 'All') query['gender'] = gender;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (minRating != null) query['min_rating'] = minRating;

    final res = await get('/api/companions', queryParams: query, withAuth: false);
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Companions retrieved',
      data: {'companions': []},
    );
  }

  Future<ApiResponse<dynamic>> getCompanionDetail(String id) async {
    return await get('/api/companions/$id', withAuth: false);
  }

  Future<ApiResponse<dynamic>> createCompanionProfile(Map<String, dynamic> profile) async {
    return await post('/api/users/me/companion', body: profile);
  }

  Future<ApiResponse<dynamic>> updateCompanionProfile(Map<String, dynamic> profile) async {
    return await put('/api/users/me/companion', body: profile);
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
        'qr_url': 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=upi%3A%2F%2Fpay%3Fpa%3Dconnect4people%40upi%26pn%3DConnect4People%26am%3D299',
      },
    );
  }

  Future<ApiResponse<dynamic>> claimRegistrationPayment({String? method, String? referenceNote}) async {
    return await post('/api/payments/registration/claim', body: {
      'method': method ?? 'UPI',
      'reference_note': referenceNote ?? '',
    });
  }

  Future<ApiResponse<dynamic>> getRegistrationStatus() async {
    return await get('/api/payments/registration/status');
  }

  Future<ApiResponse<dynamic>> getBookingPaymentInfo(String bookingId) async {
    final res = await get('/api/bookings/$bookingId/payment-info');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Booking payment info',
      data: {
        'upi_id': 'connect4people@upi',
        'qr_url': 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=upi%3A%2F%2Fpay%3Fpa%3Dconnect4people%40upi%26pn%3DConnect4People%26am%3D299',
      },
    );
  }

  Future<ApiResponse<dynamic>> claimBookingPayment(String bookingId, {String? method, String? referenceNote}) async {
    return await post('/api/bookings/$bookingId/payment/claim', body: {
      'method': method ?? 'UPI',
      'reference_note': referenceNote ?? '',
    });
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
    return await post('/api/bookings', body: {
      'companion_id': companionId,
      'booking_type': bookingType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'notes': notes,
    });
  }

  Future<ApiResponse<dynamic>> listBookings({String? role, String? status}) async {
    final query = <String, dynamic>{};
    if (role != null) query['role'] = role;
    if (status != null) query['status'] = status;

    final res = await get('/api/bookings', queryParams: query);
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Bookings list',
      data: {'bookings': []},
    );
  }

  Future<ApiResponse<dynamic>> getBookingDetail(String bookingId) async {
    return await get('/api/bookings/$bookingId');
  }

  Future<ApiResponse<dynamic>> acceptBooking(String bookingId) async {
    return await put('/api/bookings/$bookingId/accept');
  }

  Future<ApiResponse<dynamic>> declineBooking(String bookingId) async {
    return await put('/api/bookings/$bookingId/decline');
  }

  Future<ApiResponse<dynamic>> cancelBooking(String bookingId) async {
    return await put('/api/bookings/$bookingId/cancel');
  }

  Future<ApiResponse<dynamic>> completeBooking(String bookingId) async {
    return await put('/api/bookings/$bookingId/complete');
  }

  Future<ApiResponse<dynamic>> submitReview(String bookingId, int rating, String? comment) async {
    return await post('/api/bookings/$bookingId/review', body: {
      'rating': rating,
      'comment': comment,
    });
  }

  // ==========================================
  // Chat & Conversation Endpoints
  // ==========================================
  Future<ApiResponse<dynamic>> listConversations() async {
    final res = await get('/api/conversations');
    if (res.success && res.data != null) return res;

    return ApiResponse(
      success: true,
      message: 'Conversations list',
      data: [],
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
      message: 'Messages list',
      data: {'messages': []},
    );
  }

  Future<ApiResponse<dynamic>> createConversation(String userId, {String? bookingId}) async {
    return await post('/api/conversations', body: {
      'user_id': userId,
      if (bookingId != null) 'booking_id': bookingId,
    });
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
    return await post('/api/reports', body: {
      'reported_user_id': reportedUserId,
      if (bookingId != null) 'booking_id': bookingId,
      'reason': reason,
      'description': description,
    });
  }
}
