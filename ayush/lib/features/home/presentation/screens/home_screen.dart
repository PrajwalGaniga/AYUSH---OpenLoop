import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../food_scan/providers/delayed_meal_provider.dart';
import '../../../food_scan/providers/food_scan_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final onboarding = ref.watch(onboardingProvider);
    final prakriti = onboarding.prakritiResult;
    final ojas = onboarding.ojasResult;

    ref.listen<DelayedMealState>(delayedMealProvider, (previous, next) {
      if (next.isTimerComplete && next.pendingScan != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Reaction Check!"),
            content: const Text("Did you eat the hotel food you scanned 2 hours ago?"),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(delayedMealProvider.notifier).clearPending();
                  Navigator.pop(ctx);
                },
                child: const Text("No, I didn't"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AyushColors.primary),
                onPressed: () {
                  final state = next.pendingScan!;
                  ref.read(delayedMealProvider.notifier).clearPending();
                  ref.read(foodScanProvider.notifier).resumeState(state);
                  Navigator.pop(ctx);
                  context.push('/food/audit');
                },
                child: const Text("Yes, I ate it", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    });

    // ── Name resolution ───────────────────────────────────────────────────────
    // Priority: onboarding state (fresh registration this session)
    //           → profile from server (login / session restore)
    //           → fallback 'Friend'
    final String name = () {
      final fromOnboarding = onboarding.fullName;
      if (fromOnboarding != null && fromOnboarding.trim().isNotEmpty) {
        return fromOnboarding.trim();
      }
      final fromProfile = user?.profile?['fullName']?.toString().trim() ?? '';
      if (fromProfile.isNotEmpty) return fromProfile;
      return 'Friend';
    }();

    // ── OJAS score resolution ─────────────────────────────────────────────────
    // Priority: live onboarding result (just completed onboarding this session)
    //           → server value persisted in UserModel (login / session restore)
    //           → 0 (triggers "Complete onboarding" prompt)
    final int ojasScore = ojas?.ojasScore ?? user?.ojasScore ?? 0;

    // ── Prakriti resolution ───────────────────────────────────────────────────
    // Same layered priority as OJAS score
    final String dominantDosha = () {
      final fromOnboarding = prakriti?.dominant ?? '';
      if (fromOnboarding.isNotEmpty) return fromOnboarding;
      return user?.prakritiResult?['dominant']?.toString() ?? '';
    }();

    Color ojasColor = AyushColors.ojasGood;
    if (ojasScore >= 80) ojasColor = AyushColors.ojasExcellent;
    else if (ojasScore >= 60) ojasColor = AyushColors.ojasGood;
    else if (ojasScore >= 40) ojasColor = AyushColors.ojasAttention;
    else if (ojasScore > 0) ojasColor = AyushColors.ojasCritical;

    return Scaffold(
      backgroundColor: AyushColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AyushSpacing.pagePadding, AyushSpacing.lg,
                AyushSpacing.pagePadding, 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Namaste 🙏',
                          style: AyushTextStyles.bodySmall.copyWith(color: AyushColors.primary),
                        ),
                        Text(name, style: AyushTextStyles.h2),
                      ],
                    ).animate().fadeIn(duration: 500.ms),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                        IconButton(
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          },
                          icon: const Icon(Icons.logout_outlined, color: AyushColors.textMuted),
                        ),
                      ],
                    ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
                  ],
                ),
              ),
            ),

            // ── OJAS Card ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AyushSpacing.pagePadding, AyushSpacing.lg,
                AyushSpacing.pagePadding, 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                  decoration: BoxDecoration(
                    gradient: AyushColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your OJAS Score',
                              style: AyushTextStyles.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ojasScore > 0 ? '$ojasScore / 100' : 'Complete onboarding',
                              style: AyushTextStyles.h1.copyWith(color: Colors.white),
                            ),
                            if (dominantDosha.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                                ),
                                child: Text(
                                  '$dominantDosha Prakriti',
                                  style: AyushTextStyles.labelSmall.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.spa_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AyushSpacing.pagePadding, AyushSpacing.lg,
                AyushSpacing.pagePadding, 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: AyushTextStyles.labelMedium),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildActionCard(context, 'My Prakriti', Icons.person_outline, AyushColors.vata, AyushColors.vataLight, () {}),
                        _buildActionCard(context, 'Food Scan', Icons.camera_alt_outlined, AyushColors.herbalGreen, AyushColors.herbalGreenLight, () => context.push('/food/scan')),
                        _buildActionCard(context, 'Herb Guide', Icons.eco_outlined, AyushColors.kapha, AyushColors.kaphaLight, () {}),
                        _buildActionCard(context, 'Track Health', Icons.monitor_heart_outlined, AyushColors.pitta, AyushColors.pittaLight, () {}),
                      ],
                    ),
                  ],
                ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
              ),
            ),

            // ── Coming soon ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AyushColors.sandDark,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    border: Border.all(color: AyushColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AyushColors.gold, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Module 2 Coming Soon', style: AyushTextStyles.labelMedium),
                            Text(
                              'AI health consultations, personalized herb recommendations, and daily wellness tracking.',
                              style: AyushTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String label, IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: AyushTextStyles.labelMedium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
