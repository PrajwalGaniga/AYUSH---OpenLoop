import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/recipe_provider.dart';

class CookingModeScreen extends ConsumerStatefulWidget {
  const CookingModeScreen({super.key});

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  int _currentStepIndex = 0;
  late FlutterTts _flutterTts;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);
    final recipe = state.generatedRecipe;

    if (recipe == null || recipe.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No recipe steps available.")),
      );
    }

    final currentStep = recipe.steps[_currentStepIndex];
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == recipe.steps.length - 1;

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("Cooking Mode", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stop();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AyushSpacing.pagePadding),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStepIndex + 1) / recipe.steps.length,
                backgroundColor: AyushColors.primary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AyushColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AyushSpacing.xl),
              
              // Step number
              Text(
                "Step ${_currentStepIndex + 1} of ${recipe.steps.length}",
                style: AyushTextStyles.labelMedium.copyWith(color: AyushColors.primary),
              ),
              const SizedBox(height: AyushSpacing.lg),

              // Instruction card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AyushSpacing.xl),
                  decoration: BoxDecoration(
                    color: AyushColors.card,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                    boxShadow: AyushColors.cardShadow,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        currentStep.instruction,
                        style: AyushTextStyles.h2.copyWith(height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AyushSpacing.xl),

              // TTS Controls
              FloatingActionButton.large(
                onPressed: () {
                  if (_isPlaying) {
                    _stop();
                  } else {
                    _speak(currentStep.instruction);
                  }
                },
                backgroundColor: _isPlaying ? AyushColors.error : AyushColors.herbalGreen,
                elevation: 4,
                child: Icon(_isPlaying ? Icons.stop : Icons.volume_up, color: Colors.white, size: 36),
              ),
              
              const SizedBox(height: AyushSpacing.xl),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isFirstStep ? null : () {
                        _stop();
                        setState(() => _currentStepIndex--);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                      ),
                      child: const Text("Previous", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLastStep ? () {
                        _stop();
                        context.pop(); // Back to recipe display
                      } : () {
                        _stop();
                        setState(() => _currentStepIndex++);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AyushColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                      ),
                      child: Text(isLastStep ? "Finish" : "Next", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
