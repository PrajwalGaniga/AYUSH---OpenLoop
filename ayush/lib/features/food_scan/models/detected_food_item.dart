class DetectedFoodItem {
  final String classId;
  final String name;
  final double confidence;

  const DetectedFoodItem({
    required this.classId,
    required this.name,
    required this.confidence,
  });

  factory DetectedFoodItem.fromJson(Map<String, dynamic> json) {
    return DetectedFoodItem(
      classId: json['class_id'] as String,
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'class_id': classId,
        'name': name,
        'confidence': confidence,
      };

  DetectedFoodItem copyWith({
    String? classId,
    String? name,
    double? confidence,
  }) {
    return DetectedFoodItem(
      classId: classId ?? this.classId,
      name: name ?? this.name,
      confidence: confidence ?? this.confidence,
    );
  }
}
