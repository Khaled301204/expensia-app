import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _apiService.post(
      '${AppConfig.authEndpoint}/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      },
    );

    if (response.data['success']) {
      final data = response.data['data'];
      final token = data['token'];
      final user = User.fromJson(data);

      await _storageService.saveToken(token);
      await _storageService.saveUser(user);

      return {'success': true, 'user': user};
    }

    throw Exception(response.data['message'] ?? 'Registration failed');
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '${AppConfig.authEndpoint}/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.data['success']) {
      final data = response.data['data'];
      final token = data['token'];
      final user = User.fromJson(data);

      await _storageService.saveToken(token);
      await _storageService.saveUser(user);

      return {'success': true, 'user': user};
    }

    throw Exception(response.data['message'] ?? 'Login failed');
  }

  // Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  // Update profile
  Future<User> updateProfile({
    required int userId,
    String? name,
    String? phone,
    String? riskPreference,
  }) async {
    final response = await _apiService.put(
      '${AppConfig.authEndpoint}/profile/$userId',
      data: {
        'name': name,
        'phone': phone,
        'riskPreference': riskPreference,
      },
    );

    if (response.data['success']) {
      final user = User.fromJson(response.data['data']);
      await _storageService.saveUser(user);
      return user;
    }

    throw Exception(response.data['message'] ?? 'Update failed');
  }
}
