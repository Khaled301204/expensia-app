import '../models/income.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class IncomeRepository {
  final ApiService _apiService = ApiService();

  Future<List<Income>> getIncomes() async {
    final response = await _apiService.get(AppConfig.incomesEndpoint);
    final body = response.data;
    if (body is Map && body['success'] == true) {
      final List raw = body['data'] as List;
      return raw.map((j) => Income.fromJson(j)).toList();
    }
    throw Exception('Failed to load incomes');
  }

  Future<Income> createIncome({
    required double amount,
    required DateTime date,
    required String source,
    String? frequency,
    bool isRecurring = false,
  }) async {
    final response = await _apiService.post(
      AppConfig.incomesEndpoint,
      data: {
        'amount': amount,
        'date': date.toIso8601String(),
        'source': source,
        if (frequency != null) 'frequency': frequency,
        'isRecurring': isRecurring,
      },
    );
    final body = response.data;
    if (body is Map && body['success'] == true) {
      return Income.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create income');
  }

  Future<void> deleteIncome(int id) async {
    await _apiService.delete('${AppConfig.incomesEndpoint}/$id');
  }
}
