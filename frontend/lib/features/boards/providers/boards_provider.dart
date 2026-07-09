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

// State providers for search query and status filters
final boardSearchProvider = StateProvider<String>((ref) => '');
final boardStatusProvider = StateProvider<String>((ref) => 'All');

// Real-time StreamProvider for inspected boards list
final boardsProvider = StreamProvider<List<Board>>((ref) {
  final search = ref.watch(boardSearchProvider);
  final status = ref.watch(boardStatusProvider);

  return Supabase.instance.client
      .from('inspections')
      .stream(primaryKey: ['board_id'])
      .order('created_at', ascending: false)
      .map((list) {
        var mapped = list.map((item) => mapInspectionToBoard(item)).toList();

        if (search.isNotEmpty) {
          mapped = mapped.where((b) => b.boardId.toLowerCase().contains(search.toLowerCase())).toList();
        }
        if (status != 'All') {
          final upperStatus = status == 'Passed' ? 'Passed' : 'Failed';
          mapped = mapped.where((b) => b.status == upperStatus).toList();
        }

        return mapped;
      });
});

// Single board detail provider family using Stream-notifier bridge pattern
final boardDetailProvider = NotifierProvider.family<BoardDetailNotifier, AsyncValue<Board>, String>(BoardDetailNotifier.new);

class BoardDetailNotifier extends FamilyNotifier<AsyncValue<Board>, String> {
  @override
  AsyncValue<Board> build(String arg) {
    // Listen to real-time updates for this single board and push state changes dynamically
    Supabase.instance.client
        .from('inspections')
        .stream(primaryKey: ['board_id'])
        .eq('board_id', arg)
        .listen((list) {
          if (list.isNotEmpty) {
            state = AsyncValue.data(mapInspectionToBoard(list.first));
          } else {
            state = AsyncValue.error('Board details not found', StackTrace.current);
          }
        }, onError: (err, stack) {
          state = AsyncValue.error(err, stack);
        });

    return const AsyncValue.loading();
  }

  Future<bool> assignRework(String assignedTo, String remarks) async {
    try {
      // Append a live activity log to track the operator action in real-time
      await Supabase.instance.client.from('activities').insert({
        'log_message': 'Rework assigned to $assignedTo on Board #$arg: $remarks',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return true;
    }
  }
}
