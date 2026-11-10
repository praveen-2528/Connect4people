import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class BookingState {
  final bool isLoading;
  final List<BookingModel> clientBookings;
  final List<BookingModel> companionBookings;
  final String? errorMessage;

  BookingState({
    required this.isLoading,
    required this.clientBookings,
    required this.companionBookings,
    this.errorMessage,
  });

  factory BookingState.initial() => BookingState(
        isLoading: false,
        clientBookings: [],
        companionBookings: [],
      );

  BookingState copyWith({
    bool? isLoading,
    List<BookingModel>? clientBookings,
    List<BookingModel>? companionBookings,
    String? errorMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      clientBookings: clientBookings ?? this.clientBookings,
      companionBookings: companionBookings ?? this.companionBookings,
      errorMessage: errorMessage,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final ApiService _api = ApiService();

  BookingNotifier() : super(BookingState.initial()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Fetch client bookings
    final resClient = await _api.listBookings(role: 'client');
    // Fetch companion bookings
    final resCompanion = await _api.listBookings(role: 'companion');

    List<BookingModel> clientList = [];
    List<BookingModel> companionList = [];

    if (resClient.success && resClient.data != null) {
      final List list = resClient.data['bookings'] ?? resClient.data ?? [];
      clientList = list.map((b) => BookingModel.fromJson(b)).toList();
    }

    if (resCompanion.success && resCompanion.data != null) {
      final List list = resCompanion.data['bookings'] ?? resCompanion.data ?? [];
      companionList = list.map((b) => BookingModel.fromJson(b)).toList();
    }

    state = state.copyWith(
      isLoading: false,
      clientBookings: clientList,
      companionBookings: companionList,
    );
  }

  Future<BookingModel?> createBooking({
    required String companionId,
    required String bookingType,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _api.createBooking(
      companionId: companionId,
      bookingType: bookingType,
      startTime: startTime,
      endTime: endTime,
      location: location,
      notes: notes,
    );

    state = state.copyWith(isLoading: false);

    if (res.success && res.data != null) {
      final booking = BookingModel.fromJson(res.data);
      fetchBookings();
      return booking;
    } else {
      state = state.copyWith(errorMessage: res.message);
      return null;
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    final res = await _api.acceptBooking(bookingId);
    if (res.success) {
      fetchBookings();
      return true;
    }
    return false;
  }

  Future<bool> declineBooking(String bookingId) async {
    final res = await _api.declineBooking(bookingId);
    if (res.success) {
      fetchBookings();
      return true;
    }
    return false;
  }

  Future<bool> cancelBooking(String bookingId) async {
    final res = await _api.cancelBooking(bookingId);
    if (res.success) {
      fetchBookings();
      return true;
    }
    return false;
  }

  Future<bool> completeBooking(String bookingId) async {
    final res = await _api.completeBooking(bookingId);
    if (res.success) {
      fetchBookings();
      return true;
    }
    return false;
  }

  Future<bool> submitReview(String bookingId, int rating, String? comment) async {
    final res = await _api.submitReview(bookingId, rating, comment);
    if (res.success) {
      fetchBookings();
      return true;
    }
    return false;
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});
