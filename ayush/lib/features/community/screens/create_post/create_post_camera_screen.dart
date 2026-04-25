import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'create_post_details_screen.dart';

class CreatePostCameraScreen extends StatefulWidget {
  final String? prefilledPlantName;
  const CreatePostCameraScreen({super.key, this.prefilledPlantName});

  @override
  State<CreatePostCameraScreen> createState() => _CreatePostCameraScreenState();
}

class _CreatePostCameraScreenState extends State<CreatePostCameraScreen> {
  final List<File> _photos = [];
  final _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    if (_photos.length >= 3) {
      _showMaxPhotosSnack();
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _pickFromGallery() async {
    final remaining = 3 - _photos.length;
    if (remaining <= 0) {
      _showMaxPhotosSnack();
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isNotEmpty) {
      setState(() {
        for (final p in picked) {
          if (_photos.length < 3) _photos.add(File(p.path));
        }
      });
    }
  }

  void _showMaxPhotosSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum 3 photos allowed')),
    );
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
            Text('Share a Plant',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Step 1 of 3',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
      body: _photos.isEmpty ? _buildEmptyState() : _buildPhotoGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text(
            'Capture the plant you want to share',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Take up to 3 clear photos — leaf, flower, and full plant',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2d6a4f),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: _pickFromGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                ..._photos.asMap().entries.map((entry) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        entry.value,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(entry.key)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                )),
                if (_photos.length < 3)
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF4CAF50), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF1E3A5F),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Color(0xFF4CAF50), size: 36),
                          SizedBox(height: 8),
                          Text('Add another photo',
                              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _photos.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePostDetailsScreen(
                            photos: _photos,
                            prefilledPlantName: widget.prefilledPlantName,
                          ),
                        ),
                      ),
              child: const Text('Next: Add Details →', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
