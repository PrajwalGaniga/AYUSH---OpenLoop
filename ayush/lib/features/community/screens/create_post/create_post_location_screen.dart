import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/community_repository.dart';
import '../../../auth/providers/auth_provider.dart';

class CreatePostLocationScreen extends ConsumerStatefulWidget {
  final List<File> photos;
  final String plantName;
  final String description;
  final String availability;
  final String contactPreference;
  final String? whatsappNumber;

  const CreatePostLocationScreen({
    super.key,
    required this.photos,
    required this.plantName,
    required this.description,
    required this.availability,
    required this.contactPreference,
    this.whatsappNumber,
  });

  @override
  ConsumerState<CreatePostLocationScreen> createState() => _CreatePostLocationScreenState();
}

class _CreatePostLocationScreenState extends ConsumerState<CreatePostLocationScreen> {
  Position? _position;
  LatLng? _cameraPosition;
  String _neighborhood = 'Fetching location...';
  bool _isPosting = false;
  bool _locationError = false;
  final _repo = CommunityRepository();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final neighborhood = [
        place?.subLocality,
        place?.locality,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      setState(() {
        _position = pos;
        _cameraPosition = LatLng(pos.latitude, pos.longitude);
        _neighborhood = neighborhood.isNotEmpty ? neighborhood : 'Unknown area';
        _locationError = false;
      });
    } catch (e) {
      setState(() {
        _locationError = true;
        _neighborhood = 'Location unavailable';
      });
    }
  }

  Future<void> _updateNeighborhoodFromMap(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final neighborhood = [
        place?.subLocality,
        place?.locality,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      setState(() {
        _neighborhood = neighborhood.isNotEmpty ? neighborhood : 'Unknown area';
        _position = Position(
            longitude: pos.longitude,
            latitude: pos.latitude,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0);
      });
    } catch (e) {
      // Ignore errors when reverse geocoding fails during drag
    }
  }

  Future<void> _submitPost() async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for location...')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final authUser = ref.read(authProvider).value;
      final userId = authUser?.userId ?? 'current_user';
      final displayName = authUser?.profile?['name'] ?? 'Ayush User';

      await _repo.createPost(
        userId: userId,
        userDisplayName: displayName,
        plantName: widget.plantName,
        plantKey: '',
        description: widget.description,
        availability: widget.availability,
        contactPreference: widget.contactPreference,
        whatsappNumber: widget.whatsappNumber,
        lat: _position!.latitude,
        lng: _position!.longitude,
        neighborhood: _neighborhood,
        photos: widget.photos,
      );

      if (mounted) {
        // Pop all 3 create screens back to the community home
        Navigator.of(context).popUntil((route) {
          return route.isFirst || (route.settings.name == '/community');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌿 Your plant is now visible to the community!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        if (e.toString().contains('MAX_POSTS_REACHED')) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF0D1F3C),
              title: const Text('Post limit reached', style: TextStyle(color: Colors.white)),
              content: const Text(
                "You've reached the 5 post limit. Delete an old post to add a new one.",
                style: TextStyle(color: Colors.white60),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF4CAF50))),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed. Check your connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Confirm Location',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Step 3 of 3',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Map preview
          SizedBox(
            height: 250,
            child: _position != null
                ? Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_position!.latitude, _position!.longitude),
                          zoom: 15,
                        ),
                        onCameraMove: (position) {
                          _cameraPosition = position.target;
                        },
                        onCameraIdle: () {
                          if (_cameraPosition != null) {
                            _updateNeighborhoodFromMap(_cameraPosition!);
                          }
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 35),
                          child: Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 40),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: const Color(0xFF1E3A5F),
                    child: Center(
                      child: _locationError
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off, color: Colors.white38, size: 40),
                                SizedBox(height: 8),
                                Text('Location unavailable',
                                    style: TextStyle(color: Colors.white38)),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF4CAF50)),
                                SizedBox(height: 12),
                                Text('Getting your location...',
                                    style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                    ),
                  ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location info
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your location',
                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                            Text(_neighborhood,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only your neighborhood is shown publicly — not your exact location',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                  ),

                  const Divider(color: Colors.white12, height: 28),

                  // Post summary
                  const Text('POST SUMMARY',
                      style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          widget.photos.first,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.plantName,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              widget.availability[0].toUpperCase() +
                                  widget.availability.substring(1),
                              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 14),
                            ),
                            Text(
                              '${widget.photos.length} photo${widget.photos.length > 1 ? 's' : ''}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  if (_isPosting)
                    const Column(
                      children: [
                        Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                        SizedBox(height: 12),
                        Center(
                          child: Text('Uploading photos...',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2d6a4f),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _position != null ? _submitPost : null,
                        child: const Text('🌿 Post to Community', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
