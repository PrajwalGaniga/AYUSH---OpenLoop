import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/env/env.dart';

class PlantRepository {
  final Dio _dio;

  PlantRepository() : _dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> askQuestion({
    required String plantName,
    required String plantScientific,
    required String question,
    String? prakriti,
    List<String> conditions = const [],
    List<String> medications = const [],
  }) async {
    try {
      print('[PlantRepository] Sending /plant/ask request...');
      print('[PlantRepository] Base URL: ${Env.apiBaseUrl}');
      print('[PlantRepository] Plant: $plantName | Q: $question');

      final response = await _dio.post(
        '/plant/ask',
        data: jsonEncode({
          'plant_name': plantName,
          'plant_scientific': plantScientific,
          'user_question': question,
          'prakriti': prakriti,
          'conditions': conditions,
          'medications': medications,
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('[PlantRepository] Response status: ${response.statusCode}');
      print('[PlantRepository] Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data
            : Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to get answer: ${response.statusCode}');
    } on DioException catch (e) {
      print('[PlantRepository] DioException: ${e.message}');
      print('[PlantRepository] URL tried: ${e.requestOptions.uri}');
      print('[PlantRepository] Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('[PlantRepository] Unexpected error: $e');
      throw Exception('Error: $e');
    }
  }
}
