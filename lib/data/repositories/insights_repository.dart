import '../models/insights.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class InsightsRepository {
  final ApiService _apiService = ApiService();

  Future<FinancialInsights> getInsights() async {
    final response = await _apiService.get(AppConfig.insightsEndpoint);
    final body = response.data;
    // ignore: avoid_print
    print('[INSIGHTS] body keys: ${body is Map ? body.keys.toList() : body.runtimeType}');
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    if (data is Map) {
      // ignore: avoid_print
      print('[INSIGHTS] data keys: ${data.keys.toList()}');
      // ignore: avoid_print
      print('[INSIGHTS] patterns (${data['patterns'].runtimeType}): ${data['patterns']}');
      // ignore: avoid_print
      print('[INSIGHTS] recommendations (${data['recommendations'].runtimeType}): ${data['recommendations']}');
      // ignore: avoid_print
      print('[INSIGHTS] forecast (${data['forecast'].runtimeType}): ${data['forecast']}');
    }
    final safeData = data is Map<String, dynamic> ? data : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
    return FinancialInsights.fromJson(safeData);
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
