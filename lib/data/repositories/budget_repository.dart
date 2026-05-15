import '../models/budget.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class BudgetRepository {
  final ApiService _apiService = ApiService();

  Future<List<Budget>> getBudgets() async {
    final response = await _apiService.get(AppConfig.budgetsEndpoint);
    if (response.data['success']) {
      final List budgetsJson = response.data['data'];
      return budgetsJson.map((json) => Budget.fromJson(json)).toList();
    }
    throw Exception('Failed to load budgets');
  }

  Future<Budget> createBudget({
    required int categoryId,
    required double limitAmount,
    required DateTime startDate,
    required DateTime endDate,
    double alertThreshold = 0.80,
  }) async {
    final response = await _apiService.post(
      AppConfig.budgetsEndpoint,
      data: {
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'alertThreshold': alertThreshold,
      },
    );
    if (response.data['success']) {
      return Budget.fromJson(response.data['data']);
    }
    throw Exception('Failed to create budget');
  }

  Future<void> deleteBudget(int id) async {
    await _apiService.delete('${AppConfig.budgetsEndpoint}/$id');
  }
}
