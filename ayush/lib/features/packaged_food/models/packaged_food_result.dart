class PackagedFoodIngredient {
  final String name;
  final bool isConcerning;
  final String reason;

  const PackagedFoodIngredient({
    required this.name,
    required this.isConcerning,
    required this.reason,
  });

  factory PackagedFoodIngredient.fromJson(Map<String, dynamic> j) =>
      PackagedFoodIngredient(
        name: j['name'] ?? '',
        isConcerning: j['is_concerning'] ?? false,
        reason: j['reason'] ?? '',
      );
}

class PackagedFoodResult {
  final String productName;
  final String brand;
  final int overallScore;
  final String recommendation; // 'buy' | 'skip' | 'moderate'
  final String recommendationReason;
  final List<PackagedFoodIngredient> ingredients;
  final List<String> positives;
  final List<String> negatives;
  final String ayurvedicNote;
  final List<String> allergenFlags;
  final String servingTip;
  final String rawOcrText;

  const PackagedFoodResult({
    required this.productName,
    required this.brand,
    required this.overallScore,
    required this.recommendation,
    required this.recommendationReason,
    required this.ingredients,
    required this.positives,
    required this.negatives,
    required this.ayurvedicNote,
    required this.allergenFlags,
    required this.servingTip,
    required this.rawOcrText,
  });

  factory PackagedFoodResult.fromJson(Map<String, dynamic> j) =>
      PackagedFoodResult(
        productName: j['product_name'] ?? 'Unknown Product',
        brand: j['brand'] ?? 'Unknown',
        overallScore: (j['overall_score'] as num?)?.toInt() ?? 50,
        recommendation: j['recommendation'] ?? 'moderate',
        recommendationReason: j['recommendation_reason'] ?? '',
        ingredients: (j['ingredients'] as List? ?? [])
            .map((e) => PackagedFoodIngredient.fromJson(e))
            .toList(),
        positives: List<String>.from(j['positives'] ?? []),
        negatives: List<String>.from(j['negatives'] ?? []),
        ayurvedicNote: j['ayurvedic_note'] ?? '',
        allergenFlags: List<String>.from(j['allergen_flags'] ?? []),
        servingTip: j['serving_tip'] ?? '',
        rawOcrText: j['raw_ocr_text'] ?? '',
      );
}
