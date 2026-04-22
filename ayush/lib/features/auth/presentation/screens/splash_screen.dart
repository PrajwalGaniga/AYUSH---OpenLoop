import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../providers/auth_provider.dart';

/// Splash Screen — auto-login check
/// ─────────────────────────────────
/// Shows AYUSH logo + tagline while checking stored token.
/// Routes to /home, /onboarding/0, or /login based on auth state.
/// NEVER shown again after first successful login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Minimum splash duration: 2.5 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        ref.read(authProvider.notifier).restoreSession(),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]).then((_) => _navigate());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    final user = ref.read(authProvider).value;
    if (user == null) {
      context.go('/login');
    } else if (user.isOnboarded) {
      context.go('/home');
    } else {
      context.go('/onboarding/${user.onboardingStep}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F4C5C),
              Color(0xFF1F7A8C),
              Color(0xFF0F4C5C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Subtle wave decoration
            Positioned(
              bottom: -60,
              left: -40,
              right: -40,
              child: _buildWaveDecoration(),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo circle
                  _buildLogoMark()
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.7, 0.7), duration: 800.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                    'AYUSH',
                    style: AyushTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 12),

                  Text(
                    'Your Ayurvedic Health Companion',
                    style: AyushTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 1.2,
                    ),
                  ).animate(delay: 600.ms).fadeIn(duration: 600.ms),

                  const SizedBox(height: 64),

                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Bottom tagline
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Powered by Gemini AI',
                textAlign: TextAlign.center,
                style: AyushTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ).animate(delay: 1200.ms).fadeIn(duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoMark() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2 + 0.1 * _pulseController.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AyushColors.gold.withOpacity(0.15 + 0.1 * _pulseController.value),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: Text(
          'आ',
          style: AyushTextStyles.displayLarge.copyWith(
            color: AyushColors.gold,
            fontSize: 42,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveDecoration() {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.2,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.8,
      size.width, size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
