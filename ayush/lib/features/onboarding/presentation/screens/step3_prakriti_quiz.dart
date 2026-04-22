import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/onboarding_models.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

// ── 24 Prakriti Questions ─────────────────────────────────────────────────────

class PrakritiQuestion {
  final String id;
  final String domain;
  final String domainLabel;
  final String question;
  final List<PrakritiOption> options;

  const PrakritiQuestion({
    required this.id,
    required this.domain,
    required this.domainLabel,
    required this.question,
    required this.options,
  });
}

class PrakritiOption {
  final String text;
  final String dosha; // "vata" | "pitta" | "kapha"
  final IconData icon;

  const PrakritiOption({
    required this.text,
    required this.dosha,
    required this.icon,
  });
}

const _questions = [
  // DOMAIN 1 — PHYSIQUE
  PrakritiQuestion(
    id: 'Q1', domain: 'physique', domainLabel: 'Physique',
    question: 'What best describes your body build?',
    options: [
      PrakritiOption(text: 'Thin, light, hard to gain weight', dosha: 'vata', icon: Icons.airline_seat_recline_normal),
      PrakritiOption(text: 'Medium, muscular, maintain weight easily', dosha: 'pitta', icon: Icons.fitness_center),
      PrakritiOption(text: 'Large frame, tend to gain weight easily', dosha: 'kapha', icon: Icons.accessibility_new),
    ],
  ),
  PrakritiQuestion(
    id: 'Q2', domain: 'physique', domainLabel: 'Physique',
    question: 'How would you describe your skin?',
    options: [
      PrakritiOption(text: 'Dry, rough, or thin with prominent veins', dosha: 'vata', icon: Icons.texture),
      PrakritiOption(text: 'Warm, oily, prone to redness or acne', dosha: 'pitta', icon: Icons.local_fire_department),
      PrakritiOption(text: 'Smooth, thick, soft, tends to be pale', dosha: 'kapha', icon: Icons.water_drop),
    ],
  ),
  PrakritiQuestion(
    id: 'Q3', domain: 'physique', domainLabel: 'Physique',
    question: 'What is your hair like?',
    options: [
      PrakritiOption(text: 'Dry, brittle, frizzy, or thin', dosha: 'vata', icon: Icons.air),
      PrakritiOption(text: 'Fine, oily, early greying or thinning', dosha: 'pitta', icon: Icons.whatshot),
      PrakritiOption(text: 'Thick, oily, wavy, and lustrous', dosha: 'kapha', icon: Icons.waves),
    ],
  ),
  PrakritiQuestion(
    id: 'Q4', domain: 'physique', domainLabel: 'Physique',
    question: 'How do your eyes look?',
    options: [
      PrakritiOption(text: 'Small, dry, nervous or active gaze', dosha: 'vata', icon: Icons.remove_red_eye),
      PrakritiOption(text: 'Medium, sharp, penetrating, reddish', dosha: 'pitta', icon: Icons.visibility),
      PrakritiOption(text: 'Large, calm, beautiful, slightly moist', dosha: 'kapha', icon: Icons.circle_outlined),
    ],
  ),
  PrakritiQuestion(
    id: 'Q5', domain: 'physique', domainLabel: 'Physique',
    question: 'What describes your joints?',
    options: [
      PrakritiOption(text: 'Prominent, crack or pop often', dosha: 'vata', icon: Icons.broken_image),
      PrakritiOption(text: 'Loose, flexible, moderate', dosha: 'pitta', icon: Icons.sync_alt),
      PrakritiOption(text: 'Large, well-lubricated, stable', dosha: 'kapha', icon: Icons.anchor),
    ],
  ),
  PrakritiQuestion(
    id: 'Q6', domain: 'physique', domainLabel: 'Physique',
    question: 'How is your body temperature?',
    options: [
      PrakritiOption(text: 'Cold hands/feet, prefer warmth', dosha: 'vata', icon: Icons.ac_unit),
      PrakritiOption(text: 'Warm body, prefer cool environments', dosha: 'pitta', icon: Icons.wb_sunny),
      PrakritiOption(text: 'Comfortable in most temperatures', dosha: 'kapha', icon: Icons.thermostat),
    ],
  ),
  // DOMAIN 2 — METABOLISM
  PrakritiQuestion(
    id: 'Q7', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How is your appetite?',
    options: [
      PrakritiOption(text: 'Irregular — sometimes ravenous, sometimes forget to eat', dosha: 'vata', icon: Icons.schedule),
      PrakritiOption(text: 'Strong — get irritable if meals are skipped', dosha: 'pitta', icon: Icons.local_dining),
      PrakritiOption(text: 'Steady but low — can easily skip a meal', dosha: 'kapha', icon: Icons.hourglass_empty),
    ],
  ),
  PrakritiQuestion(
    id: 'Q8', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How do you digest food?',
    options: [
      PrakritiOption(text: 'Variable — sometimes fine, sometimes bloated or gassy', dosha: 'vata', icon: Icons.warning_amber),
      PrakritiOption(text: 'Fast — feel warm/flushed after meals, acidity-prone', dosha: 'pitta', icon: Icons.flash_on),
      PrakritiOption(text: 'Slow — feel heavy after meals, sluggish digestion', dosha: 'kapha', icon: Icons.snooze),
    ],
  ),
  PrakritiQuestion(
    id: 'Q9', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How are your bowel movements?',
    options: [
      PrakritiOption(text: 'Irregular, tend toward constipation', dosha: 'vata', icon: Icons.remove_circle_outline),
      PrakritiOption(text: 'Regular, loose, sometimes diarrhea when stressed', dosha: 'pitta', icon: Icons.speed),
      PrakritiOption(text: 'Regular, slow, heavy', dosha: 'kapha', icon: Icons.timer_outlined),
    ],
  ),
  PrakritiQuestion(
    id: 'Q10', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How much do you sweat?',
    options: [
      PrakritiOption(text: 'Minimal sweat, skin tends to be dry', dosha: 'vata', icon: Icons.invert_colors_off),
      PrakritiOption(text: 'Profuse sweat, strong body odor', dosha: 'pitta', icon: Icons.opacity),
      PrakritiOption(text: 'Moderate sweat, cool and pleasant', dosha: 'kapha', icon: Icons.water),
    ],
  ),
  PrakritiQuestion(
    id: 'Q11', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How do you sleep?',
    options: [
      PrakritiOption(text: 'Light sleeper, wake easily, less than 6 hours often', dosha: 'vata', icon: Icons.nightlight_round),
      PrakritiOption(text: 'Moderate — fall asleep easily but wake if stressed', dosha: 'pitta', icon: Icons.bed),
      PrakritiOption(text: 'Deep, long sleeper — hard to wake up in morning', dosha: 'kapha', icon: Icons.king_bed),
    ],
  ),
  PrakritiQuestion(
    id: 'Q12', domain: 'metabolism', domainLabel: 'Metabolism',
    question: 'How is your energy?',
    options: [
      PrakritiOption(text: 'Bursts of energy followed by exhaustion', dosha: 'vata', icon: Icons.bolt),
      PrakritiOption(text: 'Sustained moderate energy, competitive', dosha: 'pitta', icon: Icons.trending_up),
      PrakritiOption(text: 'Slow to start but steady and strong endurance', dosha: 'kapha', icon: Icons.linear_scale),
    ],
  ),
  // DOMAIN 3 — PSYCHOLOGICAL
  PrakritiQuestion(
    id: 'Q13', domain: 'psychological', domainLabel: 'Mind',
    question: 'How is your memory?',
    options: [
      PrakritiOption(text: 'Quick to learn, quick to forget', dosha: 'vata', icon: Icons.flash_auto),
      PrakritiOption(text: 'Sharp, focused, remember details well', dosha: 'pitta', icon: Icons.psychology),
      PrakritiOption(text: 'Slow to learn, but remember for a long time', dosha: 'kapha', icon: Icons.save),
    ],
  ),
  PrakritiQuestion(
    id: 'Q14', domain: 'psychological', domainLabel: 'Mind',
    question: 'How do you make decisions?',
    options: [
      PrakritiOption(text: 'Change your mind often, indecisive', dosha: 'vata', icon: Icons.shuffle),
      PrakritiOption(text: 'Decisive, can be stubborn', dosha: 'pitta', icon: Icons.check_circle),
      PrakritiOption(text: 'Slow to decide but very consistent', dosha: 'kapha', icon: Icons.hourglass_full),
    ],
  ),
  PrakritiQuestion(
    id: 'Q15', domain: 'psychological', domainLabel: 'Mind',
    question: 'Under stress, you tend to:',
    options: [
      PrakritiOption(text: 'Worry, feel anxious, panic', dosha: 'vata', icon: Icons.crisis_alert),
      PrakritiOption(text: 'Get irritable, angry, sharp-tongued', dosha: 'pitta', icon: Icons.whatshot),
      PrakritiOption(text: 'Withdraw, become quiet, overeat', dosha: 'kapha', icon: Icons.self_improvement),
    ],
  ),
  PrakritiQuestion(
    id: 'Q16', domain: 'psychological', domainLabel: 'Mind',
    question: 'How is your mind usually?',
    options: [
      PrakritiOption(text: 'Active, creative, lots of ideas, hard to focus', dosha: 'vata', icon: Icons.lightbulb_outline),
      PrakritiOption(text: 'Sharp, organized, goal-oriented', dosha: 'pitta', icon: Icons.bar_chart),
      PrakritiOption(text: 'Calm, steady, content, slow-paced', dosha: 'kapha', icon: Icons.spa),
    ],
  ),
  PrakritiQuestion(
    id: 'Q17', domain: 'psychological', domainLabel: 'Mind',
    question: 'How are your emotions?',
    options: [
      PrakritiOption(text: 'Fluctuating — quickly happy, quickly anxious', dosha: 'vata', icon: Icons.swap_vert),
      PrakritiOption(text: 'Intense — passionate, can flare up', dosha: 'pitta', icon: Icons.local_fire_department),
      PrakritiOption(text: 'Stable — slow to upset, slow to recover', dosha: 'kapha', icon: Icons.anchor),
    ],
  ),
  PrakritiQuestion(
    id: 'Q18', domain: 'psychological', domainLabel: 'Mind',
    question: 'How is your speech?',
    options: [
      PrakritiOption(text: 'Fast, talkative, jump topics quickly', dosha: 'vata', icon: Icons.record_voice_over),
      PrakritiOption(text: 'Precise, articulate, assertive', dosha: 'pitta', icon: Icons.mic),
      PrakritiOption(text: 'Slow, rhythmic, thoughtful', dosha: 'kapha', icon: Icons.slow_motion_video),
    ],
  ),
  // DOMAIN 4 — BEHAVIOURAL
  PrakritiQuestion(
    id: 'Q19', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'How often do you feel cold when others are comfortable?',
    options: [
      PrakritiOption(text: 'Very often', dosha: 'vata', icon: Icons.ac_unit),
      PrakritiOption(text: 'Rarely — usually too warm', dosha: 'pitta', icon: Icons.wb_sunny),
      PrakritiOption(text: 'Sometimes — prefer stable temperature', dosha: 'kapha', icon: Icons.device_thermostat),
    ],
  ),
  PrakritiQuestion(
    id: 'Q20', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'How is your daily routine?',
    options: [
      PrakritiOption(text: 'Irregular — wake, eat, sleep at different times', dosha: 'vata', icon: Icons.shuffle),
      PrakritiOption(text: 'Structured — have a plan, stick to schedule', dosha: 'pitta', icon: Icons.calendar_today),
      PrakritiOption(text: 'Consistent — same routine daily, resistant to change', dosha: 'kapha', icon: Icons.repeat),
    ],
  ),
  PrakritiQuestion(
    id: 'Q21', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'How do you handle physical activity?',
    options: [
      PrakritiOption(text: 'Love it in bursts, tire quickly', dosha: 'vata', icon: Icons.directions_run),
      PrakritiOption(text: 'Push hard, competitive, can overdo it', dosha: 'pitta', icon: Icons.sports),
      PrakritiOption(text: 'Slow to start, but build stamina over time', dosha: 'kapha', icon: Icons.directions_walk),
    ],
  ),
  PrakritiQuestion(
    id: 'Q22', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'How is your voice?',
    options: [
      PrakritiOption(text: 'Thin, high-pitched, soft, crackly', dosha: 'vata', icon: Icons.volume_up),
      PrakritiOption(text: 'Sharp, clear, commanding', dosha: 'pitta', icon: Icons.graphic_eq),
      PrakritiOption(text: 'Deep, resonant, smooth', dosha: 'kapha', icon: Icons.surround_sound),
    ],
  ),
  PrakritiQuestion(
    id: 'Q23', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'What weather makes you feel worst?',
    options: [
      PrakritiOption(text: 'Cold and dry wind', dosha: 'vata', icon: Icons.air),
      PrakritiOption(text: 'Hot, humid summer', dosha: 'pitta', icon: Icons.wb_sunny_outlined),
      PrakritiOption(text: 'Cold, damp, cloudy', dosha: 'kapha', icon: Icons.cloud),
    ],
  ),
  PrakritiQuestion(
    id: 'Q24', domain: 'behavioural', domainLabel: 'Behaviour',
    question: 'Your relationship with food?',
    options: [
      PrakritiOption(text: 'Snack often, irregular meals, forget to eat sometimes', dosha: 'vata', icon: Icons.cookie),
      PrakritiOption(text: 'Eat on time, get hangry if meals are late', dosha: 'pitta', icon: Icons.alarm),
      PrakritiOption(text: 'Eat moderately, could easily skip a meal', dosha: 'kapha', icon: Icons.eco),
    ],
  ),
];

