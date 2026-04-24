import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final Dio _dio;

  RecipeRepository(this._dio);

  Future<RecipeModel> generateRecipe({
    required String userId,
    required List<String> ingredients,
    required List<String> spices,
    required String prakriti,
    required List<String> conditions,
    required String diet,
    required String region,
  }) async {
    final payload = {
      "user_id": userId,
      "ingredients": ingredients,
      "spices": spices,
      "prakriti": prakriti,
      "conditions": conditions,
      "diet": diet,
      "region": region,
      "language": "English"
    };

    final response = await _dio.post(
      ApiEndpoints.recipeGenerate,
      data: payload,
    );

    if (response.statusCode == 200) {
      final recipeData = response.data['data'];
      return RecipeModel.fromJson(recipeData);
    } else {
      throw Exception('Failed to generate recipe');
    }
  }

  Future<List<YouTubeVideo>> searchYouTube(String query) async {
    final response = await _dio.get(
      ApiEndpoints.recipeYoutube,
      queryParameters: {'query': query},
    );

    if (response.statusCode == 200) {
      final List videos = response.data['videos'] ?? [];
      return videos.map((v) => YouTubeVideo.fromJson(v)).toList();
    } else {
      return [];
    }
  }
}
