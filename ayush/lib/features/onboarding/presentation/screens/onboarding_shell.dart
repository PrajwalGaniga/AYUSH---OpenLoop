import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

const _stepLabels = [
  'Basic Profile',
  'Body Map',
  'Body Type',
  'Lifestyle',
  'Health History',
  'Reports',
];

/// Onboarding Shell — wraps all 6 steps with:
/// - Animated progress bar (6 dots + line)
/// - Step label
/// - Back button (hidden on step 0)
/// - Consistent teal-white header area
class OnboardingShell extends StatelessWidget {
  final Widget child;
  final int currentStep;
  final VoidCallback? onBack;

  const OnboardingShell({
    super.key,
    required this.child,
    required this.currentStep,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AyushSpacing.pagePadding,
        AyushSpacing.lg,
        AyushSpacing.pagePadding,
        AyushSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AyushColors.card,
        border: Border(bottom: BorderSide(color: AyushColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AyushColors.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: back + step label + spacer
          Row(
            children: [
              if (currentStep > 0)
                InkWell(
                  onTap: onBack ?? () => context.pop(),
                  borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AyushColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AyushColors.textSecondary,
                    ),
                  ),
                )
              else
                // Logo mark instead of back button on step 0
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AyushColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                  ),
                  child: Text(
                    'आ',
                    style: AyushTextStyles.labelMedium.copyWith(color: Colors.white),
                  ),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${currentStep + 1} of 6',
                      style: AyushTextStyles.caption.copyWith(
                        color: AyushColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _stepLabels[currentStep],
                      style: AyushTextStyles.labelMedium,
                    ),
                  ],
                ),
              ),

              // Completion percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AyushColors.primarySurface,
                  borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                ),
                child: Text(
                  '${((currentStep) * 16.7).round()}%',
                  style: AyushTextStyles.caption.copyWith(
                    color: AyushColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress dots
          _OnboardingProgressBar(currentStep: currentStep),
        ],
      ),
    );
  }
}

class _OnboardingProgressBar extends StatelessWidget {
  final int currentStep;

  const _OnboardingProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Row(
            children: [
              _buildDot(index),
              if (index < 5)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? AyushColors.primary
                          : AyushColors.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDot(int index) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 24 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: isCompleted
            ? AyushColors.primary
            : isCurrent
                ? AyushColors.primary
                : AyushColors.divider,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AyushColors.primary.withOpacity(0.35),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: isCompleted
          ? const Center(
              child: Icon(Icons.check, size: 8, color: Colors.white),
            )
          : null,
    );
  }
}
