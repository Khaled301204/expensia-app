import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authRepository.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? riskPreference,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        riskPreference: riskPreference,
      );
      _user = result['user'];
      _user = await _authRepository.fetchCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      _user = result['user'];
      _user = await _authRepository.fetchCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? riskPreference,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.updateProfile(
        name: name,
        phone: phone,
        riskPreference: riskPreference,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
