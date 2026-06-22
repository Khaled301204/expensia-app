import '../models/notification.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiService.get(AppConfig.notificationsEndpoint);
    final body = response.data;
    List raw;
    if (body is Map && body['success'] == true) {
      raw = body['data'] as List;
    } else if (body is List) {
      raw = body;
    } else {
      throw Exception('Failed to load notifications');
    }
    return raw.map((j) => AppNotification.fromJson(j)).toList();
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiService.put(
      '${AppConfig.notificationsEndpoint}/$notificationId/read',
    );
  }
}
