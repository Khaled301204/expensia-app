import '../models/monthly_report.dart';
import '../models/insights.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class ReportsRepository {
  final ApiService _apiService = ApiService();

  Future<MonthlyReport> getMonthlyReport() async {
    final response = await _apiService.get(AppConfig.monthlyReportEndpoint);
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    if (data is Map<String, dynamic>) return MonthlyReport.fromJson(data);
    return MonthlyReport.empty();
  }

  Future<RecommendationsInsight?> getRecommendations() async {
    final response = await _apiService.get(AppConfig.recommendationsEndpoint);
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    if (data is Map) {
      return RecommendationsInsight.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<Map<String, dynamic>?> getForecast() async {
    final response = await _apiService.get(AppConfig.forecastEndpointSpring);
    final body = response.data;
    if (body is Map && body['success'] == true) return body['data'] as Map<String, dynamic>?;
    return null;
  }

  Future<Map<String, dynamic>?> getBenchmarks() async {
    final response = await _apiService.get(AppConfig.benchmarksEndpoint);
    final body = response.data;
    if (body is Map && body['success'] == true) return body['data'] as Map<String, dynamic>?;
    return null;
  }
}
