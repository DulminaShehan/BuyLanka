import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/notification_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch notifications for user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Realtime stream of notifications for user
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _client
        .from(SupabaseConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from(SupabaseConstants.notificationsTable)
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from(SupabaseConstants.notificationsTable)
        .update({'is_read': true})
        .eq('user_id', userId);
  }
}
