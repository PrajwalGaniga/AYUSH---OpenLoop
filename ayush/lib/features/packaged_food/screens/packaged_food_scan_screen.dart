import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/packaged_food_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/onboarding/providers/onboarding_provider.dart';

class PackagedFoodScanScreen extends ConsumerStatefulWidget {
  const PackagedFoodScanScreen({super.key});

  @override
  ConsumerState<PackagedFoodScanScreen> createState() =>
      _PackagedFoodScanScreenState();
}

class _PackagedFoodScanScreenState
    extends ConsumerState<PackagedFoodScanScreen> {
  final _picker = ImagePicker();

  static const _purple = Color(0xFF6A1B9A);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (picked == null) return;
      ref
          .read(packagedFoodProvider.notifier)
          .setImage(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _analyze() async {
    final user = ref.read(authProvider).value;
    final onboarding = ref.read(onboardingProvider);

    final prakriti = onboarding.prakritiResult?.dominant ??
        user?.prakritiResult?['dominant']?.toString() ??
        '';
    final ojasScore = onboarding.ojasResult?.ojasScore ??
        user?.ojasScore ??
        0;
    final conditions =
        user?.profile?['conditions']?.toString() ?? '';
    final medications =
        user?.profile?['medications']?.toString() ?? '';

    final ok = await ref.read(packagedFoodProvider.notifier).analyze(
          prakriti: prakriti,
          conditions: conditions,
          ojasScore: ojasScore,
          medications: medications,
        );

    if (ok && mounted) context.push('/packaged-food/result');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packagedFoodProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Food Label',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            ref.read(packagedFoodProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── Hero instruction ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_purple, const Color(0xFF9C27B0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('📦', style: TextStyle(fontSize: 40)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Packaged Food Scanner',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Point at the ingredients / nutrition label. AI will tell you if this food suits your body type.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Image preview / placeholder ───────────────────────
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.selectedImage != null
                                ? _purple
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: state.selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(
                                  state.selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to select from gallery',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pick buttons ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _PickButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Tips ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        children: const [
                          _TipRow(emoji: '💡', text: 'Focus on the Ingredients / Nutrition Facts panel'),
                          SizedBox(height: 6),
                          _TipRow(emoji: '🔆', text: 'Ensure good lighting — avoid shadows on the label'),
                          SizedBox(height: 6),
                          _TipRow(emoji: '📐', text: 'Hold phone parallel to the label for best results'),
                        ],
                      ),
                    ),

                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Analyse button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.selectedImage != null && !state.isLoading
                      ? _analyze
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: state.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('Reading label & analysing...',
                                style: TextStyle(fontSize: 14)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Analyse Food Label',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6A1B9A)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A1B9A),
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _TipRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    height: 1.4))),
      ],
    );
  }
}
