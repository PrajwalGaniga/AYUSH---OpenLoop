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
import 'core/theme/app_theme.dart';

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
