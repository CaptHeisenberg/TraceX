import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/notification.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<SystemNotification>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<SystemNotification>>> {
  final _apiClient;

  NotificationsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((n) => SystemNotification.fromJson(n as Map<String, dynamic>)).toList();
        state = AsyncValue.data(list);
      } else {
        state = AsyncValue.error('Failed to load notifications: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put('/notifications/$notificationId', data: {
        'status': 'read',
      });
      if (response.statusCode == 200) {
        // Optimistically update or re-fetch
        fetchNotifications();
      }
    } catch (e) {
      // Handle error
    }
  }
}
