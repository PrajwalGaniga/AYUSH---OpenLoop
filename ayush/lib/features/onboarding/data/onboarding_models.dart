class PrakritiAnswer {
  final String questionId;
  final String selectedDosha; // "vata" | "pitta" | "kapha"

  const PrakritiAnswer({required this.questionId, required this.selectedDosha});

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedDosha': selectedDosha,
      };
}

class PainPoint {
  final String region;
  final int severity; // 1-5
  final String description;
  final List<String> timing;
  final String duration;

  const PainPoint({
    required this.region,
    required this.severity,
    this.description = '',
    this.timing = const [],
    this.duration = '',
  });

  Map<String, dynamic> toJson() => {
        'region': region,
        'severity': severity,
        'description': description,
        'timing': timing,
        'duration': duration,
      };
}

class MedicationItem {
  final String name;
  final String dosage;
  final String frequency;

  const MedicationItem({
    required this.name,
    this.dosage = '',
    this.frequency = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
      };
}

class PrakritiResult {
  final String dominant;
  final String? secondary;
  final String type;
  final Map<String, int> scores;

  const PrakritiResult({
    required this.dominant,
    this.secondary,
    required this.type,
    required this.scores,
  });

  factory PrakritiResult.fromJson(Map<String, dynamic> json) {
    return PrakritiResult(
      dominant: json['dominant'] ?? '',
      secondary: json['secondary'],
      type: json['type'] ?? '',
      scores: Map<String, int>.from(json['scores'] ?? {}),
    );
  }
}

class OjasResult {
  final int ojasScore;
  final Map<String, dynamic> breakdown;

  const OjasResult({required this.ojasScore, required this.breakdown});

  factory OjasResult.fromJson(Map<String, dynamic> json) {
    return OjasResult(
      ojasScore: json['ojasScore'] ?? 0,
      breakdown: Map<String, dynamic>.from(json['breakdown'] ?? {}),
    );
  }
}

class OnboardingState {
  final int step;
  final bool isLoading;
  final String? error;

  // Step 1 data
  final String? fullName;
  final DateTime? dob;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? bloodGroup;
  final String language;
  final String? region;

  // Step 2 data
  final List<PainPoint> painPoints;

  // Step 3 data
  final List<PrakritiAnswer> prakritiAnswers;
  final PrakritiResult? prakritiResult;

  // Step 4 data
  final String? occupationType;
  final String? stressLevel;
  final String? exerciseFrequency;
  final String? dietType;
  final double? waterIntakeLiters;
  final double? sleepHours;
  final String? smokingStatus;
  final String? alcoholStatus;
  final bool yogaPractice;
  final bool meditationPractice;

  // Step 5 data
  final List<String> diagnosedConditions;
  final List<String> chronicConditions;
  final List<String> allergies;
  final List<MedicationItem> currentMedications;
  final List<String> surgeries;
  final List<String> familyHistory;

  // OJAS
  final OjasResult? ojasResult;

  const OnboardingState({
    this.step = 0,
    this.isLoading = false,
    this.error,
    this.fullName,
    this.dob,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.bloodGroup,
    this.language = 'en',
    this.region,
    this.painPoints = const [],
    this.prakritiAnswers = const [],
    this.prakritiResult,
    this.occupationType,
    this.stressLevel,
    this.exerciseFrequency,
    this.dietType,
    this.waterIntakeLiters,
    this.sleepHours,
    this.smokingStatus,
    this.alcoholStatus,
    this.yogaPractice = false,
    this.meditationPractice = false,
    this.diagnosedConditions = const [],
    this.chronicConditions = const [],
    this.allergies = const [],
    this.currentMedications = const [],
    this.surgeries = const [],
    this.familyHistory = const [],
    this.ojasResult,
  });

  OnboardingState copyWith({
    int? step,
    bool? isLoading,
    String? error,
    String? fullName,
    DateTime? dob,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? bloodGroup,
    String? language,
    String? region,
    List<PainPoint>? painPoints,
    List<PrakritiAnswer>? prakritiAnswers,
    PrakritiResult? prakritiResult,
    String? occupationType,
    String? stressLevel,
    String? exerciseFrequency,
    String? dietType,
    double? waterIntakeLiters,
    double? sleepHours,
    String? smokingStatus,
    String? alcoholStatus,
    bool? yogaPractice,
    bool? meditationPractice,
    List<String>? diagnosedConditions,
    List<String>? chronicConditions,
    List<String>? allergies,
    List<MedicationItem>? currentMedications,
    List<String>? surgeries,
    List<String>? familyHistory,
    OjasResult? ojasResult,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      language: language ?? this.language,
      region: region ?? this.region,
      painPoints: painPoints ?? this.painPoints,
      prakritiAnswers: prakritiAnswers ?? this.prakritiAnswers,
      prakritiResult: prakritiResult ?? this.prakritiResult,
      occupationType: occupationType ?? this.occupationType,
      stressLevel: stressLevel ?? this.stressLevel,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      dietType: dietType ?? this.dietType,
      waterIntakeLiters: waterIntakeLiters ?? this.waterIntakeLiters,
      sleepHours: sleepHours ?? this.sleepHours,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholStatus: alcoholStatus ?? this.alcoholStatus,
      yogaPractice: yogaPractice ?? this.yogaPractice,
      meditationPractice: meditationPractice ?? this.meditationPractice,
      diagnosedConditions: diagnosedConditions ?? this.diagnosedConditions,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      surgeries: surgeries ?? this.surgeries,
      familyHistory: familyHistory ?? this.familyHistory,
      ojasResult: ojasResult ?? this.ojasResult,
    );
  }
}
