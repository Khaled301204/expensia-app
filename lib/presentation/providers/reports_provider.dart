import 'package:flutter/material.dart';
import '../../data/models/monthly_report.dart';
import '../../data/repositories/reports_repository.dart';

class ReportsProvider with ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  MonthlyReport? _monthly;
  List<String> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  MonthlyReport? get monthly => _monthly;
  List<String> get recommendations => _recommendations;
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
      _recommendations = results[1] as List<String>;
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
