import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../../sos/sos_settings_screen.dart';
import '../../../../mixins/mentor_guidance_mixin.dart';
import '../../../../services/mentor_service.dart';
import '../../../../models/mentor_type.dart';
import 'package:provider/provider.dart';
import '../../../../providers/mentor_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with MentorGuidanceMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final mentor = context.read<MentorNotifier>().currentMentor;
      await showMentorGuidanceIfFirstVisit(
        screenKey: 'health_radar',
        mentor: mentor,
        context: 'health_radar_intro',
      );
      await showMentorGuidanceIfFirstVisit(
        screenKey: 'prakriti_screen',
        mentor: mentor,
        context: 'prakriti_intro',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AyushColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = user.profile ?? {};
    final prakriti = user.prakritiResult ?? {};
    final scores = prakriti['scores'] as Map<String, dynamic>? ?? {'vata': 0, 'pitta': 0, 'kapha': 0};

    final double vata = (scores['vata'] as num?)?.toDouble() ?? 0;
    final double pitta = (scores['pitta'] as num?)?.toDouble() ?? 0;
    final double kapha = (scores['kapha'] as num?)?.toDouble() ?? 0;

    final String dominant = prakriti['dominant']?.toString() ?? 'Unknown';
    final String fullName = profile['fullName']?.toString() ?? 'Guest User';
    final String age = profile['age']?.toString() ?? '--';
    final String gender = profile['gender']?.toString() ?? '--';

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Prakriti Profile', style: AyushTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AyushColors.textSecondary),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SosSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AyushColors.primary),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AyushSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Intro Card
            Container(
              padding: const EdgeInsets.all(AyushSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                boxShadow: AyushColors.subtleShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AyushColors.primary.withOpacity(0.1),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: AyushTextStyles.h1.copyWith(color: AyushColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, style: AyushTextStyles.h2),
                        const SizedBox(height: 4),
                        Text('$age yrs • $gender', style: AyushTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: AyushSpacing.xl),

            // Radar Chart Section
            Text('Dosha Balance', style: AyushTextStyles.h2),
            const SizedBox(height: AyushSpacing.lg),
            
            GestureDetector(
              onLongPress: () => showMentorExplanation(
                context: context,
                contextKey: 'explain_dosha_radar',
              ),
              child: Container(
                height: 300,
                padding: const EdgeInsets.all(AyushSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                boxShadow: AyushColors.subtleShadow,
              ),
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 3,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  titlePositionPercentageOffset: 0.2,
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return const RadarChartTitle(text: 'Vata', angle: 0);
                      case 1:
                        return const RadarChartTitle(text: 'Pitta', angle: 0);
                      case 2:
                        return const RadarChartTitle(text: 'Kapha', angle: 0);
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: AyushColors.primary.withOpacity(0.4),
                      borderColor: AyushColors.primary,
                      entryRadius: 4,
                      dataEntries: [
                        RadarEntry(value: vata),
                        RadarEntry(value: pitta),
                        RadarEntry(value: kapha),
                      ],
                    ),
                  ],
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutBack,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(),
            ),

            const SizedBox(height: AyushSpacing.xl),

            // Dominant Dosha Card
            GestureDetector(
              onLongPress: () => showMentorExplanation(
                context: context,
                contextKey: 'explain_dominant_prakriti',
              ),
              child: Container(
                padding: const EdgeInsets.all(AyushSpacing.lg),
              decoration: BoxDecoration(
                gradient: AyushColors.primaryGradient,
                borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dominant Prakriti',
                    style: AyushTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dominant.toUpperCase()} DOSHA',
                    style: AyushTextStyles.h1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getDoshaDescription(dominant),
                    style: AyushTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: AyushSpacing.xl),

            // Physical Traits Summary
            Text('Basic Details', style: AyushTextStyles.h2),
            const SizedBox(height: AyushSpacing.md),
            Container(
              padding: const EdgeInsets.all(AyushSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                boxShadow: AyushColors.subtleShadow,
              ),
              child: Column(
                children: [
                  _buildDetailRow('Height', '${profile['heightCm'] ?? '--'} cm'),
                  const Divider(height: 24),
                  _buildDetailRow('Weight', '${profile['weightKg'] ?? '--'} kg'),
                  const Divider(height: 24),
                  _buildDetailRow('Blood Group', profile['bloodGroup']?.toString() ?? '--'),
                  const Divider(height: 24),
                  _buildDetailRow('Language', profile['language']?.toString() ?? 'English'),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

            const SizedBox(height: AyushSpacing.xl),

            // Your Guide Section
            Text(
              'YOUR GUIDE',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AyushSpacing.md),
            Row(
              children: [
                _buildMentorTile(MentorType.rabbit),
                const SizedBox(width: 6),
                _buildMentorTile(MentorType.sloth),
              ],
            ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AyushTextStyles.bodyMedium.copyWith(color: AyushColors.textMuted)),
        Text(value, style: AyushTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _getDoshaDescription(String dosha) {
    if (dosha.toLowerCase().contains('vata')) {
      return 'Creative, energetic, and quick-moving. When balanced, you are lively and enthusiastic. When out of balance, you may experience anxiety or dry skin.';
    } else if (dosha.toLowerCase().contains('pitta')) {
      return 'Intelligent, goal-oriented, and passionate. When balanced, you are a strong leader. When out of balance, you may be irritable or prone to inflammation.';
    } else if (dosha.toLowerCase().contains('kapha')) {
      return 'Calm, loving, and grounded. When balanced, you are supportive and strong. When out of balance, you may feel sluggish or resistant to change.';
    }
    return 'Your unique mind-body constitution.';
  }

  Widget _buildMentorTile(MentorType mentor) {
    final currentMentor = context.watch<MentorNotifier>().currentMentor;
    final isSelected = currentMentor == mentor;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await MentorService.saveMentor(mentor);
          if (mounted) {
            context.read<MentorNotifier>().updateMentor(mentor);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${mentor.displayName} is now your guide.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: mentor.accentColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? mentor.accentColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? mentor.accentColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Lottie.asset(mentor.assetPath, repeat: true),
              ),
              const SizedBox(height: 4),
              Text(
                mentor.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? mentor.accentColor : Colors.grey.shade700,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: mentor.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
