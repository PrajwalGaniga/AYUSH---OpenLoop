import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/recipe_provider.dart';

class RecipeDisplayScreen extends ConsumerWidget {
  const RecipeDisplayScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeProvider);
    final recipe = state.generatedRecipe;

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No recipe generated")),
      );
    }

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: const Text("Your Recipe"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AyushSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(recipe.name, style: AyushTextStyles.h2),
            const SizedBox(height: 8),
            Text(recipe.description, style: AyushTextStyles.bodyMedium),
            const SizedBox(height: 16),
            
            // Warnings / Tags
            if (recipe.isViruddha)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AyushColors.error.withValues(alpha: 0.1),
                  border: Border.all(color: AyushColors.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: AyushColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Viruddha Ahara Warning", style: TextStyle(fontWeight: FontWeight.bold, color: AyushColors.error)),
                          Text(recipe.viruddhaReason, style: const TextStyle(color: AyushColors.error, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            Row(
              children: [
                _buildTag("Vata", recipe.doshaImpact.vata),
                const SizedBox(width: 8),
                _buildTag("Pitta", recipe.doshaImpact.pitta),
                const SizedBox(width: 8),
                _buildTag("Kapha", recipe.doshaImpact.kapha),
              ],
            ),
            const SizedBox(height: 8),
            Text("Best Time: ${recipe.bestTime}", style: AyushTextStyles.bodySmall.copyWith(color: AyushColors.primary)),
            const SizedBox(height: AyushSpacing.xl),

            // Ingredients
            Text("Ingredients", style: AyushTextStyles.h3),
            const SizedBox(height: 8),
            ...recipe.ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AyushColors.textMuted),
                  const SizedBox(width: 8),
                  Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(ing.quantity, style: AyushTextStyles.bodySmall),
                ],
              ),
            )),
            
            const SizedBox(height: AyushSpacing.xl),

            // Steps
            Text("Instructions", style: AyushTextStyles.h3),
            const SizedBox(height: 8),
            ...recipe.steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AyushColors.primary,
                    child: Text(step.stepNumber.toString(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(step.instruction, style: AyushTextStyles.bodyMedium)),
                ],
              ),
            )),

            const SizedBox(height: AyushSpacing.xl),

            // YouTube Section
            if (recipe.youtubeVideos.isNotEmpty) ...[
              Text("Watch it on YouTube", style: AyushTextStyles.h3),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipe.youtubeVideos.length,
                  itemBuilder: (context, index) {
                    final video = recipe.youtubeVideos[index];
                    return GestureDetector(
                      onTap: () => _launchUrl("https://www.youtube.com/watch?v=${video.videoId}"),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AyushColors.card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AyushColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(video.thumbnailUrl, height: 90, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(height: 90, color: Colors.grey.shade300, child: const Icon(Icons.video_library)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(video.channelName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AyushColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 16),

            // Start Cooking Button
            SizedBox(
              width: double.infinity,
              height: AyushSpacing.buttonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () => context.push('/recipe/cooking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AyushColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                ),
                label: const Text("Start Cooking (Play Mode)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: AyushSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(recipeProvider.notifier).clearSelection();
                  context.go('/home');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AyushColors.herbalGreen,
                  side: const BorderSide(color: AyushColors.herbalGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                ),
                child: const Text("Back to Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String dosha, String impact) {
    Color color;
    IconData icon;
    if (impact.toLowerCase().contains("pacif")) {
      color = AyushColors.herbalGreen;
      icon = Icons.trending_down;
    } else if (impact.toLowerCase().contains("aggrav")) {
      color = AyushColors.error;
      icon = Icons.trending_up;
    } else {
      color = AyushColors.textMuted;
      icon = Icons.horizontal_rule;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(dosha, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(impact, style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
