import 'package:flutter/material.dart';
import '../../data/models/budget.dart';
import '../../data/repositories/budget_repository.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetRepository _budgetRepository = BudgetRepository();
  
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBudgets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await _budgetRepository.getBudgets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBudget({
    required int categoryId,
    required double limitAmount,
    required DateTime startDate,
    required DateTime endDate,
    double alertThreshold = 0.80,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final budget = await _budgetRepository.createBudget(
        categoryId: categoryId,
        limitAmount: limitAmount,
        startDate: startDate,
        endDate: endDate,
        alertThreshold: alertThreshold,
      );
      _budgets.add(budget);
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

  Future<bool> deleteBudget(int id) async {
    try {
      await _budgetRepository.deleteBudget(id);
      _budgets.removeWhere((budget) => budget.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
