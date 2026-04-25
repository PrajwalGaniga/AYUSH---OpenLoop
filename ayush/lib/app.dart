import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/onboarding/presentation/screens/step1_basic_profile.dart';
import 'features/onboarding/presentation/screens/step2_body_scan.dart';
import 'features/onboarding/presentation/screens/step3_prakriti_quiz.dart';
import 'features/onboarding/presentation/screens/step4_lifestyle.dart';
import 'features/onboarding/presentation/screens/step5_health_conditions.dart';
import 'features/onboarding/presentation/screens/step6_report_upload.dart';
import 'features/onboarding/presentation/screens/ojas_reveal_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/food_scan/screens/camera_scan_screen.dart';
import 'features/food_scan/screens/detection_confirm_screen.dart';
import 'features/food_scan/screens/meal_source_screen.dart';
import 'features/food_scan/screens/deep_audit_screen.dart';
import 'features/food_scan/screens/food_results_screen.dart';
import 'features/recipe/presentation/screens/ingredient_selection_screen.dart';
import 'features/recipe/presentation/screens/recipe_display_screen.dart';
import 'features/recipe/presentation/screens/recipe_history_screen.dart';
import 'features/recipe/presentation/screens/cooking_mode_screen.dart';
import 'features/yoga/presentation/screens/yoga_home_screen.dart';
import 'features/yoga/presentation/screens/asana_detail_screen.dart';
import 'features/yoga/presentation/screens/pose_check_screen.dart';
import 'features/yoga/models/asana.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/edit_profile_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/plant/screens/plant_camera_screen.dart';
import 'features/plant/screens/plant_confirmation_screen.dart';
import 'features/plant/screens/plant_result_screen.dart';
import 'features/plant/screens/plant_ask_screen.dart';
import 'features/plant/models/plant_prediction.dart';
import 'features/plant/models/plant.dart';
import 'features/community/screens/community_home_screen.dart';
import 'features/packaged_food/screens/packaged_food_scan_screen.dart';
import 'features/packaged_food/screens/packaged_food_result_screen.dart';
import 'features/nadi_pariksha/screens/nadi_pariksha_screen.dart';
import 'features/biometrics/screens/tongue_capture_screen.dart';
import 'features/biometrics/screens/tongue_result_screen.dart';
import 'features/biometrics/screens/eye_capture_screen.dart';
import 'features/biometrics/screens/eye_result_screen.dart';
import 'dart:io';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // Onboarding steps (each wraps itself in OnboardingShell)
    GoRoute(path: '/onboarding/0', builder: (_, __) => const Step1BasicProfile()),
    GoRoute(path: '/onboarding/1', builder: (_, __) => const Step2BodyScan()),
    GoRoute(path: '/onboarding/2', builder: (_, __) => const Step3PrakritiQuiz()),
    GoRoute(path: '/onboarding/3', builder: (_, __) => const Step4Lifestyle()),
    GoRoute(path: '/onboarding/4', builder: (_, __) => const Step5HealthConditions()),
    GoRoute(path: '/onboarding/5', builder: (_, __) => const Step6ReportUpload()),

    GoRoute(path: '/ojas-reveal', builder: (_, __) => const OjasRevealScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

    // Food Scan Module
    GoRoute(path: '/food/scan', builder: (_, __) => const CameraScanScreen()),
    GoRoute(path: '/food/confirm', builder: (_, __) => const DetectionConfirmScreen()),
    GoRoute(path: '/food/source', builder: (_, __) => const MealSourceScreen()),
    GoRoute(path: '/food/audit', builder: (_, __) => const DeepAuditScreen()),
    GoRoute(path: '/food/results', builder: (_, __) => const FoodResultsScreen()),

    // Recipe Generator Module
    GoRoute(path: '/recipe/select', builder: (_, __) => const IngredientSelectionScreen()),
    GoRoute(path: '/recipe/display', builder: (_, __) => const RecipeDisplayScreen()),
    GoRoute(path: '/recipe/history', builder: (_, __) => const RecipeHistoryScreen()),
    GoRoute(path: '/recipe/cooking', builder: (_, __) => const CookingModeScreen()),

    // Yoga Posture Analyzer Module
    GoRoute(path: '/yoga/home', builder: (_, __) => const YogaHomeScreen()),
    GoRoute(
      path: '/yoga/detail',
      builder: (_, state) => AsanaDetailScreen(asana: state.extra as Asana),
    ),
    GoRoute(
      path: '/yoga/check',
      builder: (_, state) => PoseCheckScreen(asanaId: state.extra as String),
    ),

    // Profile Module
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),

    // Plant Identifier Module
    GoRoute(path: '/plant/camera', builder: (_, __) => const PlantCameraScreen()),
    GoRoute(
      path: '/plant/confirm',
      builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>;
        return PlantConfirmationScreen(
          predictions: extras['predictions'] as List<PlantPrediction>,
          imageFile: extras['imageFile'] as File,
        );
      },
    ),
    GoRoute(
      path: '/plant/result',
      builder: (_, state) {
        final extras = state.extra as Map<String, dynamic>;
        return PlantResultScreen(
          plantKey: extras['plantKey'] as String,
          confidence: extras['confidence'] as double,
          capturedImage: extras['imageFile'] as File,
        );
      },
    ),
    GoRoute(
      path: '/plant/ask',
      builder: (_, state) => PlantAskScreen(plant: state.extra as Plant),
    ),

    // Plant Community Module (Module 7)
    GoRoute(path: '/community', builder: (_, __) => const CommunityHomeScreen()),

    // Packaged Food OCR Scanner
    GoRoute(path: '/packaged-food/scan', builder: (_, __) => const PackagedFoodScanScreen()),
    GoRoute(path: '/packaged-food/result', builder: (_, __) => const PackagedFoodResultScreen()),

    // Nadi Pariksha Feature
    GoRoute(path: '/nadi-pariksha', builder: (_, __) => const NadiParikshaScreen()),

    // Biometrics / Tongue Analysis
    GoRoute(path: '/tongue-capture', builder: (_, __) => const TongueCaptureScreen()),
    GoRoute(path: '/tongue-result', builder: (_, state) => TongueResultScreen(result: state.extra as Map<String, dynamic>)),

    // Biometrics / Eye Analysis
    GoRoute(path: '/eye-capture', builder: (_, __) => const EyeCaptureScreen()),
    GoRoute(path: '/eye-result', builder: (_, state) => EyeResultScreen(result: state.extra as Map<String, dynamic>)),
  ],
);
class AyushApp extends StatelessWidget {
  const AyushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AYUSH',
      debugShowCheckedModeBanner: false,
      theme: AyushTheme.light,
      routerConfig: _router,
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
