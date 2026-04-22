class UserModel {
  final String userId;
  final String phone;
  final String token;
  final bool isOnboarded;
  final int onboardingStep;
  final Map<String, dynamic>? profile;

  const UserModel({
    required this.userId,
    required this.phone,
    required this.token,
    required this.isOnboarded,
    required this.onboardingStep,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      phone: json['phone'] as String? ?? '',
      token: json['token'] as String? ?? '',
      isOnboarded: json['isOnboarded'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as int? ?? 0,
      profile: json['profile'] as Map<String, dynamic>?,
    );
  }

  UserModel copyWith({
    String? userId,
    String? phone,
    String? token,
    bool? isOnboarded,
    int? onboardingStep,
    Map<String, dynamic>? profile,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      profile: profile ?? this.profile,
    );
  }
}
