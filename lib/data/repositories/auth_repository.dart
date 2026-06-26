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
    String? riskPreference,
  }) async {
    final response = await _apiService.post(
      '${AppConfig.authEndpoint}/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (riskPreference != null) 'riskPreference': riskPreference,
      },
    );

    if (response.data['success'] == true) {
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

    if (response.data['success'] == true) {
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

  // Fetch current user from server (gets riskPreference + createdAt)
  Future<User> fetchCurrentUser() async {
    final response = await _apiService.get(AppConfig.userMeEndpoint);
    if (response.data['success'] == true) {
      final user = User.fromJson(response.data['data']);
      await _storageService.saveUser(user);
      return user;
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch user');
  }

  // Update profile
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? riskPreference,
  }) async {
    final response = await _apiService.put(
      AppConfig.userMeEndpoint,
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (riskPreference != null) 'riskPreference': riskPreference,
      },
    );

    if (response.data['success'] == true) {
      final user = User.fromJson(response.data['data']);
      await _storageService.saveUser(user);
      return user;
    }

    throw Exception(response.data['message'] ?? 'Update failed');
  }
}
