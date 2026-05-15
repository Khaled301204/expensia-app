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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final goal = await _goalRepository.createGoal(
        name: name,
        targetAmount: targetAmount,
        deadline: deadline,
      );
      _goals.add(goal);
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

  Future<bool> addSavings(int goalId, double amount) async {
    try {
      final updatedGoal = await _goalRepository.addSavings(goalId, amount);
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
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
