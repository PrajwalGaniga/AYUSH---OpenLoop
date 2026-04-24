import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            
            Container(
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

            const SizedBox(height: AyushSpacing.xl),

            // Dominant Dosha Card
            Container(
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
}
