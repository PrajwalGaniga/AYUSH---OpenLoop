import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/asana.dart';

class AsanaDetailScreen extends StatelessWidget {
  final Asana asana;

  const AsanaDetailScreen({required this.asana, super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = Color(int.parse(asana.doshaColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: AyushColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: cardColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: cardColor.withValues(alpha: 0.1),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Image.asset(
                            asana.localImagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.self_improvement, size: 100, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asana.nameSanskrit,
                            style: AyushTextStyles.h1.copyWith(color: cardColor, fontSize: 28),
                          ),
                          Text(
                            asana.nameEnglish,
                            style: AyushTextStyles.h3.copyWith(color: AyushColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${asana.dosha.toUpperCase()} DOSHA",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPracticeInfo(cardColor),
                  const SizedBox(height: 24),
                  _buildAyurvedicBenefit(cardColor),
                  const SizedBox(height: 24),
                  Text("How To Practice", style: AyushTextStyles.h2),
                  const SizedBox(height: 16),
                  _buildSteps(),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.push('/yoga/check', extra: asana.id);
            },
            child: const Text(
              "Check My Posture →",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeInfo(Color cardColor) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(cardColor, Icons.timer, "Hold Time", "${asana.holdSeconds} seconds"),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(cardColor, Icons.fitness_center, "Difficulty", asana.difficulty.toUpperCase()),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color color, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AyushColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: AyushColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAyurvedicBenefit(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: cardColor, width: 4)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("🌿", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text("Ayurvedic Benefit", style: AyushTextStyles.h3.copyWith(color: cardColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            asana.howItHelps,
            style: AyushTextStyles.bodyMedium.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDoshaEffectChip("Vata", "vata"),
              _buildDoshaEffectChip("Pitta", "pitta"),
              _buildDoshaEffectChip("Kapha", "kapha"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDoshaEffectChip(String label, String key) {
    bool pacifies = List<String>.from(asana.doshaEffect["pacifies"] ?? []).contains(key);
    bool aggravates = List<String>.from(asana.doshaEffect["aggravates"] ?? []).contains(key);

    Color color = Colors.grey;
    IconData icon = Icons.remove;
    
    if (pacifies) {
      color = Colors.green;
      icon = Icons.arrow_downward;
    } else if (aggravates) {
      color = Colors.red;
      icon = Icons.arrow_upward;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildSteps() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: asana.steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AyushColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  asana.steps[index],
                  style: AyushTextStyles.bodyMedium.copyWith(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
