import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/food_analysis_result.dart';

class FoodKnowledgeService {
  static Map<String, dynamic>? _db;

  static Future<void> _ensureLoaded() async {
    if (_db == null) {
      final jsonStr = await rootBundle.loadString('assets/data/yolo_classs_and_food_qna.json');
      _db = jsonDecode(jsonStr);
    }
  }

  static Future<List<Map<String, String>>> getFoodNames() async {
    await _ensureLoaded();
    final foodWisdom = _db!['food_wisdom'] as Map<String, dynamic>;
    final List<Map<String, String>> names = [];

    foodWisdom.forEach((classId, data) {
      names.add({
        'class_id': classId,
        'name': data['name'] as String,
      });
    });

    return names;
  }

  static Future<Map<String, dynamic>> getQuestion(String classId, String mealSource) async {
    await _ensureLoaded();
    final entry = _db!['food_wisdom'][classId];
    if (entry == null) return {};

    final deepAudit = entry['deep_audit'];
    if (deepAudit == null) return {};

    var auditBlock = deepAudit[mealSource];
    if (auditBlock == null) {
      final fallback = mealSource == 'hotel' ? 'home' : 'hotel';
      auditBlock = deepAudit[fallback];
    }
    return auditBlock ?? {};
  }

  static FoodItemResult _buildResult(String classId, String mealSource, String answer, Map<String, dynamic> foodData) {
    final auditBlock = foodData['deep_audit'][mealSource] ?? foodData['deep_audit']['home'] ?? {};
    final baseOjas = (foodData['nutritional_context']['base_ojas_delta'] as num?)?.toInt() ?? 0;
    
    int auditAdjustment = 0;
    String answerGiven = 'Not answered';
    String reasoning = '';
    
    if (answer == 'positive') {
      auditAdjustment = (auditBlock['ojas_bonus'] as num?)?.toInt() ?? 0;
      answerGiven = auditBlock['positive_label'] as String? ?? 'Yes';
      reasoning = auditBlock['positive_reasoning'] as String? ?? '';
    } else if (answer == 'negative') {
      auditAdjustment = (auditBlock['ojas_penalty'] as num?)?.toInt() ?? 0;
      answerGiven = auditBlock['negative_label'] as String? ?? 'No';
      reasoning = auditBlock['negative_reasoning'] as String? ?? '';
    }
    
    final ayurvedicProfile = foodData['ayurvedic_profile'] ?? {};
    final doshaEffect = ayurvedicProfile['dosha_effect'] ?? {};
    final nutritionalContext = foodData['nutritional_context'] ?? {};
    final ritucharya = foodData['ritucharya'] ?? {};
    final prakritiAdvice = foodData['prakriti_advice'] ?? {};
    final pairings = foodData['pairings'] ?? {};

    return FoodItemResult(
      classId: classId,
      name: foodData['name'] as String? ?? 'Unknown',
      classification: foodData['classification'] as String? ?? '',
      baseOjasDelta: baseOjas,
      auditOjasAdjustment: auditAdjustment,
      totalOjasDelta: baseOjas + auditAdjustment,
      doshaSummary: doshaEffect['summary'] as String? ?? '',
      vataEffect: doshaEffect['vata'] as String? ?? '',
      pittaEffect: doshaEffect['pitta'] as String? ?? '',
      kaphaEffect: doshaEffect['kapha'] as String? ?? '',
      virya: ayurvedicProfile['virya'] as String? ?? '',
      vipaka: ayurvedicProfile['vipaka'] as String? ?? '',
      guna: List<String>.from(ayurvedicProfile['guna'] ?? []),
      agniImpact: ayurvedicProfile['agni_impact'] as String? ?? '',
      amaRisk: ayurvedicProfile['ama_risk'] as String? ?? '',
      digestibility: nutritionalContext['digestibility'] as String? ?? '',
      bestMealTime: nutritionalContext['best_meal_time'] as String? ?? '',
      questionAsked: auditBlock['question'] as String? ?? '',
      positiveLabel: auditBlock['positive_label'] as String? ?? 'Yes',
      negativeLabel: auditBlock['negative_label'] as String? ?? 'No',
      answerGiven: answerGiven,
      reasoning: reasoning,
      idealSeasons: List<String>.from(ritucharya['ideal_seasons'] ?? []),
      avoidSeasons: List<String>.from(ritucharya['avoid_seasons'] ?? []),
      rituacharyaReason: ritucharya['reason'] as String? ?? '',
      prakritiAdviceVata: prakritiAdvice['vata'] as String? ?? '',
      prakritiAdvicePitta: prakritiAdvice['pitta'] as String? ?? '',
      prakritiAdviceKapha: prakritiAdvice['kapha'] as String? ?? '',
      pairingsIdeal: List<String>.from(pairings['ideal_with'] ?? []),
      pairingsAvoid: List<String>.from(pairings['avoid_with'] ?? []),
      conditionWarnings: (foodData['condition_warnings'] as List?)?.map((e) => Map<String, String>.from(e)).toList() ?? [],
      redFlags: List<String>.from(auditBlock['red_flags'] ?? []),
    );
  }

  static Future<FoodAnalysisResult> calculateResults({
    required List<String> confirmedItems,
    required String mealSource,
    required Map<String, String> answers,
  }) async {
    await _ensureLoaded();
    final foodWisdom = _db!['food_wisdom'] as Map<String, dynamic>;
    final viruddhaLogic = _db!['viruddha_ahara_logic'] as List<dynamic>? ?? [];

    int totalOjasDelta = 0;
    final List<FoodItemResult> foodResults = [];

    // Process each item
    for (final classId in confirmedItems) {
      final entry = foodWisdom[classId];
      if (entry == null) continue;

      final answerGiven = answers[classId] ?? 'positive';
      final result = _buildResult(classId, mealSource, answerGiven, entry as Map<String, dynamic>);

      totalOjasDelta += result.totalOjasDelta;
      foodResults.add(result);
    }

    // Process Viruddha Ahara
    final confirmedSet = confirmedItems.toSet();
    final List<ViruddhaWarning> warnings = [];

    for (final rule in viruddhaLogic) {
      final items = (rule['items'] as List<dynamic>).map((e) => e.toString()).toList();
      if (items.every((item) => confirmedSet.contains(item))) {
        final itemNames = items.map((id) {
          final entry = foodWisdom[id];
          return entry != null ? (entry['name'] as String) : id;
        }).toList();

        warnings.add(ViruddhaWarning(
          items: itemNames,
          reason: rule['reason'] as String? ?? '',
          risk: rule['risk'] as String? ?? 'Moderate',
        ));
      }
    }

    return FoodAnalysisResult(
      totalOjasDelta: totalOjasDelta,
      foodResults: foodResults,
      viruddhaWarnings: warnings,
    );
  }
}
