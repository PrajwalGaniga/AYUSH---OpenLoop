import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/onboarding_models.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

class OjasRevealScreen extends ConsumerStatefulWidget {
  const OjasRevealScreen({super.key});

  @override
  ConsumerState<OjasRevealScreen> createState() => _OjasRevealScreenState();
}

class _OjasRevealScreenState extends ConsumerState<OjasRevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _countController;
  late AnimationController _dosha1Controller;
  late AnimationController _dosha2Controller;
  late AnimationController _dosha3Controller;

  OjasResult? _result;
  PrakritiResult? _prakriti;

  @override
  void initState() {
    super.initState();

    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _dosha1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dosha2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dosha3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _result = ref.read(onboardingProvider).ojasResult;
      _prakriti = ref.read(onboardingProvider).prakritiResult;
      setState(() {});

      Future.delayed(const Duration(milliseconds: 500), () {
        _gaugeController.forward();
        _countController.forward();
      });
      Future.delayed(const Duration(milliseconds: 1200), () => _dosha1Controller.forward());
      Future.delayed(const Duration(milliseconds: 1400), () => _dosha2Controller.forward());
      Future.delayed(const Duration(milliseconds: 1600), () => _dosha3Controller.forward());
    });
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _countController.dispose();
    _dosha1Controller.dispose();
    _dosha2Controller.dispose();
    _dosha3Controller.dispose();
    super.dispose();
  }

  int get _ojasScore => _result?.ojasScore ?? 72;

  Color get _ojasColor {
    if (_ojasScore >= 80) return AyushColors.ojasExcellent;
    if (_ojasScore >= 60) return AyushColors.ojasGood;
    if (_ojasScore >= 40) return AyushColors.ojasAttention;
    return AyushColors.ojasCritical;
  }

  String get _ojasLabel {
    if (_ojasScore >= 80) return 'Excellent Vitality';
    if (_ojasScore >= 60) return 'Good Vitality';
    if (_ojasScore >= 40) return 'Needs Attention';
    return 'Critical — Action Needed';
  }

  String get _dominantDosha => _prakriti?.dominant ?? 'Vata';
  String get _prakritiType => _prakriti?.type ?? 'Vata-Pitta';
  Map<String, int> get _doshaScores => _prakriti?.scores ?? {'vata': 40, 'pitta': 35, 'kapha': 25};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle top teal accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AyushColors.primaryDark.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AyushSpacing.pagePadding, AyushSpacing.pageTopPadding,
                AyushSpacing.pagePadding, AyushSpacing.xxxl,
              ),
              child: Column(
                children: [
                  // ── Headline ────────────────────────────────────────────────
                  Text('Your OJAS Score', style: AyushTextStyles.h2)
                      .animate(delay: 200.ms).fadeIn(duration: 600.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Vitality score based on your complete health profile',
                    style: AyushTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate(delay: 300.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 40),

                  // ── OJAS Gauge ──────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _gaugeController,
                    builder: (ctx, _) {
                      final progress = CurvedAnimation(
                        parent: _gaugeController,
                        curve: Curves.easeOutCubic,
                      ).value;
                      final currentScore = (_ojasScore * progress).round();

                      return Column(
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: CustomPaint(
                              painter: _OjasGaugePainter(
                                progress: progress * (_ojasScore / 100),
                                color: _ojasColor,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$currentScore',
                                      style: AyushTextStyles.ojasScore.copyWith(
                                        color: _ojasColor,
                                      ),
                                    ),
                                    Text(
                                      'out of 100',
                                      style: AyushTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: _ojasColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                              border: Border.all(color: _ojasColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              _ojasLabel,
                              style: AyushTextStyles.labelMedium.copyWith(color: _ojasColor),
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate(delay: 400.ms).fadeIn(duration: 800.ms),

                  const SizedBox(height: 40),

                  // ── Prakriti type ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AyushColors.card,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                      border: Border.all(color: AyushColors.divider),
                      boxShadow: AyushColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AyushColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.self_improvement, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Prakriti', style: AyushTextStyles.labelSmall),
                                Text(_prakritiType, style: AyushTextStyles.h3),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dosha bars
                        _buildDoshaBar('Vata', _doshaScores['vata'] ?? 0, AyushColors.vata, _dosha1Controller),
                        const SizedBox(height: 12),
                        _buildDoshaBar('Pitta', _doshaScores['pitta'] ?? 0, AyushColors.pitta, _dosha2Controller),
                        const SizedBox(height: 12),
                        _buildDoshaBar('Kapha', _doshaScores['kapha'] ?? 0, AyushColors.kapha, _dosha3Controller),
                      ],
                    ),
                  ).animate(delay: 1000.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  // ── Insight cards ───────────────────────────────────────────
                  _buildInsightCard(
                    icon: Icons.person_outline,
                    color: AyushColors.vata,
                    title: 'Your dominant dosha is $_dominantDosha',
                    body: _doshaInsight(_dominantDosha),
                    delay: 1200,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.monitor_heart_outlined,
                    color: _ojasColor,
                    title: 'OJAS is ${_ojasScore >= 60 ? 'Good' : 'Needs Attention'}',
                    body: 'Your vitality score reflects your lifestyle, health conditions, and habits. '
                        '${_ojasScore >= 60 ? 'Keep up the great work!' : 'Small daily changes can significantly boost your score.'}',
                    delay: 1400,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightCard(
                    icon: Icons.spa_outlined,
                    color: AyushColors.herbalGreen,
                    title: 'Personalized recommendations ready',
                    body: 'Based on your profile, AYUSH has curated Ayurvedic diet, lifestyle, '
                        'and herb recommendations specifically for your constitution.',
                    delay: 1600,
                  ),

                  const SizedBox(height: 32),

                  // ── Disclaimer ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AyushColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                    ),
                    child: Text(
                      '⚕️ This OJAS score is a wellness indicator, not a medical diagnosis. '
                      'Consult a qualified practitioner for medical advice.',
                      style: AyushTextStyles.caption.copyWith(color: AyushColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ).animate(delay: 1800.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 24),

                  // ── CTA ─────────────────────────────────────────────────────
                  AyushButton(
                    label: 'Begin Your Journey',
                    onPressed: () => context.go('/home'),
                    icon: Icons.arrow_forward_rounded,
                  ).animate(delay: 2000.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaBar(String name, int score, Color color, AnimationController ctrl) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final progress = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic).value;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: AyushTextStyles.labelSmall),
                Text('${(score * progress).round()}%',
                    style: AyushTextStyles.labelSmall.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100) * progress,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
      decoration: BoxDecoration(
        color: AyushColors.card,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: AyushColors.subtleShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AyushTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(body, style: AyushTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  String _doshaInsight(String dosha) {
    switch (dosha.toLowerCase()) {
      case 'vata':
        return 'Vata types are creative, quick, and energetic — but can be prone to anxiety and irregularity. '
            'Warm foods, routine, and grounding practices are key for you.';
      case 'pitta':
        return 'Pitta types are driven, intelligent, and sharp — but can be prone to inflammation and irritability. '
            'Cooling foods, moderation, and stress management are essential.';
      case 'kapha':
        return 'Kapha types are strong, calm, and nurturing — but can be prone to lethargy and weight gain. '
            'Stimulating foods, exercise, and variety keep you balanced.';
      default:
        return 'A balanced constitution reflects harmony across all three doshas. Focus on maintaining your current lifestyle.';
    }
  }
}

// ── OJAS gauge painter ────────────────────────────────────────────────────────

class _OjasGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _OjasGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Track background
    final trackPaint = Paint()
      ..color = AyushColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.8,
      pi * 1.6,
      false,
      trackPaint,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      // Gradient-ish effect — draw multiple arcs
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.8,
        pi * 1.6 * progress,
        false,
        progressPaint,
      );

      // Glow
      final glowPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.8,
        pi * 1.6 * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OjasGaugePainter old) =>
      old.progress != progress || old.color != color;
}
