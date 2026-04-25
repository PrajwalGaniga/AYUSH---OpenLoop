import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/packaged_food_result.dart';

class PackagedFoodRepository {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90), // OCR can be slow
  ));

  Future<PackagedFoodResult> analyze({
    required File imageFile,
    required String prakriti,
    required String conditions,
    required int ojasScore,
    required String medications,
  }) async {
    final url = '${Env.apiBaseUrl}/packaged-food/analyze';
    print('[PackagedFood] POST $url');
    print('[PackagedFood] Prakriti=$prakriti | Ojas=$ojasScore');

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'food_label.jpg',
      ),
      'prakriti': prakriti,
      'conditions': conditions,
      'ojas_score': ojasScore.toString(),
      'medications': medications,
    });

    try {
      final response = await _dio.post(url, data: formData);
      print('[PackagedFood] Response ${response.statusCode}');
      return PackagedFoodResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      print('[PackagedFood] ERROR: $msg');
      throw Exception(msg);
    }
  }
}
