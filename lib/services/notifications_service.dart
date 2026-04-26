import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationsService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getUnread() async {
    try {
      final response = await _apiService.get('/notifications/unread');
      return response is List ? response : [];
    } catch (e) {
      if (kDebugMode) print('Error fetching unread notifications: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAll() async {
    try {
      final response = await _apiService.get('/notifications');
      return response is List ? response : [];
    } catch (e) {
      if (kDebugMode) print('Error fetching all notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/count');
      return response['count'] ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error fetching notification count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiService.patch('/notifications/$id/read', {});
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.patch('/notifications/read-all', {});
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }
}
