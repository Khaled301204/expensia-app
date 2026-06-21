import 'package:flutter/material.dart';
import '../../data/models/dashboard.dart';
import '../../data/repositories/insights_repository.dart';

class DashboardProvider with ChangeNotifier {
  final InsightsRepository _repository = InsightsRepository();

  DashboardData _data = DashboardData.empty();
  bool _isLoading = false;
  String? _error;

  DashboardData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.getDashboard();
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
