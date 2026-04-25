import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/packaged_food_repository.dart';
import '../models/packaged_food_result.dart';

class PackagedFoodState {
  final PackagedFoodResult? result;
  final bool isLoading;
  final String? error;
  final File? selectedImage;

  const PackagedFoodState({
    this.result,
    this.isLoading = false,
    this.error,
    this.selectedImage,
  });

  PackagedFoodState copyWith({
    PackagedFoodResult? result,
    bool? isLoading,
    String? error,
    File? selectedImage,
    bool clearError = false,
    bool clearResult = false,
  }) =>
      PackagedFoodState(
        result: clearResult ? null : result ?? this.result,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        selectedImage: selectedImage ?? this.selectedImage,
      );
}

class PackagedFoodNotifier extends StateNotifier<PackagedFoodState> {
  final PackagedFoodRepository _repo;

  PackagedFoodNotifier(this._repo) : super(const PackagedFoodState());

  void setImage(File image) {
    state = state.copyWith(selectedImage: image, clearResult: true, clearError: true);
  }

  void reset() {
    state = const PackagedFoodState();
  }

  Future<bool> analyze({
    required String prakriti,
    required String conditions,
    required int ojasScore,
    required String medications,
  }) async {
    if (state.selectedImage == null) {
      state = state.copyWith(error: 'No image selected');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.analyze(
        imageFile: state.selectedImage!,
        prakriti: prakriti,
        conditions: conditions,
        ojasScore: ojasScore,
        medications: medications,
      );
      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final _repoProvider = Provider((_) => PackagedFoodRepository());

final packagedFoodProvider =
    StateNotifierProvider<PackagedFoodNotifier, PackagedFoodState>(
  (ref) => PackagedFoodNotifier(ref.read(_repoProvider)),
);
