import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.read(dioClientProvider));
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repo;

  OnboardingNotifier(this._repo) : super(const OnboardingState());

  void updateStep1({
    String? fullName,
    DateTime? dob,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? bloodGroup,
    String? language,
    String? region,
  }) {
    state = state.copyWith(
      fullName: fullName,
      dob: dob,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      bloodGroup: bloodGroup,
      language: language,
      region: region,
    );
  }

  void updatePainPoints(List<PainPoint> points) {
    state = state.copyWith(painPoints: points);
  }

  void addPrakritiAnswer(PrakritiAnswer answer) {
    final existing = List<PrakritiAnswer>.from(state.prakritiAnswers);
    final idx = existing.indexWhere((a) => a.questionId == answer.questionId);
    if (idx >= 0) {
      existing[idx] = answer;
    } else {
      existing.add(answer);
    }
    state = state.copyWith(prakritiAnswers: existing);
  }

  void updateLifestyle({
    String? occupationType,
    String? stressLevel,
    String? exerciseFrequency,
    String? dietType,
    double? waterIntakeLiters,
    double? sleepHours,
    String? smokingStatus,
    String? alcoholStatus,
    bool? yogaPractice,
    bool? meditationPractice,
  }) {
    state = state.copyWith(
      occupationType: occupationType,
      stressLevel: stressLevel,
      exerciseFrequency: exerciseFrequency,
      dietType: dietType,
      waterIntakeLiters: waterIntakeLiters,
      sleepHours: sleepHours,
      smokingStatus: smokingStatus,
      alcoholStatus: alcoholStatus,
      yogaPractice: yogaPractice,
      meditationPractice: meditationPractice,
    );
  }

  void updateHealthConditions({
    List<String>? diagnosedConditions,
    List<String>? chronicConditions,
    List<String>? allergies,
    List<MedicationItem>? currentMedications,
    List<String>? surgeries,
    List<String>? familyHistory,
  }) {
    state = state.copyWith(
      diagnosedConditions: diagnosedConditions,
      chronicConditions: chronicConditions,
      allergies: allergies,
      currentMedications: currentMedications,
      surgeries: surgeries,
      familyHistory: familyHistory,
    );
  }

  Future<void> submitStep1(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.saveStep1(userId: userId, state: state);
      await SecureStorage.saveOnboardingStep(1);
      state = state.copyWith(isLoading: false, step: 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitStep2(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.saveStep2BodyScan(userId: userId, painPoints: state.painPoints);
      await SecureStorage.saveOnboardingStep(2);
      state = state.copyWith(isLoading: false, step: 2);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<PrakritiResult> submitStep3(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.savePrakritiAnswers(userId: userId, answers: state.prakritiAnswers);
      final result = await _repo.calculatePrakriti(userId: userId);
      await SecureStorage.saveOnboardingStep(3);
      state = state.copyWith(isLoading: false, step: 3, prakritiResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitStep4(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.saveStep4(userId: userId, state: state);
      await SecureStorage.saveOnboardingStep(4);
      state = state.copyWith(isLoading: false, step: 4);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitStep5(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.saveStep5(userId: userId, state: state);
      await SecureStorage.saveOnboardingStep(5);
      state = state.copyWith(isLoading: false, step: 5);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<OjasResult> calculateAndFinalizeOjas(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.completeOnboarding(userId: userId);
      final ojas = await _repo.calculateOjas(userId: userId);
      await SecureStorage.setOnboarded(true);
      state = state.copyWith(isLoading: false, ojasResult: ojas);
      return ojas;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.read(onboardingRepositoryProvider));
});
