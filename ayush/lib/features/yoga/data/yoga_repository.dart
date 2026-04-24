import 'package:dio/dio.dart';
import '../models/asana.dart';

class YogaRepository {
  final Dio _dio;
  
  YogaRepository(this._dio);

  Future<List<Asana>> fetchAsanas() async {
    try {
      final resp = await _dio.get("/yoga/asanas");
      if (resp.statusCode == 200) {
        final data = resp.data["asanas"] as List;
        return data.map((e) => Asana.fromJson(e)).toList();
      }
      throw Exception("Failed to load asanas");
    } catch (e) {
      throw Exception("Error fetching asanas: $e");
    }
  }
}
