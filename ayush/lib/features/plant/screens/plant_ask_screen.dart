import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/plant.dart';
import '../providers/plant_provider.dart';
import '../data/plant_knowledge_service.dart';

class PlantAskScreen extends ConsumerStatefulWidget {
  final Plant plant;

  const PlantAskScreen({super.key, required this.plant});

  @override
  ConsumerState<PlantAskScreen> createState() => _PlantAskScreenState();
}

class _PlantAskScreenState extends ConsumerState<PlantAskScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _quickQuestions = [
    "Can I take this during pregnancy?",
    "What is the correct dosage?",
    "Are there any side effects?",
    "Which season is best for this?",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _askQuestion() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final prakriti = ref.read(onboardingProvider).prakritiResult?.dominant?.toLowerCase();
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    ref.read(plantProvider.notifier).askQuestion(
      question: text,
      prakriti: prakriti,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantProvider);

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask About ${widget.plant.names.common}'),
            Text('Powered by Gemini AI', style: AyushTextStyles.caption.copyWith(color: AyushColors.primaryLight)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AyushColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Plant Card
                  Container(
                    padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
                    decoration: BoxDecoration(
                      color: AyushColors.herbalGreenLight,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            widget.plant.imageAsset,
                            width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Icon(Icons.eco),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.plant.names.common, style: AyushTextStyles.labelLarge),
                              Text(widget.plant.names.scientific, style: AyushTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AyushSpacing.xl),

                  // Input
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: "e.g. Can I take aloe vera with Metformin?",
                      labelText: "Your question",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => setState(() {}), // rebuild for button state
                  ),
                  const SizedBox(height: 12),

                  // Quick chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions.map((q) => ActionChip(
                      label: Text(q, style: AyushTextStyles.labelSmall),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AyushColors.border),
                      onPressed: () {
                        _controller.text = q;
                        setState(() {});
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: AyushSpacing.xl),

                  // Send Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AyushColors.primary,
                        disabledBackgroundColor: AyushColors.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                      ),
                      onPressed: _controller.text.trim().isEmpty || state.isAsking ? null : _askQuestion,
                      child: state.isAsking 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Get Answer →', style: AyushTextStyles.buttonPrimary),
                    ),
                  ),

                  // Error
                  if (state.error != null && !state.isAsking)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
                    ),

                  // Answer Card
                  if (state.askResponse != null && !state.isAsking) ...[
                    const SizedBox(height: AyushSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                        boxShadow: AyushColors.subtleShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AyushColors.primary),
                              const SizedBox(width: 8),
                              Text('Answer', style: AyushTextStyles.h3),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.askResponse!['answer'] ?? '',
                            style: AyushTextStyles.bodyLarge,
                          ),
                          
                          if ((state.askResponse!['sources_mentioned'] as List?)?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            Text('Classical References:', style: AyushTextStyles.labelSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: (state.askResponse!['sources_mentioned'] as List).map<Widget>((s) => Chip(
                                label: Text(s.toString()),
                                backgroundColor: AyushColors.sand,
                              )).toList(),
                            ),
                          ],
                          
                          const Divider(height: 32),
                          Text(
                            state.askResponse!['confidence_note'] ?? '',
                            style: AyushTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade50,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      PlantKnowledgeService.instance.disclaimer,
                      style: AyushTextStyles.caption.copyWith(color: Colors.orange.shade900),
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
