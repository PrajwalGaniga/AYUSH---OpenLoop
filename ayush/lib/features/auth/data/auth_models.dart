class UserModel {
  final String userId;
  final String phone;
  final String token;
  final bool isOnboarded;
  final int onboardingStep;
  final Map<String, dynamic>? profile;

  /// Persisted from server — populated on login & session restore (/auth/me)
  /// These fields let the home screen show correct data without re-running onboarding
  final int? ojasScore;
  final Map<String, dynamic>? prakritiResult;

  const UserModel({
    required this.userId,
    required this.phone,
    required this.token,
    required this.isOnboarded,
    required this.onboardingStep,
    this.profile,
    this.ojasScore,
    this.prakritiResult,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      phone: json['phone'] as String? ?? '',
      token: json['token'] as String? ?? '',
      isOnboarded: json['isOnboarded'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as int? ?? 0,
      profile: json['profile'] as Map<String, dynamic>?,
      ojasScore: (json['ojasScore'] as num?)?.toInt(),
      prakritiResult: json['prakritiResult'] as Map<String, dynamic>?,
    );
  }

  UserModel copyWith({
    String? userId,
    String? phone,
    String? token,
    bool? isOnboarded,
    int? onboardingStep,
    Map<String, dynamic>? profile,
    int? ojasScore,
    Map<String, dynamic>? prakritiResult,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      profile: profile ?? this.profile,
      ojasScore: ojasScore ?? this.ojasScore,
      prakritiResult: prakritiResult ?? this.prakritiResult,
    );
  }
}
