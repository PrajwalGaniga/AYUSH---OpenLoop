import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/community_provider.dart';
import 'community_map_screen.dart';
import 'community_feed_screen.dart';
import 'my_requests_screen.dart';
import 'create_post/create_post_camera_screen.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  int _currentIndex = 0;
  double _selectedRadius = 20.0;
  String? _selectedAvailability;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final postsAsync = ref.watch(nearbyPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3C),
        elevation: 0,
        title: const Text(
          'Plant Community',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.inbox_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
        ],
      ),
      body: locationAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text('Getting your location...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        error: (_, __) => _buildLocationDenied(),
        data: (position) {
          if (position == null) return _buildLocationDenied();
          return postsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.white70)),
            ),
            data: (posts) => IndexedStack(
              index: _currentIndex,
              children: [
                CommunityMapScreen(
                  userLat: position.latitude,
                  userLng: position.longitude,
                  posts: posts,
                ),
                CommunityFeedScreen(
                  userLat: position.latitude,
                  userLng: position.longitude,
                  posts: posts,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1F3C),
          border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.white38,
          elevation: 0,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.view_list_outlined), label: 'Feed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2d6a4f),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Post a Plant'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostCameraScreen()),
        ),
      ),
    );
  }

  Widget _buildLocationDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 72, color: Color(0xFF4CAF50)),
            const SizedBox(height: 20),
            const Text(
              'Location needed',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'We need your location to show plants near you',
              style: TextStyle(color: Colors.white60, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await Geolocator.requestPermission();
                ref.invalidate(userLocationProvider);
              },
              child: const Text('Grant Permission', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    double localRadius = _selectedRadius;
    String? localAvailability = _selectedAvailability;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1F3C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Filter Posts',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Search radius', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [5.0, 10.0, 20.0, 50.0].map((km) => ChoiceChip(
                    label: Text('${km.toInt()}km'),
                    selected: localRadius == km,
                    selectedColor: const Color(0xFF2d6a4f),
                    labelStyle: TextStyle(
                      color: localRadius == km ? Colors.white : Colors.white60,
                    ),
                    backgroundColor: const Color(0xFF1E3A5F),
                    onSelected: (_) => setModalState(() => localRadius = km),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Availability', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['few', 'moderate', 'abundant'].map((a) => FilterChip(
                    label: Text(a[0].toUpperCase() + a.substring(1)),
                    selected: localAvailability == a,
                    selectedColor: const Color(0xFF2d6a4f),
                    labelStyle: TextStyle(
                      color: localAvailability == a ? Colors.white : Colors.white60,
                    ),
                    backgroundColor: const Color(0xFF1E3A5F),
                    onSelected: (sel) => setModalState(
                      () => localAvailability = sel ? a : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          foregroundColor: Colors.white60,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRadius = 20.0;
                            _selectedAvailability = null;
                          });
                          ref.read(communityFilterProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRadius = localRadius;
                            _selectedAvailability = localAvailability;
                          });
                          ref.read(communityFilterProvider.notifier).setRadius(localRadius);
                          ref.read(communityFilterProvider.notifier).setAvailability(localAvailability);
                          ref.invalidate(nearbyPostsProvider);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
