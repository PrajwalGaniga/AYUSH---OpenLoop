import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/food_knowledge_service.dart';
import '../data/food_scan_repository.dart';
import '../models/detected_food_item.dart';
import '../models/food_analysis_result.dart';

final foodScanRepositoryProvider = Provider<FoodScanRepository>((ref) {
  return FoodScanRepository(ref.read(dioClientProvider));
});

class FoodScanState {
  final bool isLoading;
  final String? error;
  final String? scanId;
  final List<DetectedFoodItem> detectedItems;
  final List<String> confirmedItems;
  final String? mealSource;
  final Map<String, String> auditAnswers;
  final FoodAnalysisResult? analysisResult;
  final File? imageFile;

  const FoodScanState({
    this.isLoading = false,
    this.error,
    this.scanId,
    this.detectedItems = const [],
    this.confirmedItems = const [],
    this.mealSource,
    this.auditAnswers = const {},
    this.analysisResult,
    this.imageFile,
  });

  FoodScanState copyWith({
    bool? isLoading,
    String? error,
    String? scanId,
    List<DetectedFoodItem>? detectedItems,
    List<String>? confirmedItems,
    String? mealSource,
    Map<String, String>? auditAnswers,
    FoodAnalysisResult? analysisResult,
    File? imageFile,
  }) {
    return FoodScanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      scanId: scanId ?? this.scanId,
      detectedItems: detectedItems ?? this.detectedItems,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      mealSource: mealSource ?? this.mealSource,
      auditAnswers: auditAnswers ?? this.auditAnswers,
      analysisResult: analysisResult ?? this.analysisResult,
      imageFile: imageFile ?? this.imageFile,
    );
  }
}

class FoodScanNotifier extends StateNotifier<FoodScanState> {
  final FoodScanRepository _repo;

  FoodScanNotifier(this._repo) : super(const FoodScanState());

  void reset() {
    state = const FoodScanState();
  }

  void resumeState(FoodScanState savedState) {
    state = savedState;
  }

  Future<void> scanImage(File image) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await SecureStorage.getUserId() ?? 'unknown_user';
      final result = await _repo.scanFood(image, userId);
      
      final detectedItems = result['detected_items'] as List<DetectedFoodItem>;
      final confirmed = detectedItems.map((e) => e.classId).toList();

      state = state.copyWith(
        isLoading: false,
        scanId: result['scan_id'],
        detectedItems: detectedItems,
        confirmedItems: confirmed,
        imageFile: image,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void removeConfirmedItem(String classId) {
    final updated = List<String>.from(state.confirmedItems)..remove(classId);
    state = state.copyWith(confirmedItems: updated);
  }

  void addConfirmedItem(String classId) {
    if (!state.confirmedItems.contains(classId)) {
      final updated = List<String>.from(state.confirmedItems)..add(classId);
      state = state.copyWith(confirmedItems: updated);
    }
  }

  void setMealSource(String source) {
    state = state.copyWith(mealSource: source);
  }

  void setAuditAnswer(String classId, String answer) {
    final updated = Map<String, String>.from(state.auditAnswers);
    updated[classId] = answer;
    state = state.copyWith(auditAnswers: updated);
  }

  Future<void> finalizeAnalysis() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await FoodKnowledgeService.calculateResults(
        confirmedItems: state.confirmedItems,
        mealSource: state.mealSource ?? 'home',
        answers: state.auditAnswers,
      );
      state = state.copyWith(isLoading: false, analysisResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logMeal() async {
    if (state.analysisResult == null || state.mealSource == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await SecureStorage.getUserId() ?? 'unknown_user';
      await _repo.logMeal(
        userId: userId,
        mealSource: state.mealSource!,
        result: state.analysisResult!,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final foodScanProvider = StateNotifierProvider<FoodScanNotifier, FoodScanState>((ref) {
  return FoodScanNotifier(ref.read(foodScanRepositoryProvider));
});
