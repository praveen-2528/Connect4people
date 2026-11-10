import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(AppConstants.tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  static Future<void> saveUser(UserModel user) async {
    await init();
    await _prefs!.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  static UserModel? getUser() {
    final raw = _prefs?.getString(AppConstants.userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAuth() async {
    await init();
    await _prefs!.remove(AppConstants.tokenKey);
    await _prefs!.remove(AppConstants.userKey);
  }
}
