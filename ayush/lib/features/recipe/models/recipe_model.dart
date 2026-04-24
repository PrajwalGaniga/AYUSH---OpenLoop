class RecipeIngredient {
  final String name;
  final String quantity;

  RecipeIngredient({required this.name, required this.quantity});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String instruction;

  RecipeStep({required this.stepNumber, required this.instruction});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] ?? 0,
      instruction: json['instruction'] ?? '',
    );
  }
}

class RecipeDoshaImpact {
  final String vata;
  final String pitta;
  final String kapha;
  final int overallOjas;

  RecipeDoshaImpact({
    required this.vata,
    required this.pitta,
    required this.kapha,
    required this.overallOjas,
  });

  factory RecipeDoshaImpact.fromJson(Map<String, dynamic> json) {
    return RecipeDoshaImpact(
      vata: json['vata'] ?? '',
      pitta: json['pitta'] ?? '',
      kapha: json['kapha'] ?? '',
      overallOjas: json['overall_ojas'] ?? 0,
    );
  }
}

class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      videoId: json['video_id'] ?? '',
      title: json['title'] ?? '',
      channelName: json['channel_name'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}

class RecipeModel {
  final String name;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeDoshaImpact doshaImpact;
  final String bestTime;
  final bool isViruddha;
  final String viruddhaReason;
  final String? recipeHash;
  List<YouTubeVideo> youtubeVideos;

  RecipeModel({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.doshaImpact,
    required this.bestTime,
    required this.isViruddha,
    required this.viruddhaReason,
    this.recipeHash,
    this.youtubeVideos = const [],
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients: (json['ingredients'] as List?)?.map((i) => RecipeIngredient.fromJson(i)).toList() ?? [],
      steps: (json['steps'] as List?)?.map((s) => RecipeStep.fromJson(s)).toList() ?? [],
      doshaImpact: RecipeDoshaImpact.fromJson(json['dosha_impact'] ?? {}),
      bestTime: json['best_time'] ?? '',
      isViruddha: json['is_viruddha'] ?? false,
      viruddhaReason: json['viruddha_reason'] ?? '',
      recipeHash: json['recipeHash'],
    );
  }
}
