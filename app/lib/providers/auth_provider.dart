import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, unauthenticated, pendingPayment, authenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final bool isNewUser;
  final String? devOtp;

  AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
    this.isNewUser = false,
    this.devOtp,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    String? errorMessage,
    bool? isNewUser,
    String? devOtp,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
      devOtp: devOtp ?? this.devOtp,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api = ApiService();

  AuthNotifier() : super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = StorageService.getToken();
    final cachedUser = StorageService.getUser();

    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, token: token, user: cachedUser);

    // Fetch fresh profile from backend
    final response = await _api.getMe();
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data);
      await StorageService.saveUser(user);

      // Check payment status: user must be payment verified
      if (!user.isPaymentVerified && user.role != 'admin') {
        state = state.copyWith(status: AuthStatus.pendingPayment, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        SocketService.init();
      }
    } else {
      // If cached user exists and token still valid
      if (cachedUser != null) {
        if (!cachedUser.isPaymentVerified && cachedUser.role != 'admin') {
          state = state.copyWith(status: AuthStatus.pendingPayment, user: cachedUser);
        } else {
          state = state.copyWith(status: AuthStatus.authenticated, user: cachedUser);
          SocketService.init();
        }
      } else {
        await StorageService.clearAuth();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final response = await _api.sendOtp(email);
    if (!response.success) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: response.message,
      );
      return false;
    }
    final code = response.data is Map ? response.data['devOtp']?.toString() : null;
    state = state.copyWith(status: AuthStatus.unauthenticated, devOtp: code);
    return true;
  }

  Future<bool> loginWithPassword(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final response = await _api.loginWithPassword(email, password);
    return _processAuthResponse(response);
  }

  Future<bool> registerWithPassword(String email, String password, {String? name}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final response = await _api.registerWithPassword(email, password, name: name);
    return _processAuthResponse(response);
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final response = await _api.verifyOtp(email, code);
    return _processAuthResponse(response);
  }

  Future<bool> _processAuthResponse(ApiResponse<dynamic> response) async {
    if (response.success && response.data != null) {
      final token = response.data['token'];
      final userData = response.data['user'];
      final isNewUser = response.data['isNewUser'] == true;

      await StorageService.saveToken(token);
      final user = UserModel.fromJson(userData);
      await StorageService.saveUser(user);

      if (!user.isPaymentVerified && user.role != 'admin') {
        state = state.copyWith(
          status: AuthStatus.pendingPayment,
          user: user,
          token: token,
          isNewUser: isNewUser,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          token: token,
          isNewUser: isNewUser,
        );
        SocketService.init();
      }
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: response.message,
      );
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateMe(data);
    if (response.success && response.data != null) {
      final updated = UserModel.fromJson(response.data);
      await StorageService.saveUser(updated);
      state = state.copyWith(user: updated);
      return true;
    }
    return false;
  }

  Future<void> refreshUser() async {
    final response = await _api.getMe();
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data);
      await StorageService.saveUser(user);
      if (!user.isPaymentVerified && user.role != 'admin') {
        state = state.copyWith(status: AuthStatus.pendingPayment, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      }
    }
  }

  Future<void> logout() async {
    SocketService.disconnect();
    await StorageService.clearAuth();
    state = AuthState.initial().copyWith(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
