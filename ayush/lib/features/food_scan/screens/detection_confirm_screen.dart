import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/food_scan_provider.dart';
import '../data/food_knowledge_service.dart';

class DetectionConfirmScreen extends ConsumerStatefulWidget {
  const DetectionConfirmScreen({super.key});

  @override
  ConsumerState<DetectionConfirmScreen> createState() => _DetectionConfirmScreenState();
}

class _DetectionConfirmScreenState extends ConsumerState<DetectionConfirmScreen> {
  List<Map<String, String>> _allFoods = [];

  @override
  void initState() {
    super.initState();
    _loadFoodNames();
  }

  Future<void> _loadFoodNames() async {
    final names = await FoodKnowledgeService.getFoodNames();
    setState(() {
      _allFoods = names;
    });
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AyushSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _AddFoodSheet(allFoods: _allFoods),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodScanProvider);
    final confirmedItems = state.confirmedItems;
    
    // Map classId to name using detected items + all foods fallback
    String getFoodName(String classId) {
      final detected = state.detectedItems.where((e) => e.classId == classId).toList();
      if (detected.isNotEmpty) return detected.first.name;
      final fallback = _allFoods.where((e) => e['class_id'] == classId).toList();
      if (fallback.isNotEmpty) return fallback.first['name']!;
      return classId;
    }

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("What did we find?", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AyushColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AyushSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tap × to remove anything wrong",
                style: AyushTextStyles.bodyMedium,
              ),
              const SizedBox(height: AyushSpacing.lg),
              
              if (state.imageFile != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    child: Image.file(
                      state.imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: AyushSpacing.lg),
              ],
              
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: confirmedItems.map((classId) {
                  return Chip(
                    label: Text(
                      getFoodName(classId),
                      style: const TextStyle(color: AyushColors.textOnPrimary),
                    ),
                    backgroundColor: AyushColors.herbalGreen,
                    deleteIconColor: Colors.white,
                    onDeleted: () {
                      ref.read(foodScanProvider.notifier).removeConfirmedItem(classId);
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AyushSpacing.xl),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddFoodSheet(context),
                  icon: const Icon(Icons.add, color: AyushColors.primary),
                  label: Text(
                    "Add Missing Item",
                    style: AyushTextStyles.buttonSecondary,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: AyushSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: confirmedItems.isEmpty
                      ? null
                      : () {
                          context.push('/food/source');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AyushColors.primary,
                    disabledBackgroundColor: AyushColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    ),
                  ),
                  child: Text(
                    "Looks Good →",
                    style: AyushTextStyles.buttonPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> allFoods;

  const _AddFoodSheet({required this.allFoods});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allFoods.where((food) {
      return food['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(AyushSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add food item", style: AyushTextStyles.h2),
          const SizedBox(height: AyushSpacing.md),
          TextField(
            decoration: InputDecoration(
              hintText: "Search...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: AyushSpacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final food = filtered[idx];
                return ListTile(
                  title: Text(food['name']!, style: AyushTextStyles.bodyLarge),
                  onTap: () {
                    ref.read(foodScanProvider.notifier).addConfirmedItem(food['class_id']!);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
