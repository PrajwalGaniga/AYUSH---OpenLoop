import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/env/env.dart';
import '../models/plant_prediction.dart';

class PlantClassifierService {
  static PlantClassifierService? _instance;
  final Dio _dio = Dio();

  static PlantClassifierService get instance {
    _instance ??= PlantClassifierService._();
    return _instance!;
  }
  
  PlantClassifierService._() {
    _dio.options.baseUrl = Env.apiBaseUrl;
  }

  Future<List<PlantPrediction>> classify(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      String ext = fileName.split('.').last.toLowerCase();
      MediaType mediaType = MediaType('image', 'jpeg');
      if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      }

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: mediaType,
        ),
      });

      final response = await _dio.post('/plant/identify', data: formData);

      if (response.statusCode == 200) {
        final List<dynamic> predictions = response.data['predictions'];
        return predictions.map((p) => PlantPrediction(
          plantKey: p['plantKey'],
          plantName: p['plantName'],
          confidence: (p['confidence'] as num).toDouble(),
        )).toList();
      } else {
        throw Exception('Failed to classify image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image classification failed: $e');
    }
  }
}
