import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardNotifier(apiClient);
});

class DashboardNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final _apiClient;

  DashboardNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/analytics');
      if (response.statusCode == 200) {
        state = AsyncValue.data(response.data as Map<String, dynamic>);
      } else {
        state = AsyncValue.error('Failed to load dashboard data: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
