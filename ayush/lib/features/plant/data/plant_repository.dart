import 'dart:convert';
import 'package:http/http.dart' as http;

class PlantRepository {
  // Use appropriate URL based on the environment
  static const String baseUrl = "http://10.0.2.2:8000"; // Android emulator localhost

  Future<Map<String, dynamic>> askQuestion({
    required String plantName,
    required String plantScientific,
    required String question,
    String? prakriti,
    List<String> conditions = const [],
    List<String> medications = const [],
  }) async {
    try {
      final resp = await http.post(
        Uri.parse("\$baseUrl/api/v1/plant/ask"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plant_name": plantName,
          "plant_scientific": plantScientific,
          "user_question": question,
          "prakriti": prakriti,
          "conditions": conditions,
          "medications": medications,
        }),
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
      throw Exception("Failed to get answer: \${resp.statusCode} \${resp.body}");
    } catch (e) {
      throw Exception("Network error: \$e");
    }
  }
}
