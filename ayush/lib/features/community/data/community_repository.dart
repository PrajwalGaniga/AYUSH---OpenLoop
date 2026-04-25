import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/plant_post.dart';
import '../../../core/env/env.dart';

class CommunityRepository {
  static String get baseUrl {
    // Strip trailing /api/v1 if present, then append community path
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/api/v1$'), '');
    return '$base/api/v1/community';
  }

  Future<List<PlantPost>> fetchNearbyPosts({
    required String userId,
    required double lat,
    required double lng,
    double radiusKm = 20,
    String? plantName,
    String? availability,
    int page = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/posts/nearby').replace(
      queryParameters: {
        'user_id': userId,
        'user_lat': lat.toString(),
        'user_lng': lng.toString(),
        'radius_km': radiusKm.toString(),
        if (plantName != null && plantName.isNotEmpty) 'plant_name': plantName,
        if (availability != null) 'availability': availability,
        'page': page.toString(),
      },
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('Failed to fetch posts');
    final data = jsonDecode(resp.body);
    return (data['posts'] as List).map((j) => PlantPost.fromJson(j)).toList();
  }

  Future<PlantPost> fetchPost(String postId, String userId) async {
    final resp = await http.get(
      Uri.parse('$baseUrl/posts/$postId?user_id=$userId'),
    );
    if (resp.statusCode != 200) throw Exception('Post not found');
    return PlantPost.fromJson(jsonDecode(resp.body));
  }

  Future<String> createPost({
    required String userId,
    required String userDisplayName,
    required String plantName,
    required String plantKey,
    required String description,
    required String availability,
    required String contactPreference,
    String? whatsappNumber,
    required double lat,
    required double lng,
    required String neighborhood,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));
    request.fields.addAll({
      'user_id': userId,
      'user_display_name': userDisplayName,
      'plant_name': plantName,
      'plant_key': plantKey,
      'description': description,
      'availability': availability,
      'contact_preference': contactPreference,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      'location_lat': lat.toString(),
      'location_lng': lng.toString(),
      'location_neighborhood': neighborhood,
    });
    for (final photo in photos) {
      final path = photo.path.toLowerCase();
      final mime = path.endsWith('.png') ? 'image/png'
          : path.endsWith('.webp') ? 'image/webp'
          : 'image/jpeg'; // default — covers .jpg, .jpeg, .heic renamed
      request.files.add(await http.MultipartFile.fromPath(
        'photos',
        photo.path,
        contentType: MediaType.parse(mime),
      ));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      final err = jsonDecode(resp.body)['detail'] ?? 'Upload failed';
      throw Exception(err);
    }
    return jsonDecode(resp.body)['post_id'];
  }

  Future<bool> toggleSave(String postId, String userId) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/posts/$postId/save?user_id=$userId'),
    );
    if (resp.statusCode != 200) throw Exception('Save failed');
    return jsonDecode(resp.body)['is_saved'];
  }

  Future<void> flagPost(String postId, String userId, String reason) async {
    await http.post(
      Uri.parse('$baseUrl/posts/$postId/flag'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'reason': reason}),
    );
  }

  Future<void> deletePost(String postId, String userId) async {
    final resp = await http.delete(
      Uri.parse('$baseUrl/posts/$postId?user_id=$userId'),
    );
    if (resp.statusCode != 200) throw Exception('Delete failed');
  }

  Future<void> sendContactRequest({
    required String fromUserId,
    required String fromDisplayName,
    required String toUserId,
    required String postId,
    required String plantName,
    required String message,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/contact-requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'from_user_id': fromUserId,
        'from_display_name': fromDisplayName,
        'to_user_id': toUserId,
        'post_id': postId,
        'plant_name': plantName,
        'message': message,
      }),
    );
    if (resp.statusCode != 200) {
      final err = jsonDecode(resp.body)['detail'] ?? 'Failed to send';
      throw Exception(err);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyRequests(String userId) async {
    final resp = await http.get(
      Uri.parse('$baseUrl/contact-requests/received?user_id=$userId'),
    );
    if (resp.statusCode != 200) throw Exception('Failed to fetch requests');
    return List<Map<String, dynamic>>.from(jsonDecode(resp.body)['requests']);
  }

  Future<List<PlantPost>> fetchMyPosts(String userId) async {
    final resp = await http.get(Uri.parse('$baseUrl/posts/user/$userId'));
    if (resp.statusCode != 200) throw Exception('Failed to fetch my posts');
    final data = jsonDecode(resp.body);
    return (data['posts'] as List).map((j) => PlantPost.fromJson(j)).toList();
  }
}
