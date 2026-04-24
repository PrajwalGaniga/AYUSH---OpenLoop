import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/recipe_provider.dart';
import '../../models/recipe_model.dart';
import '../../../auth/providers/auth_provider.dart';

class RecipeHistoryScreen extends ConsumerStatefulWidget {
  const RecipeHistoryScreen({super.key});

  @override
  ConsumerState<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends ConsumerState<RecipeHistoryScreen> {
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final user = ref.read(authProvider).value;
      final userId = (user != null && user.userId.isNotEmpty) ? user.userId : "demo_user";
      
      final recipes = await repo.getHistory(userId);
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecipe(String hash) async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final success = await repo.deleteHistory(hash);
      if (success) {
        setState(() {
          _recipes.removeWhere((r) => r.recipeHash == hash);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete recipe"), backgroundColor: AyushColors.error)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        title: Text("Recipe History", style: AyushTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? Center(child: Text("No generated recipes found.", style: AyushTextStyles.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.all(AyushSpacing.pagePadding),
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Dismissible(
                      key: Key(recipe.recipeHash ?? index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AyushColors.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        if (recipe.recipeHash != null) {
                          _deleteRecipe(recipe.recipeHash!);
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          // View recipe again
                          ref.read(recipeProvider.notifier).setRecipe(recipe);
                          context.push('/recipe/display');
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(recipe.name, style: AyushTextStyles.h3)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AyushColors.error),
                                      onPressed: () {
                                        if (recipe.recipeHash != null) {
                                          _deleteRecipe(recipe.recipeHash!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AyushTextStyles.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14, color: AyushColors.primary),
                                    const SizedBox(width: 4),
                                    Text(recipe.bestTime, style: AyushTextStyles.bodySmall.copyWith(color: AyushColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
