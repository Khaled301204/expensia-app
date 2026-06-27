import '../models/goal.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class GoalRepository {
  final ApiService _apiService = ApiService();

  Future<List<Goal>> getGoals() async {
    final response = await _apiService.get(AppConfig.goalsEndpoint);
    if (response.data['success'] == true) {
      final List goalsJson = response.data['data'];
      return goalsJson.map((json) => Goal.fromJson(json)).toList();
    }
    throw Exception('Failed to load goals');
  }

  Future<Goal> createGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
    double? currentAmount,
  }) async {
    final response = await _apiService.post(
      AppConfig.goalsEndpoint,
      data: {
        'name': name,
        'targetAmount': targetAmount,
        'deadline': deadline.toIso8601String().split('T')[0],
        if (currentAmount != null && currentAmount > 0)
          'currentAmount': currentAmount,
      },
    );
    if (response.data['success'] == true) {
      return Goal.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to create goal');
  }

  Future<Goal> addSavings(int goalId, double amount) async {
    final response = await _apiService.post(
      '${AppConfig.goalsEndpoint}/$goalId/savings',
      data: {'amount': amount},
    );
    if (response.data['success'] == true) {
      return Goal.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to add savings');
  }

  Future<Goal> withdrawSavings(int goalId, double amount) async {
    final response = await _apiService.post(
      '${AppConfig.goalsEndpoint}/$goalId/withdraw',
      data: {'amount': amount},
    );
    if (response.data['success'] == true) {
      return Goal.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to withdraw savings');
  }

  Future<Goal> updateGoal({
    required int id,
    String? name,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    final response = await _apiService.put(
      '${AppConfig.goalsEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (deadline != null) 'deadline': deadline.toIso8601String().split('T')[0],
      },
    );
    if (response.data['success'] == true) {
      return Goal.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to update goal');
  }

  Future<void> deleteGoal(int id) async {
    await _apiService.delete('${AppConfig.goalsEndpoint}/$id');
  }
}
