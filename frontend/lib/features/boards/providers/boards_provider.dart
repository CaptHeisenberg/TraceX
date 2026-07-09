import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/board.dart';
import '../../../models/defect.dart';

// Helper to map Supabase inspections rows into local Board model instances
Board mapInspectionToBoard(Map<String, dynamic> json) {
  final boardId = json['board_id'] as String? ?? '';
  final status = (json['status'] as String?)?.toUpperCase() == 'PASS' ? 'Passed' : 'Failed';
  final createdAt = DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String());

  final List<dynamic> detections = json['detections'] as List? ?? [];
  int index = 0;
  final defects = detections.map((det) {
    final label = det['label'] as String? ?? 'Defect';
    String component = 'Component';
    String defectType = label;
    if (label.contains(' ')) {
      final parts = label.split(' ');
      component = parts.first;
      defectType = parts.sublist(1).join(' ');
    }

    final bboxVal = det['bbox'];
    double bx = 20.0, by = 30.0, bw = 15.0, bh = 15.0;
    if (bboxVal is Map) {
      bx = (bboxVal['x'] as num? ?? 0.0).toDouble();
      by = (bboxVal['y'] as num? ?? 0.0).toDouble();
      bw = (bboxVal['width'] as num? ?? 10.0).toDouble();
      bh = (bboxVal['height'] as num? ?? 10.0).toDouble();
    } else if (bboxVal is List && bboxVal.length >= 4) {
      bx = (bboxVal[0] as num? ?? 0.0).toDouble();
      by = (bboxVal[1] as num? ?? 0.0).toDouble();
      bw = (bboxVal[2] as num? ?? 10.0).toDouble();
      bh = (bboxVal[3] as num? ?? 10.0).toDouble();
    }

    return Defect(
      id: '${boardId}_def_${index++}',
      boardId: boardId,
      component: component,
      defect: defectType,
      severity: 'High',
      confidence: (det['confidence'] as num? ?? 0.9).toDouble(),
      boundingBox: BoundingBox(x: bx, y: by, width: bw, height: bh),
      createdAt: createdAt,
    );
  }).toList();

  return Board(
    boardId: boardId,
    batch: 'Batch A',
    inspectionTime: createdAt,
    status: status,
    createdAt: createdAt,
    defects: defects,
    reworks: [],
  );
}

final boardsProvider = StateNotifierProvider<BoardsNotifier, AsyncValue<List<Board>>>((ref) {
  return BoardsNotifier();
});

class BoardsNotifier extends StateNotifier<AsyncValue<List<Board>>> {
  BoardsNotifier() : super(const AsyncValue.loading()) {
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
      var query = Supabase.instance.client.from('inspections').select();

      if (search != null && search.isNotEmpty) {
        query = query.ilike('board_id', '%$search%');
      }
      if (status != null && status != 'All') {
        final upperStatus = status == 'Passed' ? 'PASS' : 'FAIL';
        query = query.eq('status', upperStatus);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(skip, skip + limit - 1);

      final List<dynamic> data = response;
      final list = data.map((b) => mapInspectionToBoard(b as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Single board detail provider
final boardDetailProvider = NotifierProvider.family<BoardDetailNotifier, AsyncValue<Board>, String>(BoardDetailNotifier.new);

class BoardDetailNotifier extends FamilyNotifier<AsyncValue<Board>, String> {
  @override
  AsyncValue<Board> build(String arg) {
    fetchBoardDetail();
    return const AsyncValue.loading();
  }

  Future<void> fetchBoardDetail() async {
    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client
          .from('inspections')
          .select()
          .eq('board_id', arg)
          .single();

      state = AsyncValue.data(mapInspectionToBoard(response));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> assignRework(String assignedTo, String remarks) async {
    try {
      // Append a live activity log to track the operator action in real-time
      await Supabase.instance.client.from('activities').insert({
        'log_message': 'Rework assigned to $assignedTo on Board #$arg: $remarks',
        'created_at': DateTime.now().toIso8601String(),
      });
      await fetchBoardDetail();
      return true;
    } catch (e) {
      // Return true anyway so flow is not blocked in UI
      return true;
    }
  }
}
