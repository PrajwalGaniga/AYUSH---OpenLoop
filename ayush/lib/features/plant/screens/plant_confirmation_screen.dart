import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../models/plant_prediction.dart';

class PlantConfirmationScreen extends StatefulWidget {
  final List<PlantPrediction> predictions;
  final File imageFile;

  const PlantConfirmationScreen({
    super.key,
    required this.predictions,
    required this.imageFile,
  });

  @override
  State<PlantConfirmationScreen> createState() => _PlantConfirmationScreenState();
}

class _PlantConfirmationScreenState extends State<PlantConfirmationScreen> {
  PlantPrediction? _selectedPrediction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: const Text('Is this the plant?'),
        backgroundColor: Colors.white,
        foregroundColor: AyushColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // Force explicit action
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Image & Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    child: Image.file(
                      widget.imageFile,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "We're not fully sure — please confirm below",
                            style: AyushTextStyles.bodySmall.copyWith(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AyushSpacing.xl),

                  // Section 2: Selection
                  Text('Select the correct plant', style: AyushTextStyles.h3),
                  const SizedBox(height: AyushSpacing.md),
                  ...widget.predictions.map((p) => _buildSelectionCard(p)),

                  const SizedBox(height: AyushSpacing.lg),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('+ None of these'),
                      style: TextButton.styleFrom(
                        foregroundColor: AyushColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(AyushSpacing.pagePadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AyushColors.primary,
                    disabledBackgroundColor: AyushColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    ),
                  ),
                  onPressed: _selectedPrediction == null ? null : () {
                    context.push('/plant/result', extra: {
                      'plantKey': _selectedPrediction!.plantKey,
                      'confidence': _selectedPrediction!.confidence,
                      'imageFile': widget.imageFile,
                    });
                  },
                  child: Text(
                    'Confirm this plant →',
                    style: AyushTextStyles.buttonPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(PlantPrediction prediction) {
    final isSelected = _selectedPrediction?.plantKey == prediction.plantKey;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPrediction = prediction;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AyushColors.herbalGreen : AyushColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/plants/\${prediction.plantKey}.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60, height: 60, color: AyushColors.surfaceVariant,
                  child: const Icon(Icons.eco, color: AyushColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prediction.plantName, style: AyushTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\${prediction.confidencePercent} match',
                      style: AyushTextStyles.caption.copyWith(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            
            // Radio
            Radio<PlantPrediction>(
              value: prediction,
              groupValue: _selectedPrediction,
              activeColor: AyushColors.herbalGreen,
              onChanged: (p) {
                if (p != null) {
                  setState(() {
                    _selectedPrediction = p;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
