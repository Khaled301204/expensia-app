import 'package:flutter/material.dart';
import '../../data/models/income.dart';
import '../../data/repositories/income_repository.dart';

class IncomeProvider with ChangeNotifier {
  final IncomeRepository _repository = IncomeRepository();

  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalIncome => _incomes.fold(0.0, (sum, i) => sum + i.amount);

  Future<void> loadIncomes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _incomes = await _repository.getIncomes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createIncome({
    required double amount,
    required DateTime date,
    required String source,
    String? frequency,
    bool isRecurring = false,
    bool recurringActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final income = await _repository.createIncome(
        amount: amount,
        date: date,
        source: source,
        frequency: frequency,
        isRecurring: isRecurring,
        recurringActive: recurringActive,
      );
      _incomes.insert(0, income);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateIncome({
    required int id,
    double? amount,
    DateTime? date,
    String? source,
    String? frequency,
    bool? isRecurring,
    bool? recurringActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repository.updateIncome(
        id: id, amount: amount, date: date,
        source: source, frequency: frequency,
        isRecurring: isRecurring, recurringActive: recurringActive,
      );
      final idx = _incomes.indexWhere((i) => i.id == id);
      if (idx != -1) _incomes[idx] = updated;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteIncome(int id) async {
    try {
      await _repository.deleteIncome(id);
      _incomes.removeWhere((i) => i.id == id);
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
