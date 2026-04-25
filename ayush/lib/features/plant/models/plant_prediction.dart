class PlantPrediction {
  final String plantKey; // matches JSON key e.g. "aloevera"
  final String plantName; // display name e.g. "Aloe Vera"
  final double confidence; // 0.0 to 1.0

  const PlantPrediction({
    required this.plantKey,
    required this.plantName,
    required this.confidence,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  String get confidenceLevel {
    if (confidence >= 0.70) return 'high';
    if (confidence >= 0.50) return 'medium';
    return 'low';
  }
}
