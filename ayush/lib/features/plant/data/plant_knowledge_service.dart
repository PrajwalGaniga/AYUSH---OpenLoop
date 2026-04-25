import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plant.dart';

class PlantKnowledgeService {
  static PlantKnowledgeService? _instance;
  Map<String, dynamic> _data = {};
  Map<String, Plant> _plantCache = {};
  bool _loaded = false;

  static PlantKnowledgeService get instance {
    _instance ??= PlantKnowledgeService._();
    return _instance!;
  }
  PlantKnowledgeService._();

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/plant_knowledge.json');
    _data = jsonDecode(raw);
    _plantCache = {}; // clear cache on fresh load
    _loaded = true;
  }

  void reset() {
    _loaded = false;
    _plantCache = {};
    _data = {};
  }

  Future<Plant?> getPlant(String plantKey) async {
    await load();
    if (_plantCache.containsKey(plantKey)) return _plantCache[plantKey];
    final plantData = _data['plants']?[plantKey];
    if (plantData == null) return null;
    final plant = Plant.fromJson(Map<String, dynamic>.from(plantData));
    _plantCache[plantKey] = plant;
    return plant;
  }

  Future<List<String>> getAllPlantKeys() async {
    await load();
    return List<String>.from(_data['plants']?.keys ?? []);
  }

  String get disclaimer => _data['metadata']?['disclaimer'] ?? '';

  Map<String, dynamic> getSafetyConfig(String safetyLevel) {
    return Map<String, dynamic>.from(
      _data['safety_level_config']?[safetyLevel] ?? {}
    );
  }
}
