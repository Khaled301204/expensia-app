import 'package:flutter/material.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/goal_repository.dart';

class GoalProvider with ChangeNotifier {
  final GoalRepository _goalRepository = GoalRepository();
  
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await _goalRepository.getGoals();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
    double? currentAmount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final goal = await _goalRepository.createGoal(
        name: name,
        targetAmount: targetAmount,
        deadline: deadline,
        currentAmount: currentAmount,
      );
      _goals.add(goal);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGoal({
    required int id,
    String? name,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _goalRepository.updateGoal(
        id: id, name: name, targetAmount: targetAmount, deadline: deadline,
      );
      final idx = _goals.indexWhere((g) => g.id == id);
      if (idx != -1) _goals[idx] = updated;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Goal?> withdrawSavings(int goalId, double amount) async {
    _error = null;
    try {
      final updatedGoal = await _goalRepository.withdrawSavings(goalId, amount);
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
      }
      return updatedGoal;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Returns the updated [Goal] on success (check `.status == 'COMPLETED'`),
  /// or null on failure (check [error]).
  Future<Goal?> addSavings(int goalId, double amount) async {
    _error = null;
    try {
      final updatedGoal = await _goalRepository.addSavings(goalId, amount);
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
      }
      return updatedGoal;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await _goalRepository.deleteGoal(id);
      _goals.removeWhere((goal) => goal.id == id);
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
