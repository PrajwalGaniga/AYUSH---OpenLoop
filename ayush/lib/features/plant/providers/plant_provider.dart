import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import '../models/plant_prediction.dart';
import '../services/plant_classifier_service.dart';
import '../data/plant_knowledge_service.dart';
import '../data/plant_repository.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

class PlantState {
  final bool isLoading;
  final String? error;
  final File? imageFile;
  final List<PlantPrediction> predictions;
  final Plant? selectedPlant;
  final Map<String, dynamic>? askResponse;
  final bool isAsking;

  const PlantState({
    this.isLoading = false,
    this.error,
    this.imageFile,
    this.predictions = const [],
    this.selectedPlant,
    this.askResponse,
    this.isAsking = false,
  });

  PlantState copyWith({
    bool? isLoading,
    String? error,
    File? imageFile,
    List<PlantPrediction>? predictions,
    Plant? selectedPlant,
    Map<String, dynamic>? askResponse,
    bool? isAsking,
  }) {
    return PlantState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      imageFile: imageFile ?? this.imageFile,
      predictions: predictions ?? this.predictions,
      selectedPlant: selectedPlant ?? this.selectedPlant,
      askResponse: askResponse ?? this.askResponse,
      isAsking: isAsking ?? this.isAsking,
    );
  }
}

class PlantNotifier extends StateNotifier<PlantState> {
  final PlantRepository _repo;

  PlantNotifier(this._repo) : super(const PlantState());

  void reset() {
    state = const PlantState();
  }

  Future<void> classifyImage(File image) async {
    state = state.copyWith(isLoading: true, error: null, imageFile: image);
    try {
      final predictions = await PlantClassifierService.instance.classify(image);
      state = state.copyWith(isLoading: false, predictions: predictions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectPlant(String plantKey) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plant = await PlantKnowledgeService.instance.getPlant(plantKey);
      state = state.copyWith(isLoading: false, selectedPlant: plant);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> askQuestion({
    required String question,
    String? prakriti,
    List<String> conditions = const [],
  }) async {
    if (state.selectedPlant == null) return;
    
    state = state.copyWith(isAsking: true, error: null);
    try {
      final response = await _repo.askQuestion(
        plantName: state.selectedPlant!.names.common,
        plantScientific: state.selectedPlant!.names.scientific,
        question: question,
        prakriti: prakriti,
        conditions: conditions,
      );
      state = state.copyWith(isAsking: false, askResponse: response);
    } catch (e) {
      state = state.copyWith(isAsking: false, error: e.toString());
    }
  }
}

final plantProvider = StateNotifierProvider<PlantNotifier, PlantState>((ref) {
  return PlantNotifier(ref.read(plantRepositoryProvider));
});
