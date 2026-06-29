import 'package:flutter/material.dart';
import '../../data/models/expense.dart';
import '../../data/models/voice_preview.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalExpenses {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Load expenses
  Future<void> loadExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _expenseRepository.getExpenses(
        size: 100,
        startDate: startDate,
        endDate: endDate,
      );
      _expenses.sort((a, b) => b.id.compareTo(a.id));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create expense — category is AI-assigned by backend
  Future<bool> createExpense({
    required double amount,
    required DateTime date,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool isRecurring = false,
    String? frequency,
    bool recurringActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final expense = await _expenseRepository.createExpense(
        amount: amount,
        date: date,
        description: description,
        merchant: merchant,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
        frequency: frequency,
        recurringActive: recurringActive,
      );
      _expenses.insert(0, expense);
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

  // Step 1: Get voice expense preview (no expense created yet)
  Future<VoicePreview?> previewVoiceExpense(String audioFilePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final preview = await _expenseRepository.previewVoiceExpense(audioFilePath);
      _isLoading = false;
      notifyListeners();
      return preview;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Step 2: Confirm and create the expense from corrected preview data
  Future<bool> confirmVoiceExpense(VoicePreview preview) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final expense = await _expenseRepository.confirmVoiceExpense(preview);
      _expenses.insert(0, expense);
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

  // Update expense
  Future<bool> updateExpense({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _expenseRepository.updateExpense(
        id: id,
        amount: amount,
        categoryId: categoryId,
        date: date,
        description: description,
        merchant: merchant,
        paymentMethod: paymentMethod,
        frequency: frequency,
        recurringActive: recurringActive,
      );
      final idx = _expenses.indexWhere((e) => e.id == id);
      if (idx != -1) _expenses[idx] = updated;
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

  // Delete expense
  Future<bool> deleteExpense(int id) async {
    try {
      await _expenseRepository.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get expenses by category
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((e) => e.categoryName == category).toList();
  }

  // Get expenses by date range
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((e) => 
      e.date.isAfter(start) && e.date.isBefore(end)
    ).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
