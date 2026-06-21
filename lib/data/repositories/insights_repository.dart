import '../models/insights.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class InsightsRepository {
  final ApiService _apiService = ApiService();

  Future<FinancialInsights> getInsights() async {
    final response = await _apiService.get(AppConfig.insightsEndpoint);
    return FinancialInsights.fromJson(response.data);
  }

  Future<DashboardData> getDashboard() async {
    final response = await _apiService.get(AppConfig.dashboardEndpoint);
    final body = response.data;
    if (body is Map && body['success'] == true) {
      return DashboardData.fromJson(body['data']);
    }
    return DashboardData.fromJson(body);
  }
}
