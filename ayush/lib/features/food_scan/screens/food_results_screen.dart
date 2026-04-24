import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/food_scan_provider.dart';
import '../models/food_analysis_result.dart';

class FoodResultsScreen extends ConsumerWidget {
  const FoodResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodScanProvider);
    final result = state.analysisResult;

    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get user prakriti
    final onboarding = ref.watch(onboardingProvider);
    final user = ref.watch(authProvider).value;
    final String prakritiType = () {
      final fromOnboarding = onboarding.prakritiResult?.dominant ?? '';
      if (fromOnboarding.isNotEmpty) return fromOnboarding;
      return user?.prakritiResult?['dominant']?.toString() ?? 'Vata'; // default fallback
    }();

    final totalOjasDelta = result.totalOjasDelta;
    final isPositive = totalOjasDelta >= 0;
    final warnings = result.viruddhaWarnings;
    final foods = result.foodResults;

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("Analysis Result", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Don't go back to audit
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AyushSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1 — OJAS Banner
                    Container(
                      padding: const EdgeInsets.all(AyushSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: isPositive ? AyushColors.herbalGradient : const LinearGradient(colors: [Colors.redAccent, Colors.red]),
                        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                        boxShadow: AyushColors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: totalOjasDelta.abs()),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) {
                              return Text(
                                "${isPositive ? '+' : '-'}$value OJAS",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AyushSpacing.sm),
                          const Text(
                            "Based on your meal quality",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AyushSpacing.xl),

                    // Section 2 — Viruddha Warning
                    if (warnings.isNotEmpty) ...[
                      Text("Warnings", style: AyushTextStyles.h3),
                      const SizedBox(height: AyushSpacing.sm),
                      ...warnings.map((w) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AyushSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                            side: const BorderSide(color: AyushColors.error, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AyushColors.error, size: 32),
                                const SizedBox(width: AyushSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: w.risk == 'Critical' ? AyushColors.error : Colors.orange,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              w.risk,
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              w.items.join(" + "),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AyushSpacing.xs),
                                      Text(w.reason, style: AyushTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AyushSpacing.xl),
                    ],

                    // Section 3 — Food Cards (ExpansionTiles)
                    Text("Food Details", style: AyushTextStyles.h3),
                    const SizedBox(height: AyushSpacing.sm),
                    ...foods.map((food) => _FoodExpansionTile(food: food, prakritiType: prakritiType)),
                  ],
                ),
              ),
            ),
            
            // Section 4 — Action Buttons
            Container(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              decoration: BoxDecoration(
                color: AyushColors.card,
                boxShadow: AyushColors.subtleShadow,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AyushSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              try {
                                await ref.read(foodScanProvider.notifier).logMeal();
                                await ref.read(authProvider.notifier).restoreSession();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Meal logged successfully!"), backgroundColor: AyushColors.success),
                                );
                                context.go('/home'); // Go to dashboard
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: AyushColors.error),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AyushColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                      ),
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Log This Meal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: AyushSpacing.sm),
                  TextButton(
                    onPressed: state.isLoading ? null : () => context.go('/home'),
                    child: const Text("Skip & Return to Dashboard"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodExpansionTile extends StatelessWidget {
  final FoodItemResult food;
  final String prakritiType;

  const _FoodExpansionTile({required this.food, required this.prakritiType});

  Color _getDoshaColor(String effect, Color baseColor) {
    if (effect == 'pacifies') return baseColor;
    if (effect == 'aggravates') return AyushColors.error;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isPositiveOjas = food.totalOjasDelta >= 0;
    final isAnswerPositive = food.auditOjasAdjustment >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AyushSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusMd)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AyushSpacing.sm),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    food.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositiveOjas ? AyushColors.herbalGreenLight : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${isPositiveOjas ? '+' : ''}${food.totalOjasDelta}",
                    style: TextStyle(
                      color: isPositiveOjas ? AyushColors.herbalGreen : AyushColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AyushSpacing.xs),
            // Row 2: Dosha Effects
            Row(
              children: [
                _MiniTag(text: "Vata", color: _getDoshaColor(food.vataEffect, AyushColors.vata)),
                const SizedBox(width: 4),
                _MiniTag(text: "Pitta", color: _getDoshaColor(food.pittaEffect, AyushColors.pitta)),
                const SizedBox(width: 4),
                _MiniTag(text: "Kapha", color: _getDoshaColor(food.kaphaEffect, AyushColors.kapha)),
              ],
            ),
            const SizedBox(height: AyushSpacing.xs),
            // Row 3: Virya, Vipaka, Digestibility
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _OutlinedTag(text: food.virya),
                _OutlinedTag(text: food.vipaka),
                _OutlinedTag(text: food.digestibility),
              ],
            ),
            const SizedBox(height: AyushSpacing.sm),
            // Row 4 & 5: Question and Answer
            Text(food.questionAsked, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              "Answer: ${food.answerGiven.toUpperCase()}", 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                color: isAnswerPositive ? AyushColors.success : AyushColors.error,
              )
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AyushSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section A — WHY
                if (food.reasoning.isNotEmpty) ...[
                  Text("WHY THIS MATTERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AyushColors.primary, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(food.reasoning, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: AyushSpacing.md),
                ],

                // Section B — Ojas Breakdown
                Row(
                  children: [
                    Expanded(child: _OjasStat("Base Ojas", food.baseOjasDelta)),
                    Expanded(child: _OjasStat("Adjustment", food.auditOjasAdjustment)),
                    Expanded(child: _OjasStat("Total", food.totalOjasDelta, isBold: true)),
                  ],
                ),
                const SizedBox(height: AyushSpacing.md),

                // Section C — Seasonal Advice
                if (food.idealSeasons.isNotEmpty || food.avoidSeasons.isNotEmpty) ...[
                  const Text("Seasonal Advice", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (food.idealSeasons.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: [
                        const Text("Best Seasons:", style: TextStyle(fontSize: 12)),
                        ...food.idealSeasons.map((s) => _SeasonalTag(text: s, isIdeal: true)),
                      ],
                    ),
                  if (food.avoidSeasons.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        const Text("Avoid In:", style: TextStyle(fontSize: 12)),
                        ...food.avoidSeasons.map((s) => _SeasonalTag(text: s, isIdeal: false)),
                      ],
                    ),
                  ],
                  if (food.rituacharyaReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(food.rituacharyaReason, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: AyushSpacing.md),
                ],

                // Section D — For Your Prakriti
                ..._buildPrakritiAdvice(),

                // Section E — Pair It Right
                if (food.pairingsIdeal.isNotEmpty || food.pairingsAvoid.isNotEmpty) ...[
                  const Text("Pairings", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (food.pairingsIdeal.isNotEmpty) ...[
                    const Text("Eat With:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...food.pairingsIdeal.take(3).map((p) => Row(children: [const Icon(Icons.check, color: AyushColors.success, size: 16), const SizedBox(width: 4), Expanded(child: Text(p, style: const TextStyle(fontSize: 13)))])),
                  ],
                  if (food.pairingsAvoid.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text("Avoid Pairing:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...food.pairingsAvoid.take(3).map((p) => Row(children: [const Icon(Icons.close, color: AyushColors.error, size: 16), const SizedBox(width: 4), Expanded(child: Text(p, style: const TextStyle(fontSize: 13)))])),
                  ],
                  const SizedBox(height: AyushSpacing.md),
                ],

                // Section F — Red Flags
                if (food.redFlags.isNotEmpty) ...[
                  const Text("⚠️ Watch For", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 4),
                  ...food.redFlags.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: AyushSpacing.md),
                ],

                // Section G — Health Conditions
                if (food.conditionWarnings.isNotEmpty) ...[
                  const Text("Health Notes", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...food.conditionWarnings.map((cw) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cw['condition'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(cw['advice'] ?? '', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrakritiAdvice() {
    String advice = '';
    Color bgColor = AyushColors.surfaceVariant;
    
    final pLower = prakritiType.toLowerCase();
    if (pLower.contains('vata')) {
      advice = food.prakritiAdviceVata;
      bgColor = AyushColors.vataLight;
    } else if (pLower.contains('pitta')) {
      advice = food.prakritiAdvicePitta;
      bgColor = AyushColors.pittaLight;
    } else if (pLower.contains('kapha')) {
      advice = food.prakritiAdviceKapha;
      bgColor = AyushColors.kaphaLight;
    }

    if (advice.isEmpty) return [];

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("For Your Prakriti ($prakritiType)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(advice, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      const SizedBox(height: AyushSpacing.md),
    ];
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _OutlinedTag extends StatelessWidget {
  final String text;

  const _OutlinedTag({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
    );
  }
}

class _SeasonalTag extends StatelessWidget {
  final String text;
  final bool isIdeal;

  const _SeasonalTag({required this.text, required this.isIdeal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isIdeal ? AyushColors.success : Colors.orange),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: isIdeal ? AyushColors.success : Colors.orange.shade800, 
          fontSize: 10
        )
      ),
    );
  }
}

class _OjasStat extends StatelessWidget {
  final String label;
  final int value;
  final bool isBold;

  const _OjasStat(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final valStr = "${value >= 0 ? '+' : ''}$value";
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          valStr, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: value >= 0 ? AyushColors.success : AyushColors.error,
          )
        ),
      ],
    );
  }
}
