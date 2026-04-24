import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recipe_repository.dart';
import '../models/recipe_model.dart';
import '../../onboarding/providers/onboarding_provider.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(dioClientProvider));
});

class RecipeState {
  final List<String> primaryIngredients;
  final List<String> spices;
  final RecipeModel? generatedRecipe;
  final bool isLoading;
  final String? error;

  RecipeState({
    this.primaryIngredients = const [],
    this.spices = const [],
    this.generatedRecipe,
    this.isLoading = false,
    this.error,
  });

  RecipeState copyWith({
    List<String>? primaryIngredients,
    List<String>? spices,
    RecipeModel? generatedRecipe,
    bool? isLoading,
    String? error,
    bool clearRecipe = false,
  }) {
    return RecipeState(
      primaryIngredients: primaryIngredients ?? this.primaryIngredients,
      spices: spices ?? this.spices,
      generatedRecipe: clearRecipe ? null : (generatedRecipe ?? this.generatedRecipe),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  final Ref ref;

  RecipeNotifier(this.ref) : super(RecipeState());

  void togglePrimary(String item) {
    final list = List<String>.from(state.primaryIngredients);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      if (list.length >= 10) throw Exception("Max 10 primary ingredients allowed");
      list.add(item);
    }
    state = state.copyWith(primaryIngredients: list);
  }

  void toggleSpice(String item) {
    final list = List<String>.from(state.spices);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      if (list.length >= 5) throw Exception("Max 5 spices allowed");
      list.add(item);
    }
    state = state.copyWith(spices: list);
  }

  void clearSelection() {
    state = RecipeState();
  }

  Future<void> generateRecipe() async {
    if (state.primaryIngredients.isEmpty) {
      state = state.copyWith(error: "Select at least one ingredient");
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(recipeRepositoryProvider);
      final user = ref.read(authProvider).value;
      final onboarding = ref.read(onboardingProvider);
      
      final prakriti = onboarding.prakritiResult?.dominant ?? user?.prakritiResult?['dominant']?.toString() ?? "Vata";
      final conditions = onboarding.diagnosedConditions;

      final recipe = await repo.generateRecipe(
        userId: user?.userId ?? "demo_user",
        ingredients: state.primaryIngredients,
        spices: state.spices,
        prakriti: prakriti,
        conditions: conditions,
        diet: onboarding.dietType ?? "Vegetarian",
        region: "India",
      );

      // Fetch YouTube Videos
      final videos = await repo.searchYouTube(recipe.name);
      recipe.youtubeVideos = videos;

      state = state.copyWith(generatedRecipe: recipe, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final recipeProvider = StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  return RecipeNotifier(ref);
});
