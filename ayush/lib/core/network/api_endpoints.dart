/// All API endpoint constants — single source of truth
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const String step1BasicProfile = '/step1/basic-profile';
  static const String step2BodyScan = '/step2/body-scan';
  static const String step2PhysicalTraits = '/step2/physical-traits';
  static const String step3PrakritiAnswers = '/step3/prakriti-answers';
  static const String step3CalculatePrakriti = '/step3/calculate-prakriti';
  static const String step4Lifestyle = '/step4/lifestyle';
  static const String step5HealthConditions = '/step5/health-conditions';
  static const String step6UploadReport = '/step6/upload-report';
  static const String step6ConfirmReport = '/step6/confirm-report';
  static const String calculateOjas = '/calculate-ojas';
  static const String completeOnboarding = '/complete';
  static String onboardingStatus(String userId) => '/status/$userId';
}
