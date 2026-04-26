import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../food_scan/providers/delayed_meal_provider.dart';
import '../../../food_scan/providers/food_scan_provider.dart';
import '../widgets/daily_checkin_card.dart';

import '../../../../mixins/mentor_guidance_mixin.dart';
import '../../../../services/mentor_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/mentor_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/mentor_messages.dart';
import '../../../../widgets/mentor_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with MentorGuidanceMixin {
  bool _mentorVisible = false;
  String? _mentorMessageKey;
  int? _deltaVal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final mentor = context.read<MentorNotifier>().currentMentor;
      await showMentorGuidanceIfFirstVisit(
        screenKey: 'log_screen',
        mentor: mentor,
        context: 'log_prompt',
      );
      
      await _checkMentorAlerts();
    });
  }

  Future<void> _checkMentorAlerts() async {
    final ojas = ref.read(onboardingProvider).ojasResult;
    final user = ref.read(authProvider).value;
    final int currentOjas = ojas?.ojasScore ?? user?.ojasScore ?? 0;
    
    if (currentOjas == 0) return; // not calculated yet
    
    final isFirst = await MentorService.isFirstVisit('home_ojas_alert');
    final prefs = await SharedPreferences.getInstance();
    final int? lastOjas = prefs.getInt('last_ojas_score');
    
    await prefs.setInt('last_ojas_score', currentOjas);
    
    if (isFirst) return;
    
    if (lastOjas != null) {
      final delta = currentOjas - lastOjas;
      if (delta <= -5 || delta >= 5) {
        if (mounted) {
          setState(() {
            _deltaVal = delta;
            _mentorMessageKey = delta <= -5 ? 'ojas_warning' : 'ojas_celebrating';
            _mentorVisible = true;
          });
        }
        return; // Prioritize Ojas alert over daily greeting
      }
    }

    // Daily greeting logic
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastGreeting = prefs.getString('last_greeting_date');
    if (lastGreeting != todayStr) {
      await prefs.setString('last_greeting_date', todayStr);
      final hour = DateTime.now().hour;
      String greetingKey = 'login_greeting_morning';
      if (hour >= 12 && hour < 17) greetingKey = 'login_greeting_afternoon';
      else if (hour >= 17) greetingKey = 'login_greeting_evening';

      if (mounted) {
        setState(() {
          _mentorMessageKey = greetingKey;
          _mentorVisible = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // Greeting logic
    final int hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) { greeting = "Good Afternoon"; }
    else if (hour >= 17 && hour < 21) { greeting = "Good Evening"; }
    else if (hour >= 21 || hour < 6) { greeting = "Rest well tonight"; }

    String ojasStatusPill = "❄️ Low";
    if (ojasScore > 70) ojasStatusPill = "🧘 Balanced";
    else if (ojasScore >= 50) ojasStatusPill = "⚡ Moderate";

    return Scaffold(
      backgroundColor: AyushColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── SECTION 1: APP BAR ────────────────────────────────────────────
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
                        const SizedBox(height: 2),
                        Text(
                          greeting,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
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

            // ── OJAS Mentor Alert ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: _mentorVisible && _mentorMessageKey != null
                    ? Builder(builder: (context) {
                        final mentor = context.watch<MentorNotifier>().currentMentor;
                        final msg = MentorMessages.get(
                          mentor: mentor,
                          context: _mentorMessageKey!,
                          data: _deltaVal != null ? {'delta': _deltaVal!.abs()} : const {},
                        );
                        if (msg.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: MentorWidget(
                            mentor: mentor,
                            message: msg,
                            dismissible: true,
                            onDismiss: () => setState(() => _mentorVisible = false),
                          ),
                        );
                      })
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),

            // ── SECTION 2: OJAS CARD + DAILY CHECKIN ──────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AyushSpacing.pagePadding, AyushSpacing.lg,
                AyushSpacing.pagePadding, 0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      onLongPress: () => showMentorExplanation(
                        context: context,
                        contextKey: 'explain_ojas_card',
                      ),
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
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (ojasScore > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                                          ),
                                          child: Text(
                                            ojasStatusPill,
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                      if (ojasScore > 0) const SizedBox(width: 8),
                                      if (dominantDosha.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                                          ),
                                          child: Text(
                                            '$dominantDosha Prakriti',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator.adaptive(
                                      value: ojasScore > 0 ? ojasScore / 100 : 0.0,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                      strokeWidth: 5,
                                    ),
                                  ),
                                  Text(
                                    ojasScore > 0 ? '$ojasScore' : '--',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AyushSpacing.xl),
                    GestureDetector(
                      onLongPress: () => showMentorExplanation(
                        context: context,
                        contextKey: 'explain_daily_checkin',
                      ),
                      child: const DailyCheckinCard(),
                    ),
                  ],
                ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn(),
              ),
            ),

            // ── SECTION 3: HEALTH RADAR BANNER ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, AyushSpacing.xl,
                  AyushSpacing.pagePadding, 0,
                ),
                child: GestureDetector(
                  onLongPress: () => showMentorExplanation(
                    context: context,
                    contextKey: 'explain_health_radar',
                  ),
                  onTap: () => context.push('/health-radar'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0d1f14), Color(0xFF1a3a2a)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2d6a4f)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF52b788),
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1200.ms),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "LIVE PREDICTION",
                                    style: TextStyle(fontSize: 10, color: Color(0xFF52b788), fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Health Radar",
                                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "See your OJAS prediction for next 3 days",
                                style: TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildHealthRadarPill("👁 Eye: Good"),
                            _buildHealthRadarPill("🫦 Tongue: Check"),
                            _buildHealthRadarPill("💓 HR: 72 bpm"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),
              ),
            ),

            // ── SECTION 4: MORNING DIAGNOSTICS ────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader("Morning Diagnostics", "Daily biomarker check-in")
                  .animate(delay: 300.ms).fadeIn(),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                child: Row(
                  children: [
                    _buildDiagnosticCard(
                      contextKey: 'explain_tongue_scan',
                      route: '/tongue-capture',
                      bgColor: Colors.pink.shade50,
                      iconColor: Colors.pinkAccent,
                      icon: Icons.face_retouching_natural,
                      label: "Tongue\nScan",
                      sub: "Coating & Color",
                      pillText: "Daily",
                    ),
                    _buildDiagnosticCard(
                      contextKey: 'explain_eye_scan',
                      route: '/eye-capture',
                      bgColor: Colors.blue.shade50,
                      iconColor: Colors.blueAccent,
                      icon: Icons.remove_red_eye_outlined,
                      label: "Eye\nScan",
                      sub: "Sclera Analysis",
                      pillText: "Daily",
                    ),
                    _buildDiagnosticCard(
                      contextKey: 'explain_nadi_pariksha',
                      route: '/nadi-pariksha',
                      bgColor: const Color(0xFFFDEDEC),
                      iconColor: const Color(0xFFE74C3C),
                      icon: Icons.favorite_border,
                      label: "Nadi\nPariksha",
                      sub: "Heart Rate via PPG",
                      pillText: "Daily",
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.1),
            ),

            // ── SECTION 5: NUTRITION ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader("Nutrition", "Scan, analyze & eat right")
                  .animate(delay: 400.ms).fadeIn(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildNutritionCard(
                    contextKey: 'explain_food_scan',
                    route: '/food/scan',
                    color: AyushColors.herbalGreen,
                    bgColor: AyushColors.herbalGreenLight,
                    icon: Icons.camera_alt_outlined,
                    label: "Food Scan",
                    tagText: "YOLO AI",
                  ),
                  _buildNutritionCard(
                    contextKey: 'explain_label_scan',
                    route: '/packaged-food/scan',
                    color: const Color(0xFF6A1B9A),
                    bgColor: const Color(0xFFF3E5F5),
                    icon: Icons.qr_code_scanner,
                    label: "Label Scan",
                    tagText: "OCR",
                  ),
                  _buildNutritionCard(
                    contextKey: 'explain_ai_recipe',
                    route: '/recipe/select',
                    color: AyushColors.kapha,
                    bgColor: AyushColors.kaphaLight,
                    icon: Icons.restaurant_menu,
                    label: "AI Recipe",
                    tagText: "Gemini",
                  ),
                ],
              ),
            ),

            // ── SECTION 6: WELLNESS ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader("Wellness", "Move, breathe & restore")
                  .animate(delay: 500.ms).fadeIn(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onLongPress: () => showMentorExplanation(
                    context: context,
                    contextKey: 'explain_yoga',
                  ),
                  onTap: () => context.push('/yoga/home'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AyushColors.pittaLight, Colors.orange.shade50],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AyushColors.pitta.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Yoga Posture", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AyushColors.pitta)),
                              const Text("Real-time MediaPipe correction", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AyushColors.pitta,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text("Start Session →", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Opacity(
                            opacity: 0.6,
                            child: Icon(Icons.self_improvement, color: AyushColors.pitta, size: 72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 500.ms).fadeIn(),
              ),
            ),

            // ── SECTION 7: NATURE & COMMUNITY ─────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader("Nature & Community", "Explore plants, connect locally")
                  .animate(delay: 600.ms).fadeIn(),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildNutritionCard(
                    contextKey: 'explain_plant_id',
                    route: '/plant/camera',
                    color: Colors.teal,
                    bgColor: Colors.teal.shade50,
                    icon: Icons.eco_outlined,
                    label: "Plant ID",
                    tagText: "TFLite AI",
                  ),
                  _buildNutritionCard(
                    contextKey: 'explain_community',
                    route: '/community',
                    color: const Color(0xFF2d6a4f),
                    bgColor: const Color(0xFFe8f5e9),
                    icon: Icons.people_outline,
                    label: "Community",
                    tagText: "Geolocated",
                  ),
                ],
              ),
            ),

            // ── SECTION 8: BOTTOM SPACING ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPER METHODS ────────────────────────────────────────────────────────
  Widget _buildHealthRadarPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0d2818),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF52b788)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AyushSpacing.pagePadding, AyushSpacing.lg, AyushSpacing.pagePadding, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AyushColors.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCard({
    required String contextKey,
    required String route,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required String label,
    required String sub,
    required String pillText,
  }) {
    return GestureDetector(
      onLongPress: () => showMentorExplanation(context: context, contextKey: contextKey),
      onTap: () => context.push(route),
      child: Container(
        width: 140,
        height: 160,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: iconColor.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(pillText, style: TextStyle(fontSize: 9, color: iconColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: iconColor)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard({
    required String contextKey,
    required String route,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String label,
    required String tagText,
  }) {
    return GestureDetector(
      onLongPress: () => showMentorExplanation(context: context, contextKey: contextKey),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 26),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tagText, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
