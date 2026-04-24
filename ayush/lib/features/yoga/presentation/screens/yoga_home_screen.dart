import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/asana.dart';
import '../../providers/yoga_provider.dart';

class YogaHomeScreen extends ConsumerWidget {
  const YogaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asanasAsync = ref.watch(asanasProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AyushColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("Yoga For You", style: AyushTextStyles.h2),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AyushColors.primary,
            labelColor: AyushColors.primary,
            unselectedLabelColor: AyushColors.textSecondary,
            tabs: [
              Tab(text: "🌬️ Vata"),
              Tab(text: "🔥 Pitta"),
              Tab(text: "🌿 Kapha"),
            ],
          ),
        ),
        body: asanasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
          data: (asanas) {
            final vataAsanas = asanas.where((a) => a.dosha == "vata").toList();
            final pittaAsanas = asanas.where((a) => a.dosha == "pitta").toList();
            final kaphaAsanas = asanas.where((a) => a.dosha == "kapha").toList();

            return TabBarView(
              children: [
                _buildAsanaList(vataAsanas, context),
                _buildAsanaList(pittaAsanas, context),
                _buildAsanaList(kaphaAsanas, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAsanaList(List<Asana> asanas, BuildContext context) {
    if (asanas.isEmpty) {
      return const Center(child: Text("No asanas found for this dosha."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asanas.length,
      itemBuilder: (context, index) {
        final asana = asanas[index];
        Color cardColor = Color(int.parse(asana.doshaColor.replaceFirst('#', '0xFF')));

        return GestureDetector(
          onTap: () => context.push('/yoga/detail', extra: asana),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 140,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Image
                SizedBox(
                  width: 120,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: Image.asset(
                      asana.localImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.self_improvement, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asana.nameSanskrit,
                          style: AyushTextStyles.h3.copyWith(fontSize: 16, color: cardColor.withValues(alpha: 1.0)),
                        ),
                        Text(
                          asana.nameEnglish,
                          style: AyushTextStyles.bodyMedium.copyWith(fontSize: 13, color: AyushColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniChip(asana.difficulty, Icons.fitness_center),
                            const SizedBox(width: 8),
                            _buildMiniChip("${asana.holdSeconds}s", Icons.timer),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            asana.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AyushTextStyles.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AyushColors.primary),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AyushColors.primary),
          ),
        ],
      ),
    );
  }
}
