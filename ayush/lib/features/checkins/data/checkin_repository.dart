import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class CheckinRepository {
  final Dio _dio;

  CheckinRepository(this._dio);

  Future<void> submitDailyCheckin({
    required String userId,
    required double sleepQuality,
    required double stressLevel,
    required double energyLevel,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.checkins,
        data: {
          'user_id': userId,
          'sleep_quality': sleepQuality,
          'stress_level': stressLevel,
          'energy_level': energyLevel,
        },
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to submit check-in');
      }
      throw Exception('Failed to submit check-in: $e');
    }
  }
}
