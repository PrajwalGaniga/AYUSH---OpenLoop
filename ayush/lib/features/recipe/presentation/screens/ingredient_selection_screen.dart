import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/recipe_provider.dart';

class IngredientSelectionScreen extends ConsumerStatefulWidget {
  const IngredientSelectionScreen({super.key});

  @override
  ConsumerState<IngredientSelectionScreen> createState() => _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState extends ConsumerState<IngredientSelectionScreen> {
  List<dynamic> _categories = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/ingredients.json');
      setState(() {
        _categories = json.decode(jsonStr);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);

    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("Create Recipe", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AyushColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/recipe/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search ingredients...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AyushColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Selected Chips Area
            if (state.primaryIngredients.isNotEmpty || state.spices.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AyushSpacing.pagePadding),
                color: AyushColors.background,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...state.primaryIngredients.map((item) => InputChip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => ref.read(recipeProvider.notifier).togglePrimary(item),
                      backgroundColor: AyushColors.primary.withValues(alpha: 0.1),
                      deleteIconColor: AyushColors.primary,
                    )),
                    ...state.spices.map((item) => InputChip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => ref.read(recipeProvider.notifier).toggleSpice(item),
                      backgroundColor: AyushColors.herbalGreen.withValues(alpha: 0.1),
                      deleteIconColor: AyushColors.herbalGreen,
                    )),
                  ],
                ),
              ),

            // Selection Limits
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Primary: ${state.primaryIngredients.length}/10", style: AyushTextStyles.bodySmall),
                  Text("Spices: ${state.spices.length}/5", style: AyushTextStyles.bodySmall),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(AyushSpacing.pagePadding),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final catName = category['category'];
                      final isSpice = catName == 'Spices & Herbs';
                      
                      final items = (category['items'] as List)
                          .map((e) => e.toString())
                          .where((e) => e.toLowerCase().contains(_searchQuery))
                          .toList();

                      if (items.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(catName, style: AyushTextStyles.h3),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: items.map((item) {
                              final isSelected = isSpice 
                                  ? state.spices.contains(item)
                                  : state.primaryIngredients.contains(item);
                              return FilterChip(
                                label: Text(item, style: TextStyle(color: isSelected ? Colors.white : AyushColors.textPrimary)),
                                selected: isSelected,
                                selectedColor: isSpice ? AyushColors.herbalGreen : AyushColors.primary,
                                backgroundColor: AyushColors.card,
                                checkmarkColor: Colors.white,
                                onSelected: (val) {
                                  try {
                                    if (isSpice) {
                                      ref.read(recipeProvider.notifier).toggleSpice(item);
                                    } else {
                                      ref.read(recipeProvider.notifier).togglePrimary(item);
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AyushColors.error)
                                    );
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AyushSpacing.lg),
                        ],
                      );
                    },
                  ),
            ),

            // Generate Button
            Padding(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              child: SizedBox(
                width: double.infinity,
                height: AyushSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.primaryIngredients.isEmpty || state.isLoading
                      ? null
                      : () async {
                          await ref.read(recipeProvider.notifier).generateRecipe();
                          if (mounted && ref.read(recipeProvider).error == null) {
                            context.push('/recipe/display');
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ref.read(recipeProvider).error ?? "Error"), backgroundColor: AyushColors.error)
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AyushColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Generate Recipe", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