class Step3PrakritiQuiz extends ConsumerStatefulWidget {
  const Step3PrakritiQuiz({super.key});

  @override
  ConsumerState<Step3PrakritiQuiz> createState() => _Step3PrakritiQuizState();
}

class _Step3PrakritiQuizState extends ConsumerState<Step3PrakritiQuiz> {
  int _currentQuestion = 0;
  final Map<String, String> _answers = {}; // questionId → dosha

  bool get _isAnswered => _answers.containsKey(_questions[_currentQuestion].id);
  bool get _isLastQuestion => _currentQuestion == _questions.length - 1;

  Color _doshaColor(String dosha) {
    switch (dosha) {
      case 'vata': return AyushColors.vata;
      case 'pitta': return AyushColors.pitta;
      case 'kapha': return AyushColors.kapha;
      default: return AyushColors.primary;
    }
  }

  Color _doshaBgColor(String dosha) {
    switch (dosha) {
      case 'vata': return AyushColors.vataLight;
      case 'pitta': return AyushColors.pittaLight;
      case 'kapha': return AyushColors.kaphaLight;
      default: return AyushColors.primarySurface;
    }
  }

  void _selectAnswer(String dosha) {
    HapticFeedback.lightImpact();
    setState(() {
      _answers[_questions[_currentQuestion].id] = dosha;
    });
  }

