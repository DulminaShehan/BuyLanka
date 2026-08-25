import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/models/notification_model.dart';
import 'package:buylanka/repositories/notification_repository.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;
  final String? _userId;

  NotificationsController(this._repository, this._userId) : super(const NotificationsState(isLoading: true)) {
    if (_userId != null) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNotifications(_userId);
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    await _repository.markAllAsRead(_userId);
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationsControllerProvider = StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(authControllerProvider).profile?.id;
  return NotificationsController(repo, userId);
});
