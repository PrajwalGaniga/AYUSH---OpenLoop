import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/plant_provider.dart';
import '../data/plant_knowledge_service.dart';

class PlantResultScreen extends ConsumerStatefulWidget {
  final String plantKey;
  final double confidence;
  final File capturedImage;

  const PlantResultScreen({
    super.key,
    required this.plantKey,
    required this.confidence,
    required this.capturedImage,
  });

  @override
  ConsumerState<PlantResultScreen> createState() => _PlantResultScreenState();
}

class _PlantResultScreenState extends ConsumerState<PlantResultScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(plantProvider.notifier).selectPlant(widget.plantKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantProvider);
    final plant = state.selectedPlant;
    final prakriti = ref.watch(onboardingProvider).prakritiResult?.dominant?.toLowerCase() ?? 'vata';

    if (state.isLoading || plant == null) {
      return const Scaffold(
        backgroundColor: AyushColors.background,
        body: Center(child: CircularProgressIndicator(color: AyushColors.herbalGreen)),
      );
    }

    final rawSafety = PlantKnowledgeService.instance.getSafetyConfig(plant.safetyLevel);
    // Provide defaults if safety_level_config is missing from JSON
    final safetyConfig = rawSafety.isNotEmpty ? rawSafety : {
      'banner_color': '#2d6a4f',
      'banner_text': 'Generally safe — follow recommended doses',
      'icon': '✓',
    };
    final bannerColorHex = (safetyConfig['banner_color'] as String?)?.replaceAll('#', '0xFF') ?? '0xFF2d6a4f';
    final bannerColor = Color(int.parse(bannerColorHex));

    return Scaffold(
      backgroundColor: AyushColors.background,
      body: CustomScrollView(
        slivers: [
          // Section 0: Toxicity Banner (pinned at top)
          if (plant.toxicityWarning != null)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: plant.safetyLevel == 'toxic_expert_only' ? AyushColors.ojasCritical : Colors.amber.shade700,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plant.toxicityWarning!,
                          style: AyushTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Section 1: Hero Image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AyushColors.herbalGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              // Removed title from here to prevent duplicate name display
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Show the actual captured image as background
                  Image.file(
                    widget.capturedImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(gradient: AyushColors.herbalGradient),
                      child: const Center(child: Icon(Icons.eco, size: 120, color: Colors.white54)),
                    ),
                  ),
                  // Dark overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Section 2: Identity Card
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                    padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusXl),
                      boxShadow: AyushColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.names.common, style: AyushTextStyles.h1),
                        Text(plant.names.scientific, style: AyushTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                        const SizedBox(height: AyushSpacing.sm),
                        
                        // Confidence
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                            border: Border.all(
                              color: widget.confidence >= 0.70 ? AyushColors.herbalGreen : Colors.orange.shade900,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Identified with ${(widget.confidence * 100).toStringAsFixed(1)}% confidence',
                            style: AyushTextStyles.labelSmall.copyWith(
                              color: widget.confidence >= 0.70 ? AyushColors.herbalGreen : Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        
                        // Dosha Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDoshaChip('Vata', plant.doshaEffect['vata'] ?? ''),
                            _buildDoshaChip('Pitta', plant.doshaEffect['pitta'] ?? ''),
                            _buildDoshaChip('Kapha', plant.doshaEffect['kapha'] ?? ''),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Quick Facts
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFactChip(Icons.eco_outlined, plant.quickFacts['plant_type'] ?? ''),
                            const SizedBox(height: 8),
                            _buildFactChip(Icons.spa, (plant.quickFacts['parts_used'] as List?)?.join(', ') ?? ''),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Section 3: Safety Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    border: Border.all(color: bannerColor),
                  ),
                  child: Row(
                    children: [
                      Text(safetyConfig['icon']?.toString() ?? '✓', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          safetyConfig['banner_text']?.toString() ?? 'Generally safe — follow recommended doses',
                          style: AyushTextStyles.bodyMedium.copyWith(
                            color: bannerColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AyushSpacing.lg),

                // Section 4: Expandable Sections
                _buildExpandableSection(
                  title: 'Ayurvedic Properties',
                  icon: Icons.auto_awesome,
                  children: [
                    _buildPropertyRow('Virya (Potency)', plant.quickFacts['virya'] ?? ''),
                    _buildPropertyRow('Vipaka (Post-digestion)', plant.quickFacts['vipaka'] ?? ''),
                    _buildPropertyRow('Rasa (Taste)', plant.quickFacts['taste_rasa'] ?? ''),
                    const SizedBox(height: 12),
                    Text('Gunas (Qualities):', style: AyushTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (plant.ayurvedicProperties['guna'] as List? ?? []).map<Widget>((g) {
                        return Chip(label: Text(g.toString()), backgroundColor: AyushColors.sand);
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _buildPropertyRow('Agni Impact', plant.ayurvedicProperties['agni_impact'] ?? ''),
                    const SizedBox(height: 12),
                    Text('Classical Reference:', style: AyushTextStyles.labelMedium),
                    Text(plant.ayurvedicProperties['classical_reference'] ?? '', style: AyushTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),

                _buildExpandableSection(
                  title: 'Medicinal Uses',
                  icon: Icons.medical_services_outlined,
                  children: plant.medicinalUses.map((use) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AyushColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(use.use, style: AyushTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(use.method, style: AyushTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: AyushColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${use.frequency} • ${use.duration}', style: AyushTextStyles.labelSmall),
                          ],
                        )
                      ],
                    ),
                  )).toList(),
                ),

                _buildExpandableSection(
                  title: 'How to Use It',
                  icon: Icons.blender_outlined,
                  children: [
                    if (plant.intakeMethods['external']?.isNotEmpty ?? false) ...[
                      Text('External Use', style: AyushTextStyles.labelLarge),
                      ...plant.intakeMethods['external'].map<Widget>((e) => _buildBulletPoint(e)),
                      const SizedBox(height: 12),
                    ],
                    if (plant.intakeMethods['internal']?.isNotEmpty ?? false) ...[
                      Text('Internal Use', style: AyushTextStyles.labelLarge),
                      ...plant.intakeMethods['internal'].map<Widget>((e) => _buildBulletPoint(e)),
                      const SizedBox(height: 12),
                    ],
                    if (plant.intakeMethods['avoided_forms']?.isNotEmpty ?? false) ...[
                      Text('⚠️ Avoid', style: AyushTextStyles.labelLarge.copyWith(color: Colors.orange.shade900)),
                      ...plant.intakeMethods['avoided_forms'].map<Widget>((e) => _buildBulletPoint(e, color: Colors.orange.shade900)),
                    ],
                  ],
                ),

                _buildExpandableSection(
                  title: 'Contraindications',
                  icon: Icons.do_not_disturb_alt,
                  backgroundColor: Colors.red.shade50,
                  children: plant.contraindications.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.close, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c, style: AyushTextStyles.bodyMedium)),
                      ],
                    ),
                  )).toList(),
                ),

                _buildExpandableSection(
                  title: 'Drug Interactions',
                  icon: Icons.medication_liquid,
                  children: plant.drugInteractions.isEmpty 
                    ? [Text('No significant drug interactions documented.', style: AyushTextStyles.bodyMedium)]
                    : plant.drugInteractions.map((di) {
                        Color severityColor;
                        if (di.severity.toLowerCase() == 'high') severityColor = Colors.red;
                        else if (di.severity.toLowerCase() == 'moderate') severityColor = Colors.orange;
                        else severityColor = Colors.grey;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: severityColor, width: 4)),
                            color: AyushColors.surfaceVariant,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(di.drugClass, style: AyushTextStyles.labelLarge),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severityColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(di.severity.toUpperCase(), style: AyushTextStyles.caption.copyWith(color: severityColor)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(di.interaction, style: AyushTextStyles.bodyMedium),
                            ],
                          ),
                        );
                      }).toList(),
                ),

                // Prakriti Advice (User specific)
                Container(
                  margin: const EdgeInsets.all(AyushSpacing.pagePadding),
                  padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: _getDoshaColor(prakriti).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    border: Border.all(color: _getDoshaColor(prakriti).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: _getDoshaColor(prakriti)),
                          const SizedBox(width: 8),
                          Text('Advice for ${prakriti[0].toUpperCase()}${prakriti.substring(1)} Prakriti', style: AyushTextStyles.h3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plant.prakritiAdvice[prakriti] ?? 'Consult a qualified Ayurvedic practitioner for personalized advice.',
                        style: AyushTextStyles.bodyMedium,
                      ),
                      const Divider(height: 24),
                      Text('Seasonal Advice:', style: AyushTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Best: ${plant.seasonalAdvice["best_season"] ?? "Consult a practitioner."}'),
                      _buildBulletPoint('Avoid: ${plant.seasonalAdvice["avoid_season"] ?? "None documented."}'),
                    ],
                  ),
                ),

                // Fun Fact
                if (plant.funFact.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
                    padding: const EdgeInsets.all(AyushSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AyushColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AyushColors.gold, size: 32),
                        const SizedBox(height: 8),
                        Text('Did You Know?', style: AyushTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        Text(plant.funFact, textAlign: TextAlign.center, style: AyushTextStyles.bodyMedium),
                      ],
                    ),
                  ),

                // Disclaimer
                Container(
                  margin: const EdgeInsets.all(AyushSpacing.pagePadding),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          PlantKnowledgeService.instance.disclaimer,
                          style: AyushTextStyles.caption.copyWith(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: plant.safetyLevel != 'toxic_expert_only' ? FloatingActionButton.extended(
        backgroundColor: AyushColors.primary,
        onPressed: () {
          context.push('/plant/ask', extra: plant);
        },
        icon: const Icon(Icons.science, color: Colors.white),
        label: Text('Ask a Question', style: AyushTextStyles.buttonPrimary),
      ) : null,
    );
  }

  Widget _buildDoshaChip(String dosha, String effect) {
    Color c;
    if (effect.toLowerCase() == 'pacifies') c = AyushColors.success;
    else if (effect.toLowerCase() == 'aggravates') c = AyushColors.error;
    else c = AyushColors.textMuted;

    return Column(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(dosha, style: AyushTextStyles.labelSmall),
      ],
    );
  }

  Widget _buildFactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AyushColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: AyushTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({required String title, required IconData icon, required List<Widget> children, Color? backgroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        boxShadow: AyushColors.subtleShadow,
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: AyushColors.primary),
            const SizedBox(width: 12),
            Text(title, style: AyushTextStyles.h3),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: AyushTextStyles.labelMedium)),
          Expanded(child: Text(value, style: AyushTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color ?? AyushColors.textPrimary)),
          Expanded(child: Text(text, style: AyushTextStyles.bodyMedium.copyWith(color: color))),
        ],
      ),
    );
  }

  Color _getDoshaColor(String prakriti) {
    if (prakriti == 'vata') return AyushColors.vata;
    if (prakriti == 'pitta') return AyushColors.pitta;
    if (prakriti == 'kapha') return AyushColors.kapha;
    return AyushColors.primary;
  }
}
