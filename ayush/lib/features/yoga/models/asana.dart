class Asana {
  final String id;
  final String nameSanskrit;
  final String nameEnglish;
  final String dosha;
  final Map<String, dynamic> doshaEffect;
  final String difficulty;
  final int holdSeconds;
  final String description;
  final String howItHelps;
  final List<String> steps;

  // imageUrl is local asset — not from backend
  String get localImagePath => "assets/yoga/$id.png";
  String get doshaColor {
    switch (dosha) {
      case "vata": return "#6c63a8";
      case "pitta": return "#e05c3a";
      case "kapha": return "#2d6a4f";
      default: return "#666666";
    }
  }

  Asana.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nameSanskrit = json['name_sanskrit'],
      nameEnglish = json['name_english'],
      dosha = json['dosha'],
      doshaEffect = json['dosha_effect'],
      difficulty = json['difficulty'],
      holdSeconds = json['hold_seconds'],
      description = json['description'],
      howItHelps = json['how_it_helps'],
      steps = List<String>.from(json['steps']);
}
