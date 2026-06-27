import 'package:flutter/material.dart';
import '../../data/models/monthly_report.dart';
import '../../data/models/insights.dart';
import '../../data/repositories/reports_repository.dart';

class ReportsProvider with ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  MonthlyReport? _monthly;
  RecommendationsInsight? _recommendations;
  bool _isLoading = false;
  String? _error;

  MonthlyReport? get monthly => _monthly;
  RecommendationsInsight? get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getMonthlyReport(),
        _repository.getRecommendations(),
      ]);
      _monthly = results[0] as MonthlyReport;
      _recommendations = results[1] as RecommendationsInsight?;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthly() async {
    try {
      _monthly = await _repository.getMonthlyReport();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadRecommendations() async {
    try {
      _recommendations = await _repository.getRecommendations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
