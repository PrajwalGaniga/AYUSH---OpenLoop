import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/detected_food_item.dart';
import '../models/food_analysis_result.dart';

class FoodScanRepository {
  final Dio _dio;

  FoodScanRepository(this._dio);

  Future<Map<String, dynamic>> scanFood(File image, String userId) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      ApiEndpoints.foodScan,
      data: formData,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final scanId = data['scan_id'] as String;
    final detectedItems = (data['detected_items'] as List<dynamic>)
        .map((e) => DetectedFoodItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'scan_id': scanId,
      'detected_items': detectedItems,
    };
  }

  Future<void> logMeal({
    required String userId,
    required String mealSource,
    required FoodAnalysisResult result,
  }) async {
    final payload = {
      'user_id': userId,
      'meal_source': mealSource,
      'total_ojas_delta': result.totalOjasDelta,
      'food_results': result.foodResults.map((e) => e.toJson()).toList(),
      'viruddha_warnings': result.viruddhaWarnings.map((e) => e.toJson()).toList(),
    };

    await _dio.post(
      ApiEndpoints.foodLog,
      data: payload,
    );
  }
}
