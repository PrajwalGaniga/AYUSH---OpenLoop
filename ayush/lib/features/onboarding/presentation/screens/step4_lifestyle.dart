import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

class Step4Lifestyle extends ConsumerStatefulWidget {
  const Step4Lifestyle({super.key});

  @override
  ConsumerState<Step4Lifestyle> createState() => _Step4LifestyleState();
}

class _Step4LifestyleState extends ConsumerState<Step4Lifestyle> {
  String? _occupation;
  int _stressLevel = 2; // 0-4
  String? _exerciseFreq;
  String? _dietType;
  double _waterLiters = 1.5;
  double _sleepHours = 7;
  bool _smoking = false;
  bool _alcohol = false;
  bool _yoga = false;
  bool _meditation = false;
  bool _highScreen = false;
  String? _screenTime;

  static const _stressEmojis = ['😌', '😐', '😟', '😰', '🤯'];
  static const _stressLabels = ['Rarely', 'Sometimes', 'Often', 'Very Often', 'Always'];
  static const _stressValues = ['rarely', 'sometimes', 'often', 'very_often', 'always'];

  Future<void> _submit() async {
    ref.read(onboardingProvider.notifier).updateLifestyle(
          occupationType: _occupation,
          stressLevel: _stressValues[_stressLevel],
          exerciseFrequency: _exerciseFreq,
          dietType: _dietType,
          waterIntakeLiters: _waterLiters,
          sleepHours: _sleepHours,
          smokingStatus: _smoking ? 'regular' : 'none',
          alcoholStatus: _alcohol ? 'regular' : 'none',
          yogaPractice: _yoga || _meditation,
          meditationPractice: _meditation,
        );

    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      await ref.read(onboardingProvider.notifier).submitStep4(userId);
      if (mounted) context.go('/onboarding/4');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return OnboardingShell(
      currentStep: 3,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AyushSpacing.pagePadding, AyushSpacing.lg,
              AyushSpacing.pagePadding, 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tell us how\nyou live', style: AyushTextStyles.h1)
                    .animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 8),
                Text('Your daily habits shape your health deeply', style: AyushTextStyles.bodyMedium)
                    .animate(delay: 100.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 32),

                // ── Occupation ────────────────────────────────────────────
                _buildLabel('Occupation Type'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildOccupCard('Sedentary', Icons.computer, 'sedentary'),
                      _buildOccupCard('Light', Icons.store, 'light'),
                      _buildOccupCard('Moderate', Icons.directions_walk, 'moderate'),
                      _buildOccupCard('Active', Icons.agriculture, 'active'),
                      _buildOccupCard('Athletic', Icons.sports, 'athletic'),
                    ],
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Stress level ──────────────────────────────────────────
                _buildLabel('Stress Level'),
                Container(
                  padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
                  decoration: BoxDecoration(
                    color: AyushColors.card,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    border: Border.all(color: AyushColors.divider),
                    boxShadow: AyushColors.subtleShadow,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _stressEmojis[_stressLevel],
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stressLabels[_stressLevel],
                        style: AyushTextStyles.labelMedium.copyWith(color: AyushColors.primary),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _stressLevel.toDouble(),
                          min: 0,
                          max: 4,
                          divisions: 4,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _stressLevel = v.round());
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calm', style: AyushTextStyles.caption),
                          Text('Overwhelmed', style: AyushTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Exercise frequency ────────────────────────────────────
                _buildLabel('Exercise Frequency'),
                _buildSegmentedControl(
                  options: {'Never': 'never', '1-2×/wk': '1_2_week', '3-4×/wk': '3_4_week', 'Daily': 'daily'},
                  selected: _exerciseFreq,
                  onChanged: (v) => setState(() => _exerciseFreq = v),
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Diet type ─────────────────────────────────────────────
                _buildLabel('Diet Type'),
                Row(
                  children: [
                    _buildDietCard('Vegetarian', '🌿', 'vegetarian'),
                    const SizedBox(width: 10),
                    _buildDietCard('Vegan', '🥗', 'vegan'),
                    const SizedBox(width: 10),
                    _buildDietCard('Non-Veg', '🍗', 'non_vegetarian'),
                  ],
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Water intake ──────────────────────────────────────────
                _buildLabel('Daily Water Intake'),
                _buildWaterWidget().animate(delay: 350.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Sleep hours ───────────────────────────────────────────
                _buildLabel('Sleep Hours'),
                Container(
                  padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
                  decoration: BoxDecoration(
                    color: AyushColors.card,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    border: Border.all(color: AyushColors.divider),
                    boxShadow: AyushColors.subtleShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_sleepHours.toStringAsFixed(1)} hrs',
                            style: AyushTextStyles.h3.copyWith(color: AyushColors.primary),
                          ),
                          const Icon(Icons.bedtime_outlined, color: AyushColors.primary),
                        ],
                      ),
                      Slider(
                        value: _sleepHours,
                        min: 4,
                        max: 12,
                        divisions: 16,
                        onChanged: (v) => setState(() => _sleepHours = v),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Habit toggles ─────────────────────────────────────────
                _buildLabel('Habits'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    _buildHabitToggle('🚬 Smoking', _smoking, (v) => setState(() => _smoking = v)),
                    _buildHabitToggle('🍺 Alcohol', _alcohol, (v) => setState(() => _alcohol = v)),
                    _buildHabitToggle('🧘 Yoga/Meditation', _yoga || _meditation, (v) {
                      setState(() { _yoga = v; _meditation = v; });
                    }),
                    _buildHabitToggle('📱 High Screen Time', _highScreen, (v) => setState(() {
                      _highScreen = v;
                      if (!v) _screenTime = null;
                    })),
                  ],
                ).animate(delay: 450.ms).fadeIn(duration: 500.ms),

                // ── Screen time (conditional) ─────────────────────────────
                if (_highScreen) ...[
                  const SizedBox(height: 16),
                  _buildLabel('Daily Screen Time'),
                  _buildSegmentedControl(
                    options: {'< 2h': 'under_2', '2–4h': '2_4', '4–6h': '4_6', '> 6h': 'over_6'},
                    selected: _screenTime,
                    onChanged: (v) => setState(() => _screenTime = v),
                  ).animate().fadeIn(duration: 300.ms),
                ],
              ],
            ),
          ),

          // ── Continue button ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              decoration: BoxDecoration(
                color: AyushColors.background,
                border: Border(top: BorderSide(color: AyushColors.divider)),
              ),
              child: AyushButton(
                label: 'Continue',
                onPressed: _submit,
                isLoading: isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AyushTextStyles.labelMedium),
    );
  }

  Widget _buildOccupCard(String label, IconData icon, String value) {
    final isSelected = _occupation == value;
    return GestureDetector(
      onTap: () => setState(() => _occupation = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AyushColors.primarySurface : AyushColors.card,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AyushColors.primary : AyushColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? AyushColors.primary : AyushColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: AyushTextStyles.caption.copyWith(
                color: isSelected ? AyushColors.primary : AyushColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required Map<String, String> options,
    required String? selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AyushColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
        border: Border.all(color: AyushColors.border),
      ),
      child: Row(
        children: options.entries.map((e) {
          final isSelected = selected == e.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(e.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AyushColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AyushSpacing.radiusSm),
                ),
                child: Text(
                  e.key,
                  textAlign: TextAlign.center,
                  style: AyushTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AyushColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDietCard(String label, String emoji, String value) {
    final isSelected = _dietType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dietType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AyushColors.herbalGreenLight : AyushColors.card,
            borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AyushColors.herbalGreen : AyushColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AyushTextStyles.caption.copyWith(
                  color: isSelected ? AyushColors.herbalGreen : AyushColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterWidget() {
    final filledGlasses = (_waterLiters / 0.5).round();
    return GestureDetector(
      onTap: () => setState(() {
        _waterLiters = (_waterLiters + 0.5).clamp(0.5, 4.0);
        if (_waterLiters > 3.0) _waterLiters = 0.5;
      }),
      child: Container(
        padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
        decoration: BoxDecoration(
          color: AyushColors.card,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          border: Border.all(color: AyushColors.divider),
          boxShadow: AyushColors.subtleShadow,
        ),
        child: Row(
          children: [
            Text(
              '${_waterLiters.toStringAsFixed(1)} L',
              style: AyushTextStyles.h3.copyWith(color: AyushColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: List.generate(6, (i) {
                  final isFilled = i < filledGlasses;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 32,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? AyushColors.primary.withOpacity(0.7)
                            : AyushColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AyushColors.border),
                      ),
                      child: isFilled
                          ? const Center(child: Icon(Icons.water_drop, size: 12, color: Colors.white))
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline, color: AyushColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitToggle(String label, bool isOn, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!isOn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOn ? AyushColors.primarySurface : AyushColors.card,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          border: Border.all(
            color: isOn ? AyushColors.primary : AyushColors.border,
            width: isOn ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AyushTextStyles.labelSmall.copyWith(
                color: isOn ? AyushColors.primary : AyushColors.textSecondary,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: isOn ? AyushColors.primary : AyushColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
