import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/plant_provider.dart';

class PlantCameraScreen extends ConsumerStatefulWidget {
  const PlantCameraScreen({super.key});

  @override
  ConsumerState<PlantCameraScreen> createState() => _PlantCameraScreenState();
}

class _PlantCameraScreenState extends ConsumerState<PlantCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      final file = File(image.path);
      
      // Process the image
      await ref.read(plantProvider.notifier).classifyImage(file);
      
      if (!mounted) return;
      
      final state = ref.read(plantProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \${state.error}')),
        );
        return;
      }

      if (state.predictions.isEmpty) {
        _showRetakeSheet();
        return;
      }

      final topPrediction = state.predictions.first;
      
      if (topPrediction.confidence >= 0.70) {
        // High confidence - go direct
        context.push('/plant/result', extra: {
          'plantKey': topPrediction.plantKey,
          'confidence': topPrediction.confidence,
          'imageFile': file,
        });
      } else if (topPrediction.confidence >= 0.50) {
        // Medium confidence - confirm
        context.push('/plant/confirm', extra: {
          'predictions': state.predictions,
          'imageFile': file,
        });
      } else {
        // Low confidence
        _showRetakeSheet();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: \$e')),
      );
    }
  }

  void _showRetakeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AyushSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco, size: 64, color: AyushColors.herbalGreen),
                const SizedBox(height: AyushSpacing.md),
                Text('Plant not recognized', style: AyushTextStyles.h2),
                const SizedBox(height: AyushSpacing.sm),
                Text(
                  'Try again in better lighting with the leaf fully visible',
                  style: AyushTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AyushSpacing.lg),
                _buildTip('Get closer to the leaf'),
                _buildTip('Ensure good lighting — avoid shadows'),
                _buildTip('Capture a single leaf, not a branch'),
                const SizedBox(height: AyushSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AyushColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Try Again', style: AyushTextStyles.buttonPrimary),
                  ),
                ),
                const SizedBox(height: AyushSpacing.md),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Browse feature coming soon!')),
                    );
                  },
                  child: const Text('Browse Plants'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AyushColors.herbalGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AyushTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(plantProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Main UI
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Stack(
                    children: [
                      // Framing guides (corners)
                      _buildCorner(Alignment.topLeft),
                      _buildCorner(Alignment.topRight),
                      _buildCorner(Alignment.bottomLeft),
                      _buildCorner(Alignment.bottomRight),
                      
                      // Center icon
                      Center(
                        child: Icon(
                          Icons.filter_center_focus,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AyushSpacing.xl),
              Text(
                'Center the leaf or flower clearly',
                style: AyushTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildBottomButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AyushColors.herbalGreen),
                    const SizedBox(height: AyushSpacing.lg),
                    Text(
                      'Analyzing plant...',
                      style: AyushTextStyles.h2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight)
                ? const BorderSide(color: AyushColors.herbalGreen, width: 4)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight)
                ? const BorderSide(color: AyushColors.herbalGreen, width: 4)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
                ? const BorderSide(color: AyushColors.herbalGreen, width: 4)
                : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
                ? const BorderSide(color: AyushColors.herbalGreen, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: AyushTextStyles.labelMedium.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
