import 'package:flutter/material.dart';
import '../../data/models/insights.dart';
import '../../data/repositories/insights_repository.dart';

class InsightsProvider with ChangeNotifier {
  final InsightsRepository _repository = InsightsRepository();

  FinancialInsights? _insights;
  bool _isLoading = false;
  String? _error;

  FinancialInsights? get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInsights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _insights = await _repository.getInsights();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
