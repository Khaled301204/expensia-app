import '../models/budget.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';
import 'category_repository.dart';

class BudgetRepository {
  final ApiService _apiService = ApiService();
  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<List<Budget>> getBudgets() async {
    final responseFuture = _apiService.get(AppConfig.budgetsEndpoint);
    final categoriesFuture = _categoryRepository.getCategories();
    final response = await responseFuture;
    final categories = await categoriesFuture;
    final categoryMap = {for (final c in categories) c.id: c.name};

    if (response.data['success'] == true) {
      final List budgetsJson = response.data['data'];
      return budgetsJson.map((json) {
        final catId = json['categoryId'] as int?;
        final resolvedName = categoryMap[catId] ?? 'Unknown';
        return Budget.fromJson({...json, 'categoryName': resolvedName});
      }).toList();
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
    final categories = await _categoryRepository.getCategories();
    final categoryMap = {for (final c in categories) c.id: c.name};

    final response = await _apiService.post(
      AppConfig.budgetsEndpoint,
      data: {
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
        'alertThreshold': alertThreshold,
      },
    );
    if (response.data['success'] == true) {
      final json = response.data['data'];
      final catId = json['categoryId'] as int?;
      return Budget.fromJson({...json, 'categoryName': categoryMap[catId] ?? 'Unknown'});
    }
    throw Exception('Failed to create budget');
  }

  Future<void> deleteBudget(int id) async {
    await _apiService.delete('${AppConfig.budgetsEndpoint}/$id');
  }
}
