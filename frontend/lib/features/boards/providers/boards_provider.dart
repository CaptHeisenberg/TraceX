import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/board.dart';
import '../../../models/rework.dart';

final boardsProvider = StateNotifierProvider<BoardsNotifier, AsyncValue<List<Board>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BoardsNotifier(apiClient);
});

class BoardsNotifier extends StateNotifier<AsyncValue<List<Board>>> {
  final _apiClient;

  BoardsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchBoards();
  }

  Future<void> fetchBoards({
    String? search,
    String? status,
    String? batch,
    int skip = 0,
    int limit = 20,
  }) async {
    state = const AsyncValue.loading();
    try {
      final Map<String, dynamic> params = {
        'skip': skip,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (status != null && status != 'All') params['status'] = status;
      if (batch != null && batch != 'All') params['batch'] = batch;

      final response = await _apiClient.get('/boards', queryParameters: params);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((b) => Board.fromJson(b as Map<String, dynamic>)).toList();
        state = AsyncValue.data(list);
      } else {
        state = AsyncValue.error('Failed to load boards: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Single board detail provider
final boardDetailProvider = NotifierProvider.family<BoardDetailNotifier, AsyncValue<Board>, String>(BoardDetailNotifier.new);

class BoardDetailNotifier extends FamilyNotifier<AsyncValue<Board>, String> {
  late final _apiClient;

  @override
  AsyncValue<Board> build(String arg) {
    _apiClient = ref.watch(apiClientProvider);
    fetchBoardDetail();
    return const AsyncValue.loading();
  }

  Future<void> fetchBoardDetail() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/boards/$arg');
      if (response.statusCode == 200) {
        state = AsyncValue.data(Board.fromJson(response.data as Map<String, dynamic>));
      } else {
        state = AsyncValue.error('Board not found', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> assignRework(String assignedTo, String remarks) async {
    try {
      final response = await _apiClient.post('/boards/$arg/rework', data: {
        'assigned_to': assignedTo,
        'remarks': remarks,
        'board_id': arg,
      });
      if (response.statusCode == 201) {
        await fetchBoardDetail();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}
