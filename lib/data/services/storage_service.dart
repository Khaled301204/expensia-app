import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../models/user.dart';

class StorageService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Token Management
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(AppConfig.tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await _prefs;
    await prefs.remove(AppConfig.tokenKey);
  }

  // User Management
  Future<void> saveUser(User user) async {
    final prefs = await _prefs;
    await prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await _prefs;
    final userString = prefs.getString(AppConfig.userKey);
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  Future<void> removeUser() async {
    final prefs = await _prefs;
    await prefs.remove(AppConfig.userKey);
  }

  // Theme Management
  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await _prefs;
    await prefs.setString(AppConfig.themeKey, themeMode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(AppConfig.themeKey);
  }

  // Clear All Data
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
