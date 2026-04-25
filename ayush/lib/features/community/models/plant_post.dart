import 'package:flutter/material.dart';

enum Availability { few, moderate, abundant }
enum PostStatus { active, review, archived }
enum ContactPreference { inApp, whatsapp, none }

extension AvailabilityExt on Availability {
  String get label => name[0].toUpperCase() + name.substring(1);
  Color get color {
    switch (this) {
      case Availability.few:
        return const Color(0xFFf4a261);
      case Availability.moderate:
        return const Color(0xFF457b9d);
      case Availability.abundant:
        return const Color(0xFF2d6a4f);
    }
  }
}

class PostLocation {
  final String geohash;
  final double lat;
  final double lng;
  final String neighborhood;

  const PostLocation({
    required this.geohash,
    required this.lat,
    required this.lng,
    required this.neighborhood,
  });

  factory PostLocation.fromJson(Map<String, dynamic> j) => PostLocation(
        geohash: j['geohash'] ?? '',
        lat: (j['lat'] ?? 0).toDouble(),
        lng: (j['lng'] ?? 0).toDouble(),
        neighborhood: j['neighborhood'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'geohash': geohash,
        'lat': lat,
        'lng': lng,
        'neighborhood': neighborhood,
      };
}

class PlantPost {
  final String postId;
  final String userId;
  final String userDisplayName;
  final String plantName;
  final String plantKey;
  final String description;
  final Availability availability;
  final List<String> photoUrls;
  final PostLocation location;
  final ContactPreference contactPreference;
  final String? whatsappNumber;
  final int savedByCount;
  final bool isSaved;
  final int flagCount;
  final PostStatus status;
  final int daysLeft;
  final DateTime createdAt;
  final double? distanceKm;

  const PlantPost({
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    required this.plantName,
    required this.plantKey,
    required this.description,
    required this.availability,
    required this.photoUrls,
    required this.location,
    required this.contactPreference,
    this.whatsappNumber,
    required this.savedByCount,
    required this.isSaved,
    required this.flagCount,
    required this.status,
    required this.daysLeft,
    required this.createdAt,
    this.distanceKm,
  });

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()}m away';
    return '${distanceKm!.toStringAsFixed(1)}km away';
  }

  PlantPost copyWith({bool? isSaved, int? savedByCount}) => PlantPost(
        postId: postId,
        userId: userId,
        userDisplayName: userDisplayName,
        plantName: plantName,
        plantKey: plantKey,
        description: description,
        availability: availability,
        photoUrls: photoUrls,
        location: location,
        contactPreference: contactPreference,
        whatsappNumber: whatsappNumber,
        savedByCount: savedByCount ?? this.savedByCount,
        isSaved: isSaved ?? this.isSaved,
        flagCount: flagCount,
        status: status,
        daysLeft: daysLeft,
        createdAt: createdAt,
        distanceKm: distanceKm,
      );

  factory PlantPost.fromJson(Map<String, dynamic> j) => PlantPost(
        postId: j['post_id'] ?? '',
        userId: j['user_id'] ?? '',
        userDisplayName: j['user_display_name'] ?? '',
        plantName: j['plant_name'] ?? '',
        plantKey: j['plant_key'] ?? '',
        description: j['description'] ?? '',
        availability: Availability.values.firstWhere(
          (e) => e.name == j['availability'],
          orElse: () => Availability.few,
        ),
        photoUrls: List<String>.from(j['photo_urls'] ?? []),
        location: PostLocation.fromJson(j['location'] ?? {}),
        contactPreference: ContactPreference.values.firstWhere(
          (e) => e.name == (j['contact_preference']?.replaceAll('_', '') ?? 'inApp').replaceAll('in_app', 'inApp'),
          orElse: () => ContactPreference.inApp,
        ),
        whatsappNumber: j['whatsapp_number'],
        savedByCount: j['saved_by_count'] ?? 0,
        isSaved: j['is_saved'] ?? false,
        flagCount: j['flag_count'] ?? 0,
        status: PostStatus.values.firstWhere(
          (e) => e.name == (j['status'] ?? 'active'),
          orElse: () => PostStatus.active,
        ),
        daysLeft: j['days_left'] ?? 30,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        distanceKm: j['distance_km']?.toDouble(),
      );
}