  Future<void> _nextQuestion() async {
    if (!_isAnswered) return;

    if (!_isLastQuestion) {
      setState(() => _currentQuestion++);
      return;
    }

    // All answered — submit
    final answers = _answers.entries
        .map((e) => PrakritiAnswer(questionId: e.key, selectedDosha: e.value))
        .toList();

    // Submit all answers to the notifier
    for (final a in answers) {
      ref.read(onboardingProvider.notifier).addPrakritiAnswer(a);
    }

    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      await ref.read(onboardingProvider.notifier).submitStep3(userId);
      if (mounted) context.go('/onboarding/3');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please retry.')),
        );
      }
    }
  }

  void _prevQuestion() {
    if (_currentQuestion > 0) setState(() => _currentQuestion--);
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final selectedDosha = _answers[question.id];
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return OnboardingShell(
      currentStep: 2,
      onBack: _currentQuestion > 0 ? _prevQuestion : null,
      child: Stack(
        children: [
          Column(
            children: [
              // ── Question counter ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, AyushSpacing.lg,
                  AyushSpacing.pagePadding, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AyushColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                          ),
                          child: Text(
                            '${question.domainLabel} · ${_currentQuestion + 1} / ${_questions.length}',
                            style: AyushTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AyushColors.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Mini domain progress
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (_currentQuestion + 1) / _questions.length,
                              minHeight: 4,
                              backgroundColor: AyushColors.divider,
                              valueColor: const AlwaysStoppedAnimation<Color>(AyushColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        question.question,
                        key: ValueKey(question.id),
                        style: AyushTextStyles.h2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Options ──────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(question.id),
                      children: question.options.asMap().entries.map((entry) {
                        final option = entry.value;
                        final isSelected = selectedDosha == option.dosha;
                        final dotColor = _doshaColor(option.dosha);
                        final bgColor = _doshaBgColor(option.dosha);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _selectAnswer(option.dosha),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? bgColor : AyushColors.card,
                                borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                                border: Border.all(
                                  color: isSelected ? dotColor : AyushColors.divider,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: dotColor.withOpacity(0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : AyushColors.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? dotColor.withOpacity(0.15)
                                          : AyushColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      option.icon,
                                      color: isSelected ? dotColor : AyushColors.textMuted,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      option.text,
                                      style: AyushTextStyles.bodyLarge.copyWith(
                                        color: isSelected
                                            ? AyushColors.textPrimary
                                            : AyushColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: dotColor, size: 22)
                                        .animate()
                                        .scale(begin: const Offset(0.5, 0.5), duration: 200.ms),
                                ],
                              ),
                            ),
                          ).animate(delay: (entry.key * 80).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),

          // ── Next / Submit button ──────────────────────────────────────────
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
                label: _isLastQuestion ? 'Calculate My Body Type' : 'Next Question',
                onPressed: _isAnswered ? _nextQuestion : null,
                isLoading: isLoading,
                icon: _isLastQuestion ? Icons.auto_awesome : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
