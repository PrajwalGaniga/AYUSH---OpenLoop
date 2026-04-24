class FoodItemResult {
  final String classId;
  final String name;
  final String classification;
  final int baseOjasDelta;
  final int auditOjasAdjustment;
  final int totalOjasDelta;
  final String doshaSummary;
  final String vataEffect;
  final String pittaEffect;
  final String kaphaEffect;
  final String virya;
  final String vipaka;
  final List<String> guna;
  final String agniImpact;
  final String amaRisk;
  final String digestibility;
  final String bestMealTime;
  final String questionAsked;
  final String positiveLabel;
  final String negativeLabel;
  final String answerGiven;
  final String reasoning;
  final List<String> idealSeasons;
  final List<String> avoidSeasons;
  final String rituacharyaReason;
  final String prakritiAdviceVata;
  final String prakritiAdvicePitta;
  final String prakritiAdviceKapha;
  final List<String> pairingsIdeal;
  final List<String> pairingsAvoid;
  final List<Map<String, String>> conditionWarnings;
  final List<String> redFlags;

  FoodItemResult({
    required this.classId,
    required this.name,
    required this.classification,
    required this.baseOjasDelta,
    required this.auditOjasAdjustment,
    required this.totalOjasDelta,
    required this.doshaSummary,
    required this.vataEffect,
    required this.pittaEffect,
    required this.kaphaEffect,
    required this.virya,
    required this.vipaka,
    required this.guna,
    required this.agniImpact,
    required this.amaRisk,
    required this.digestibility,
    required this.bestMealTime,
    required this.questionAsked,
    required this.positiveLabel,
    required this.negativeLabel,
    required this.answerGiven,
    required this.reasoning,
    required this.idealSeasons,
    required this.avoidSeasons,
    required this.rituacharyaReason,
    required this.prakritiAdviceVata,
    required this.prakritiAdvicePitta,
    required this.prakritiAdviceKapha,
    required this.pairingsIdeal,
    required this.pairingsAvoid,
    required this.conditionWarnings,
    required this.redFlags,
  });

  factory FoodItemResult.fromJson(Map<String, dynamic> json) {
    return FoodItemResult(
      classId: json['class_id'] ?? '',
      name: json['name'] ?? '',
      classification: json['classification'] ?? '',
      baseOjasDelta: json['base_ojas_delta'] ?? 0,
      auditOjasAdjustment: json['audit_ojas_adjustment'] ?? 0,
      totalOjasDelta: json['total_ojas_delta'] ?? 0,
      doshaSummary: json['dosha_summary'] ?? '',
      vataEffect: json['vata_effect'] ?? '',
      pittaEffect: json['pitta_effect'] ?? '',
      kaphaEffect: json['kapha_effect'] ?? '',
      virya: json['virya'] ?? '',
      vipaka: json['vipaka'] ?? '',
      guna: List<String>.from(json['guna'] ?? []),
      agniImpact: json['agni_impact'] ?? '',
      amaRisk: json['ama_risk'] ?? '',
      digestibility: json['digestibility'] ?? '',
      bestMealTime: json['best_meal_time'] ?? '',
      questionAsked: json['question_asked'] ?? '',
      positiveLabel: json['positive_label'] ?? '',
      negativeLabel: json['negative_label'] ?? '',
      answerGiven: json['answer_given'] ?? '',
      reasoning: json['reasoning'] ?? '',
      idealSeasons: List<String>.from(json['ideal_seasons'] ?? []),
      avoidSeasons: List<String>.from(json['avoid_seasons'] ?? []),
      rituacharyaReason: json['ritucharya_reason'] ?? '',
      prakritiAdviceVata: json['prakriti_advice_vata'] ?? '',
      prakritiAdvicePitta: json['prakriti_advice_pitta'] ?? '',
      prakritiAdviceKapha: json['prakriti_advice_kapha'] ?? '',
      pairingsIdeal: List<String>.from(json['pairings_ideal'] ?? []),
      pairingsAvoid: List<String>.from(json['pairings_avoid'] ?? []),
      conditionWarnings: (json['condition_warnings'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      redFlags: List<String>.from(json['red_flags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'name': name,
      'classification': classification,
      'base_ojas_delta': baseOjasDelta,
      'audit_ojas_adjustment': auditOjasAdjustment,
      'total_ojas_delta': totalOjasDelta,
      'dosha_summary': doshaSummary,
      'vata_effect': vataEffect,
      'pitta_effect': pittaEffect,
      'kapha_effect': kaphaEffect,
      'virya': virya,
      'vipaka': vipaka,
      'guna': guna,
      'agni_impact': agniImpact,
      'ama_risk': amaRisk,
      'digestibility': digestibility,
      'best_meal_time': bestMealTime,
      'question_asked': questionAsked,
      'positive_label': positiveLabel,
      'negative_label': negativeLabel,
      'answer_given': answerGiven,
      'reasoning': reasoning,
      'ideal_seasons': idealSeasons,
      'avoid_seasons': avoidSeasons,
      'ritucharya_reason': rituacharyaReason,
      'prakriti_advice_vata': prakritiAdviceVata,
      'prakriti_advice_pitta': prakritiAdvicePitta,
      'prakriti_advice_kapha': prakritiAdviceKapha,
      'pairings_ideal': pairingsIdeal,
      'pairings_avoid': pairingsAvoid,
      'condition_warnings': conditionWarnings,
      'red_flags': redFlags,
    };
  }
}

class FoodAnalysisResult {
  final int totalOjasDelta;
  final List<FoodItemResult> foodResults;
  final List<ViruddhaWarning> viruddhaWarnings;

  FoodAnalysisResult({
    required this.totalOjasDelta,
    required this.foodResults,
    required this.viruddhaWarnings,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      totalOjasDelta: json['total_ojas_delta'] ?? 0,
      foodResults: (json['food_results'] as List?)
              ?.map((item) => FoodItemResult.fromJson(item))
              .toList() ??
          [],
      viruddhaWarnings: (json['viruddha_warnings'] as List?)
              ?.map((item) => ViruddhaWarning.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_ojas_delta': totalOjasDelta,
      'food_results': foodResults.map((item) => item.toJson()).toList(),
      'viruddha_warnings':
          viruddhaWarnings.map((item) => item.toJson()).toList(),
    };
  }
}

class ViruddhaWarning {
  final List<String> items;
  final String reason;
  final String risk;

  ViruddhaWarning({
    required this.items,
    required this.reason,
    required this.risk,
  });

  factory ViruddhaWarning.fromJson(Map<String, dynamic> json) {
    return ViruddhaWarning(
      items: List<String>.from(json['items'] ?? []),
      reason: json['reason'] ?? '',
      risk: json['risk'] ?? 'Moderate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'reason': reason,
      'risk': risk,
    };
  }
}
