import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/checkin_repository.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CheckinRepository(dioClient);
});

class CheckinState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  CheckinState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CheckinState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return CheckinState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CheckinNotifier extends StateNotifier<CheckinState> {
  final CheckinRepository _repository;

  CheckinNotifier(this._repository) : super(CheckinState());

  Future<void> submitCheckin({
    required String userId,
    required double sleepQuality,
    required double stressLevel,
    required double energyLevel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.submitDailyCheckin(
        userId: userId,
        sleepQuality: sleepQuality,
        stressLevel: stressLevel,
        energyLevel: energyLevel,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final checkinProvider = StateNotifierProvider<CheckinNotifier, CheckinState>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return CheckinNotifier(repository);
});
