class Rework {
  final String id;
  final String boardId;
  final String assignedTo;
  final String status; // "Assigned", "In Progress", "Resolved"
  final String? remarks;
  final DateTime createdAt;

  Rework({
    required this.id,
    required this.boardId,
    required this.assignedTo,
    required this.status,
    this.remarks,
    required this.createdAt,
  });

  factory Rework.fromJson(Map<String, dynamic> json) {
    return Rework(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      assignedTo: json['assigned_to'] as String,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'assigned_to': assignedTo,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
