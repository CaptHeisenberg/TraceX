import 'defect.dart';
import 'rework.dart';

class Board {
  final String boardId;
  final String batch;
  final DateTime inspectionTime;
  final String status; // "Passed", "Failed"
  final DateTime createdAt;
  final List<Defect> defects;
  final List<Rework> reworks;

  Board({
    required this.boardId,
    required this.batch,
    required this.inspectionTime,
    required this.status,
    required this.createdAt,
    this.defects = const [],
    this.reworks = const [],
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    var defectsList = <Defect>[];
    if (json['defects'] != null) {
      defectsList = (json['defects'] as List)
          .map((d) => Defect.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    
    var reworksList = <Rework>[];
    if (json['reworks'] != null) {
      reworksList = (json['reworks'] as List)
          .map((r) => Rework.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Board(
      boardId: json['board_id'] as String,
      batch: json['batch'] as String,
      inspectionTime: DateTime.parse(json['inspection_time'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      defects: defectsList,
      reworks: reworksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'board_id': boardId,
      'batch': batch,
      'inspection_time': inspectionTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'defects': defects.map((d) => d.toJson()).toList(),
      'reworks': reworks.map((r) => r.toJson()).toList(),
    };
  }
}
