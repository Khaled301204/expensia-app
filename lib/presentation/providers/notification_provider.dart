import 'package:flutter/material.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _repository.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = AppNotification(
          id: _notifications[idx].id,
          userId: _notifications[idx].userId,
          type: _notifications[idx].type,
          title: _notifications[idx].title,
          message: _notifications[idx].message,
          isRead: true,
          createdAt: _notifications[idx].createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    await Future.wait(unread.map((n) => markAsRead(n.id)));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
