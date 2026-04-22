/// AYUSH String Constants — All hardcoded UI strings
/// Use these instead of inline strings for easy i18n migration
class AyushStrings {
  AyushStrings._();

  // App
  static const String appName = 'AYUSH';
  static const String appTagline = 'Your Ayurvedic Health Companion';

  // Auth
  static const String signIn = 'Sign In';
  static const String createAccount = 'Create Account';
  static const String phoneNumber = 'Phone Number';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String noAccount = "New here? Create account";
  static const String haveAccount = 'Already have an account? Sign In';
  static const String phoneRegistered = 'Phone already registered';
  static const String incorrectPassword = 'Incorrect password';
  static const String phoneNotFound = 'Phone not registered';

  // Onboarding
  static const String step1Title = "Let's start with the basics";
  static const String step1Subtitle = "We'll personalize everything for you";
  static const String step2Title = "Show us where it hurts";
  static const String step2Subtitle = "Tap any area of the body — this helps us understand your pain patterns";
  static const String step3Title = "Discover your body type";
  static const String step3Subtitle = "Answer honestly — there are no right or wrong answers";
  static const String step4Title = "Tell us how you live";
  static const String step4Subtitle = "Your daily habits shape your health deeply";
  static const String step5Title = "Your health history";
  static const String step5Subtitle = "This helps us avoid recommendations that could harm you";
  static const String step6Title = "Upload your health reports";
  static const String step6Subtitle = "AYUSH reads your reports using AI — no doctor needed";

  // OJAS
  static const String ojasTitle = "Your OJAS Score";
  static const String ojasDisclaimer = "This OJAS score is a wellness indicator, not a medical diagnosis. Consult a qualified practitioner for medical advice.";
  static const String ojasExcellent = "Excellent Vitality";
  static const String ojasGood = "Good Vitality";
  static const String ojasAttention = "Needs Attention";
  static const String ojasCritical = "Critical — Action Needed";
  static const String beginJourney = "Begin Your Journey";

  // Doshas
  static const String vata = 'Vata';
  static const String pitta = 'Pitta';
  static const String kapha = 'Kapha';

  // Common
  static const String continueBtn = 'Continue';
  static const String saveBtn = 'Save';
  static const String skipForNow = 'Skip for now';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String done = 'Done';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String addManually = 'Add manually';
  static const String confirmAndSave = 'Confirm & Save';
  static const String uploadReport = 'Tap to upload PDF, JPG, or PNG';
  static const String analyzing = 'Analyzing...';
  static const String extracted = '✓ Extracted';
  static const String noPainAreas = "No pain areas — I'm pain-free";
  static const String stepOf = 'Step {current} of {total}';
}
