import '../models/expense.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class ExpenseRepository {
  final ApiService _apiService = ApiService();

  // Get all expenses
  Future<List<Expense>> getExpenses({
    int page = 0,
    int size = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = {
      'page': page,
      'size': size,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _apiService.get(
      AppConfig.expensesEndpoint,
      queryParameters: queryParams,
    );

    if (response.data['success']) {
      final List expensesJson = response.data['data']['expenses'];
      return expensesJson.map((json) => Expense.fromJson(json)).toList();
    }

    throw Exception('Failed to load expenses');
  }

  // Get expense by ID
  Future<Expense> getExpenseById(int id) async {
    final response = await _apiService.get('${AppConfig.expensesEndpoint}/$id');

    if (response.data['success']) {
      return Expense.fromJson(response.data['data']);
    }

    throw Exception('Failed to load expense');
  }

  // Create expense
  Future<Expense> createExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? description,
    String? merchant,
    String? paymentMethod,
  }) async {
    final response = await _apiService.post(
      AppConfig.expensesEndpoint,
      data: {
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'description': description,
        'merchant': merchant,
        'paymentMethod': paymentMethod,
      },
    );

    if (response.data['success']) {
      return Expense.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Failed to create expense');
  }

  // Create voice expense
  Future<Expense> createVoiceExpense(String audioFilePath) async {
    final response = await _apiService.uploadFile(
      AppConfig.voiceExpenseEndpoint,
      audioFilePath,
    );

    if (response.data['success']) {
      return Expense.fromJson(response.data['data']['expense']);
    }

    throw Exception(response.data['message'] ?? 'Failed to create voice expense');
  }

  // Update expense
  Future<Expense> updateExpense({
    required int id,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? description,
    String? merchant,
    String? paymentMethod,
  }) async {
    final response = await _apiService.put(
      '${AppConfig.expensesEndpoint}/$id',
      data: {
        if (amount != null) 'amount': amount,
        if (categoryId != null) 'categoryId': categoryId,
        if (date != null) 'date': date.toIso8601String(),
        if (description != null) 'description': description,
        if (merchant != null) 'merchant': merchant,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
    );

    if (response.data['success']) {
      return Expense.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Failed to update expense');
  }

  // Delete expense
  Future<void> deleteExpense(int id) async {
    final response = await _apiService.delete('${AppConfig.expensesEndpoint}/$id');

    if (!response.data['success']) {
      throw Exception(response.data['message'] ?? 'Failed to delete expense');
    }
  }
}
