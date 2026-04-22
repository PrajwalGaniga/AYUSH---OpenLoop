import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import 'onboarding_models.dart';

class OnboardingRepository {
  final Dio _dio;
  OnboardingRepository(this._dio);

  Future<void> saveStep1({required String userId, required OnboardingState state}) async {
    await _dio.post(ApiEndpoints.step1BasicProfile, data: {
      'userId': userId,
      'fullName': state.fullName,
      'age': state.dob != null ? _computeAge(state.dob!) : null,
      'dob': state.dob?.toIso8601String(),
      'gender': state.gender,
      'heightCm': state.heightCm,
      'weightKg': state.weightKg,
      'bloodGroup': state.bloodGroup,
      'language': state.language,
      'region': state.region,
    });
  }

  Future<void> saveStep2BodyScan({required String userId, required List<PainPoint> painPoints}) async {
    await _dio.post(ApiEndpoints.step2BodyScan, data: {
      'userId': userId,
      'painPoints': painPoints.map((p) => p.toJson()).toList(),
    });
  }

  Future<void> savePrakritiAnswers({required String userId, required List<PrakritiAnswer> answers}) async {
    await _dio.post(ApiEndpoints.step3PrakritiAnswers, data: {
      'userId': userId,
      'answers': answers.map((a) => a.toJson()).toList(),
    });
  }

  Future<PrakritiResult> calculatePrakriti({required String userId}) async {
    final response = await _dio.post(ApiEndpoints.step3CalculatePrakriti, data: {'userId': userId});
    return PrakritiResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> saveStep4({required String userId, required OnboardingState state}) async {
    await _dio.post(ApiEndpoints.step4Lifestyle, data: {
      'userId': userId,
      'occupationType': state.occupationType,
      'stressLevel': state.stressLevel,
      'exerciseFrequency': state.exerciseFrequency,
      'dietType': state.dietType,
      'waterIntakeLiters': state.waterIntakeLiters,
      'sleepHours': state.sleepHours,
      'smokingStatus': state.smokingStatus,
      'alcoholStatus': state.alcoholStatus,
      'yogaPractice': state.yogaPractice,
      'meditationPractice': state.meditationPractice,
    });
  }

  Future<void> saveStep5({required String userId, required OnboardingState state}) async {
    await _dio.post(ApiEndpoints.step5HealthConditions, data: {
      'userId': userId,
      'diagnosedConditions': state.diagnosedConditions,
      'chronicConditions': state.chronicConditions,
      'allergies': state.allergies,
      'currentMedications': state.currentMedications.map((m) => m.toJson()).toList(),
      'surgeries': state.surgeries,
      'familyHistory': state.familyHistory,
      'mentalHealthConditions': [],
    });
  }

  Future<OjasResult> calculateOjas({required String userId}) async {
    final response = await _dio.post(ApiEndpoints.calculateOjas, data: {'userId': userId});
    return OjasResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> completeOnboarding({required String userId}) async {
    await _dio.post(ApiEndpoints.completeOnboarding, data: {'userId': userId});
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }
}
