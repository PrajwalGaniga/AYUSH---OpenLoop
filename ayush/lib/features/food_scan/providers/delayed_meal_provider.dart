import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'food_scan_provider.dart';

class DelayedMealState {
  final FoodScanState? pendingScan;
  final bool isTimerComplete;

  const DelayedMealState({
    this.pendingScan,
    this.isTimerComplete = false,
  });

  DelayedMealState copyWith({
    FoodScanState? pendingScan,
    bool? isTimerComplete,
  }) {
    return DelayedMealState(
      pendingScan: pendingScan ?? this.pendingScan,
      isTimerComplete: isTimerComplete ?? this.isTimerComplete,
    );
  }
}

class DelayedMealNotifier extends StateNotifier<DelayedMealState> {
  Timer? _timer;

  DelayedMealNotifier() : super(const DelayedMealState());

  void startDelayedTimer(FoodScanState scanState) {
    state = DelayedMealState(
      pendingScan: scanState,
      isTimerComplete: false,
    );

    _timer?.cancel();
    // Start 25 second demo timer
    _timer = Timer(const Duration(seconds: 25), () {
      state = state.copyWith(isTimerComplete: true);
    });
  }

  void clearPending() {
    _timer?.cancel();
    state = const DelayedMealState();
  }
  
  void setTimerComplete(bool complete) {
    state = state.copyWith(isTimerComplete: complete);
  }
}

final delayedMealProvider = StateNotifierProvider<DelayedMealNotifier, DelayedMealState>((ref) {
  return DelayedMealNotifier();
});
