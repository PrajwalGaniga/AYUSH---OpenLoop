import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/widgets/ayush_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../checkins/providers/checkin_provider.dart';

class DailyCheckinCard extends ConsumerStatefulWidget {
  const DailyCheckinCard({super.key});

  @override
  ConsumerState<DailyCheckinCard> createState() => _DailyCheckinCardState();
}

class _DailyCheckinCardState extends ConsumerState<DailyCheckinCard> {
  double _sleep = 7.0;
  double _stress = 3.0;
  double _energy = 7.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkinProvider);

    if (state.isSuccess) {
      return Container(
        padding: const EdgeInsets.all(AyushSpacing.md),
        decoration: BoxDecoration(
          color: AyushColors.card,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          border: Border.all(color: AyushColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AyushColors.success),
            const SizedBox(width: AyushSpacing.sm),
            Text(
              "Daily check-in complete. Great job!",
              style: AyushTextStyles.bodyMedium.copyWith(color: AyushColors.success),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AyushSpacing.lg),
      decoration: BoxDecoration(
        color: AyushColors.card,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Daily Check-in", style: AyushTextStyles.h3),
          const SizedBox(height: AyushSpacing.xs),
          Text(
            "How are you feeling today?",
            style: AyushTextStyles.bodyMedium.copyWith(color: AyushColors.textMuted),
          ),
          const SizedBox(height: AyushSpacing.lg),

          // Sleep
          _buildSliderRow("Sleep Quality", _sleep, Icons.nightlight_round, (v) => setState(() => _sleep = v)),
          const SizedBox(height: AyushSpacing.md),

          // Stress
          _buildSliderRow("Stress Level", _stress, Icons.psychology, (v) => setState(() => _stress = v)),
          const SizedBox(height: AyushSpacing.md),

          // Energy
          _buildSliderRow("Energy Level", _energy, Icons.bolt, (v) => setState(() => _energy = v)),
          const SizedBox(height: AyushSpacing.lg),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AyushSpacing.sm),
              child: Text(
                state.error!,
                style: AyushTextStyles.bodySmall.copyWith(color: AyushColors.error),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: AyushButton(
              label: "Log Check-in",
              isLoading: state.isLoading,
              onPressed: () {
                final user = ref.read(authProvider).value;
                if (user != null) {
                  ref.read(checkinProvider.notifier).submitCheckin(
                    userId: user.userId,
                    sleepQuality: _sleep,
                    stressLevel: _stress,
                    energyLevel: _energy,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, IconData icon, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AyushColors.primary),
            const SizedBox(width: AyushSpacing.xs),
            Text(label, style: AyushTextStyles.bodyMedium),
            const Spacer(),
            Text(value.toStringAsFixed(1), style: AyushTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 18, // 0.5 increments
            activeColor: AyushColors.primary,
            inactiveColor: AyushColors.primary.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
