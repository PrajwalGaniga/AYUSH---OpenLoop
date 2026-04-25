import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant_post.dart';
import 'post_detail_screen.dart';

class CommunityMapScreen extends StatefulWidget {
  final double userLat;
  final double userLng;
  final List<PlantPost> posts;

  const CommunityMapScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.posts,
  });

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  PlantPost? _selectedPost;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(CommunityMapScreen old) {
    super.didUpdateWidget(old);
    if (old.posts != widget.posts) _buildMarkers();
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final post in widget.posts) {
      final hue = _hueForAvailability(post.availability);
      markers.add(Marker(
        markerId: MarkerId(post.postId),
        position: LatLng(post.location.lat, post.location.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => setState(() => _selectedPost = post),
      ));
    }
    setState(() => _markers = markers);
  }

  double _hueForAvailability(Availability a) {
    switch (a) {
      case Availability.few:
        return BitmapDescriptor.hueOrange;
      case Availability.moderate:
        return BitmapDescriptor.hueAzure;
      case Availability.abundant:
        return BitmapDescriptor.hueGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.userLat, widget.userLng),
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (_) {},
          onTap: (_) => setState(() => _selectedPost = null),
          mapType: MapType.normal,
        ),
        // Post preview card
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          bottom: _selectedPost != null ? 16 : -200,
          left: 12,
          right: 12,
          child: _selectedPost != null
              ? _buildPreviewCard(_selectedPost!)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(PlantPost post) {
    return Card(
      color: const Color(0xFF0D1F3C),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.photoUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 60, height: 60,
                            color: const Color(0xFF1E3A5F),
                            child: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 60, height: 60,
                            color: const Color(0xFF1E3A5F),
                            child: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
                          ),
                        )
                      : Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 32),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.plantName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(post.location.neighborhood,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Color(0xFF4CAF50)),
                          Text(post.distanceLabel,
                              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: post.availability.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: post.availability.color),
                            ),
                            child: Text(
                              post.availability.label,
                              style: TextStyle(color: post.availability.color, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                ),
                child: const Text('View Details →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
