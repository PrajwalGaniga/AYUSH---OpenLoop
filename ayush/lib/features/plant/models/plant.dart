class PlantName {
  final String common;
  final String scientific;
  final String sanskrit;
  final String kannada;
  final String hindi;
  final String tamil;

  PlantName.fromJson(Map<String, dynamic> j)
      : common = j['common'] ?? '',
        scientific = j['scientific'] ?? '',
        sanskrit = j['sanskrit'] ?? '',
        kannada = j['kannada'] ?? '',
        hindi = j['hindi'] ?? '',
        tamil = j['tamil'] ?? '';
}

class MedicinalUse {
  final String use;
  final String method;
  final String frequency;
  final String duration;

  MedicinalUse.fromJson(Map<String, dynamic> j)
      : use = j['use'] ?? '',
        method = j['method'] ?? '',
        frequency = j['frequency'] ?? '',
        duration = j['duration'] ?? '';
}

class DrugInteraction {
  final String drugClass;
  final String interaction;
  final String severity;

  DrugInteraction.fromJson(Map<String, dynamic> j)
      : drugClass = j['drug_class'] ?? '',
        interaction = j['interaction'] ?? '',
        severity = j['severity'] ?? 'low';
}

class Plant {
  final int tfliteClassIndex;
  final PlantName names;
  final Map<String, dynamic> quickFacts;
  final Map<String, String> doshaEffect;
  final Map<String, String> prakritiAdvice;
  final Map<String, dynamic> ayurvedicProperties;
  final List<MedicinalUse> medicinalUses;
  final Map<String, dynamic> intakeMethods;
  final List<String> contraindications;
  final List<DrugInteraction> drugInteractions;
  final Map<String, dynamic> conditionSuitability;
  final Map<String, String> seasonalAdvice;
  final String funFact;
  final String safetyLevel;
  final String? toxicityWarning;
  final String imageAsset;

  Plant.fromJson(Map<String, dynamic> j)
      : tfliteClassIndex = j['tflite_class_index'] ?? 0,
        names = PlantName.fromJson(j['names'] ?? {}),
        quickFacts = j['quick_facts'] ?? {},
        doshaEffect = Map<String, String>.from(j['dosha_effect'] ?? {}),
        prakritiAdvice = Map<String, String>.from(j['prakriti_advice'] ?? {}),
        ayurvedicProperties = j['ayurvedic_properties'] ?? {},
        medicinalUses = (j['medicinal_uses'] as List? ?? [])
            .map((e) => MedicinalUse.fromJson(e))
            .toList(),
        intakeMethods = j['intake_methods'] ?? {},
        contraindications = List<String>.from(j['contraindications'] ?? []),
        drugInteractions = (j['drug_interactions'] as List? ?? [])
            .map((e) => DrugInteraction.fromJson(e))
            .toList(),
        conditionSuitability = j['condition_suitability'] ?? {},
        seasonalAdvice = Map<String, String>.from(j['seasonal_advice'] ?? {}),
        funFact = j['fun_fact'] ?? '',
        safetyLevel = j['safety_level'] ?? 'safe_with_guidance',
        toxicityWarning = j['toxicity_warning'],
        imageAsset = j['image_asset'] ?? '';
}
