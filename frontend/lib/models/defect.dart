class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}

class Defect {
  final String id;
  final String boardId;
  final String component;
  final String defect;
  final String severity; // "Critical", "High", "Medium", "Low"
  final double confidence;
  final BoundingBox boundingBox;
  final String? imagePath;
  final DateTime createdAt;

  Defect({
    required this.id,
    required this.boardId,
    required this.component,
    required this.defect,
    required this.severity,
    required this.confidence,
    required this.boundingBox,
    this.imagePath,
    required this.createdAt,
  });

  factory Defect.fromJson(Map<String, dynamic> json) {
    return Defect(
      id: json['id'] as String,
      boardId: json['board_id'] as String,
      component: json['component'] as String,
      defect: json['defect'] as String,
      severity: json['severity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: BoundingBox.fromJson(json['bounding_box'] as Map<String, dynamic>),
      imagePath: json['image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'component': component,
      'defect': defect,
      'severity': severity,
      'confidence': confidence,
      'bounding_box': boundingBox.toJson(),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
