import '../models/monthly_report.dart';
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

  Future<List<String>> getRecommendations() async {
    final response = await _apiService.get(AppConfig.recommendationsEndpoint);
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;

    // Handle both List<String> and { recommendations: [...] }
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is Map) {
      if (data['recommendations'] is List) {
        return (data['recommendations'] as List).map((e) => e.toString()).toList();
      }
      if (data['items'] is List) {
        return (data['items'] as List).map<String>((e) =>
          e is Map ? (e['message'] ?? e['text'] ?? e).toString() : e.toString()
        ).toList();
      }
    }
    return [];
  }
}
