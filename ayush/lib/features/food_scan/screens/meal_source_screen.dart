import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/food_scan_provider.dart';

class MealSourceScreen extends ConsumerWidget {
  const MealSourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealSource = ref.watch(foodScanProvider).mealSource;

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("Where is this from?", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AyushColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AyushSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "This helps us give accurate Ayurvedic insight",
                style: AyushTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AyushSpacing.xl),
              
              _SourceCard(
                title: "Home Cooked",
                subtitle: "Made in your kitchen",
                icon: "🏠",
                isSelected: mealSource == 'home',
                onTap: () {
                  ref.read(foodScanProvider.notifier).setMealSource('home');
                  context.push('/food/audit');
                },
              ),
              
              const SizedBox(height: AyushSpacing.lg),
              
              _SourceCard(
                title: "Outside",
                subtitle: "Restaurant / Hotel / Canteen",
                icon: "🏪",
                isSelected: mealSource == 'hotel',
                onTap: () {
                  ref.read(foodScanProvider.notifier).setMealSource('hotel');
                  context.push('/food/audit');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AyushColors.card,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AyushColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: AyushColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: AyushSpacing.sm),
            Text(title, style: AyushTextStyles.h3),
            const SizedBox(height: AyushSpacing.xs),
            Text(subtitle, style: AyushTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
