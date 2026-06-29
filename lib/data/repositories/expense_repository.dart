import '../models/expense.dart';
import '../models/voice_preview.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';
import 'category_repository.dart';

class ExpenseRepository {
  final ApiService _apiService = ApiService();
  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<Map<int, String>> _categoryMap() async {
    final categories = await _categoryRepository.getCategories();
    return {for (final c in categories) c.id: c.name};
  }

  Map<String, dynamic> _injectCategory(
      Map<String, dynamic> json, Map<int, String> map) {
    final catId = json['categoryId'] as int?;
    final name = map[catId] ?? 'Other';
    return {...json, 'category': name, 'categoryName': name};
  }

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
      'sort': 'id,desc',
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final responseFuture = _apiService.get(
      AppConfig.expensesEndpoint,
      queryParameters: queryParams,
    );
    final catMap = await _categoryMap();
    final response = await responseFuture;

    if (response.data['success'] == true) {
      final List expensesJson = response.data['data'];
      return expensesJson
          .map((json) => Expense.fromJson(_injectCategory(json, catMap)))
          .toList();
    }

    throw Exception('Failed to load expenses');
  }

  // Get expense by ID
  Future<Expense> getExpenseById(int id) async {
    final responseFuture = _apiService.get('${AppConfig.expensesEndpoint}/$id');
    final catMap = await _categoryMap();
    final response = await responseFuture;

    if (response.data['success'] == true) {
      return Expense.fromJson(_injectCategory(response.data['data'], catMap));
    }

    throw Exception('Failed to load expense');
  }

  // Create expense — categoryId is ignored by backend (AI assigns it)
  Future<Expense> createExpense({
    required double amount,
    required DateTime date,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool isRecurring = false,
    String? frequency,
    bool recurringActive = true,
  }) async {
    final catMapFuture = _categoryMap();
    final response = await _apiService.post(
      AppConfig.expensesEndpoint,
      data: {
        'amount': amount,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'description': description,
        'merchant': merchant,
        'paymentMethod': paymentMethod,
        if (isRecurring) 'isRecurring': true,
        if (isRecurring && frequency != null) 'frequency': frequency,
        if (isRecurring) 'recurringActive': recurringActive,
      },
    );

    if (response.data['success'] == true) {
      final catMap = await catMapFuture;
      return Expense.fromJson(_injectCategory(response.data['data'], catMap));
    }

    throw Exception(response.data['message'] ?? 'Failed to create expense');
  }

  // Step 1: Preview voice expense (returns editable preview, no expense created yet)
  Future<VoicePreview> previewVoiceExpense(String audioFilePath) async {
    final response = await _apiService.uploadFile(
      AppConfig.voicePreviewEndpoint,
      audioFilePath,
      additionalData: {'language': 'auto'},
    );
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    return VoicePreview.fromJson(data);
  }

  // Step 2: Confirm and create the expense from corrected preview data
  Future<Expense> confirmVoiceExpense(VoicePreview preview) async {
    final catMapFuture = _categoryMap();
    final response = await _apiService.post(
      AppConfig.voiceConfirmEndpoint,
      data: preview.toConfirmJson(),
    );
    final body = response.data;
    if (body is Map && body['success'] == true) {
      final catMap = await catMapFuture;
      return Expense.fromJson(_injectCategory(body['data'], catMap));
    }
    throw Exception(body['message'] ?? 'Failed to confirm voice expense');
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
    String? frequency,
    bool? recurringActive,
  }) async {
    final catMapFuture = _categoryMap();
    final response = await _apiService.put(
      '${AppConfig.expensesEndpoint}/$id',
      data: {
        if (amount != null) 'amount': amount,
        if (categoryId != null) 'categoryId': categoryId,
        if (date != null) 'date': date.toIso8601String(),
        if (description != null) 'description': description,
        if (merchant != null) 'merchant': merchant,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (frequency != null) 'frequency': frequency,
        if (recurringActive != null) 'recurringActive': recurringActive,
      },
    );

    if (response.data['success'] == true) {
      final catMap = await catMapFuture;
      return Expense.fromJson(_injectCategory(response.data['data'], catMap));
    }

    throw Exception(response.data['message'] ?? 'Failed to update expense');
  }

  // Delete expense
  Future<void> deleteExpense(int id) async {
    final response = await _apiService.delete('${AppConfig.expensesEndpoint}/$id');

    if (response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete expense');
    }
  }
}
