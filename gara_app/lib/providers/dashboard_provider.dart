import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/dashboard_stats.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardStats _stats = DashboardStats.initial();
  List<NotificationModel> _notifications = [];
  final bool _loading = false;

  DashboardStats get stats => _stats;
  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount => _stats.unreadNotifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  Future<void> fetchStats() async {
    try {
      final data = await ApiService.get(ApiConfig.dashboardStats);
      _stats = DashboardStats.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchNotifications() async {
    try {
      final data = await ApiService.get(ApiConfig.myNotifications);
      _notifications = (data['results'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead(int id) async {
    try {
      await ApiService.patch(ApiConfig.markNotificationRead(id), body: {});
      await fetchStats();
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.patch(ApiConfig.markAllRead, body: {});
      await fetchStats();
      await fetchNotifications();
    } catch (_) {}
  }
}
