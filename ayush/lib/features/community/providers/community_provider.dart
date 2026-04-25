import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/community_repository.dart';
import '../models/plant_post.dart';

// ── Repository provider ────────────────────────────────
final communityRepositoryProvider = Provider((ref) => CommunityRepository());

// ── Location provider ──────────────────────────────────
final userLocationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
});

// ── Filter state ────────────────────────────────────────
class CommunityFilter {
  final double radiusKm;
  final String? availability;
  final String? plantName;

  const CommunityFilter({
    this.radiusKm = 20.0,
    this.availability,
    this.plantName,
  });

  CommunityFilter copyWith({
    double? radiusKm,
    String? availability,
    String? plantName,
    bool clearAvailability = false,
    bool clearPlantName = false,
  }) =>
      CommunityFilter(
        radiusKm: radiusKm ?? this.radiusKm,
        availability: clearAvailability ? null : (availability ?? this.availability),
        plantName: clearPlantName ? null : (plantName ?? this.plantName),
      );
}

class CommunityFilterNotifier extends Notifier<CommunityFilter> {
  @override
  CommunityFilter build() => const CommunityFilter();

  void setRadius(double km) => state = state.copyWith(radiusKm: km);
  void setAvailability(String? a) => state = state.copyWith(
        availability: a,
        clearAvailability: a == null,
      );
  void setPlantName(String? name) => state = state.copyWith(
        plantName: name,
        clearPlantName: name == null,
      );
  void clear() => state = const CommunityFilter();
}

final communityFilterProvider =
    NotifierProvider<CommunityFilterNotifier, CommunityFilter>(
  CommunityFilterNotifier.new,
);

// ── Posts provider ─────────────────────────────────────
class NearbyPostsNotifier extends AsyncNotifier<List<PlantPost>> {
  @override
  Future<List<PlantPost>> build() async {
    final location = await ref.watch(userLocationProvider.future);
    if (location == null) return [];
    final filter = ref.watch(communityFilterProvider);
    final repo = ref.read(communityRepositoryProvider);
    return repo.fetchNearbyPosts(
      userId: 'current_user', // will be replaced with actual user id
      lat: location.latitude,
      lng: location.longitude,
      radiusKm: filter.radiusKm,
      plantName: filter.plantName,
      availability: filter.availability,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  void toggleSave(String postId, String userId) {
    final repo = ref.read(communityRepositoryProvider);
    state.whenData((posts) {
      final updated = posts.map((p) {
        if (p.postId == postId) {
          return p.copyWith(
            isSaved: !p.isSaved,
            savedByCount: p.isSaved ? p.savedByCount - 1 : p.savedByCount + 1,
          );
        }
        return p;
      }).toList();
      state = AsyncValue.data(updated);
      repo.toggleSave(postId, userId).catchError((_) {
        // revert on error
        state = AsyncValue.data(posts);
        return false;
      });
    });
  }
}

final nearbyPostsProvider =
    AsyncNotifierProvider<NearbyPostsNotifier, List<PlantPost>>(
  NearbyPostsNotifier.new,
);

// ── My requests provider ───────────────────────────────
final myRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.read(communityRepositoryProvider).fetchMyRequests(userId);
});
