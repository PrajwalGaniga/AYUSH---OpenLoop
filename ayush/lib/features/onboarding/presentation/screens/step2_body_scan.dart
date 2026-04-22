import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/onboarding_models.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

// ── Body regions ──────────────────────────────────────────────────────────────
const _frontRegions = [
  BodyRegion('head', 'Head', Offset(0.5, 0.05), 28),
  BodyRegion('neck', 'Neck', Offset(0.5, 0.115), 16),
  BodyRegion('left_shoulder', 'L. Shoulder', Offset(0.28, 0.16), 22),
  BodyRegion('right_shoulder', 'R. Shoulder', Offset(0.72, 0.16), 22),
  BodyRegion('chest_left', 'L. Chest', Offset(0.38, 0.22), 20),
  BodyRegion('chest_right', 'R. Chest', Offset(0.62, 0.22), 20),
  BodyRegion('abdomen_upper', 'Upper Abdomen', Offset(0.5, 0.31), 22),
  BodyRegion('abdomen_lower', 'Lower Abdomen', Offset(0.5, 0.40), 22),
  BodyRegion('left_arm_upper', 'L. Upper Arm', Offset(0.22, 0.27), 16),
  BodyRegion('right_arm_upper', 'R. Upper Arm', Offset(0.78, 0.27), 16),
  BodyRegion('left_forearm', 'L. Forearm', Offset(0.18, 0.37), 16),
  BodyRegion('right_forearm', 'R. Forearm', Offset(0.82, 0.37), 16),
  BodyRegion('left_hand', 'L. Hand', Offset(0.14, 0.46), 14),
  BodyRegion('right_hand', 'R. Hand', Offset(0.86, 0.46), 14),
  BodyRegion('left_hip', 'L. Hip', Offset(0.38, 0.50), 18),
  BodyRegion('right_hip', 'R. Hip', Offset(0.62, 0.50), 18),
  BodyRegion('left_thigh', 'L. Thigh', Offset(0.38, 0.62), 20),
  BodyRegion('right_thigh', 'R. Thigh', Offset(0.62, 0.62), 20),
  BodyRegion('left_knee', 'L. Knee', Offset(0.38, 0.73), 16),
  BodyRegion('right_knee', 'R. Knee', Offset(0.62, 0.73), 16),
  BodyRegion('left_calf', 'L. Calf', Offset(0.38, 0.83), 16),
  BodyRegion('right_calf', 'R. Calf', Offset(0.62, 0.83), 16),
  BodyRegion('left_foot', 'L. Foot', Offset(0.36, 0.94), 14),
  BodyRegion('right_foot', 'R. Foot', Offset(0.64, 0.94), 14),
];

const _backRegions = [
  BodyRegion('upper_back', 'Upper Back', Offset(0.5, 0.19), 24),
  BodyRegion('mid_back', 'Mid Back', Offset(0.5, 0.28), 22),
  BodyRegion('lower_back', 'Lower Back', Offset(0.5, 0.38), 22),
  BodyRegion('left_shoulder_blade', 'L. Shoulder Blade', Offset(0.32, 0.21), 20),
  BodyRegion('right_shoulder_blade', 'R. Shoulder Blade', Offset(0.68, 0.21), 20),
  BodyRegion('left_glute', 'L. Glute', Offset(0.38, 0.50), 20),
  BodyRegion('right_glute', 'R. Glute', Offset(0.62, 0.50), 20),
  BodyRegion('left_hamstring', 'L. Hamstring', Offset(0.38, 0.64), 20),
  BodyRegion('right_hamstring', 'R. Hamstring', Offset(0.62, 0.64), 20),
  BodyRegion('left_calf_back', 'L. Calf (back)', Offset(0.38, 0.80), 16),
  BodyRegion('right_calf_back', 'R. Calf (back)', Offset(0.62, 0.80), 16),
];

class BodyRegion {
  final String id;
  final String label;
  final Offset position; // fractional position on body
  final double radius;

  const BodyRegion(this.id, this.label, this.position, this.radius);
}

class Step2BodyScan extends ConsumerStatefulWidget {
  const Step2BodyScan({super.key});

  @override
  ConsumerState<Step2BodyScan> createState() => _Step2BodyScanState();
}

class _Step2BodyScanState extends ConsumerState<Step2BodyScan>
    with SingleTickerProviderStateMixin {
  bool _showFront = true;
  bool _noPain = false;
  final Map<String, PainPoint> _selectedPoints = {};
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipBody() {
    HapticFeedback.lightImpact();
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  Color _severityColor(int severity) {
    if (severity <= 2) return AyushColors.warning;
    if (severity <= 4) return const Color(0xFFFF7043);
    return AyushColors.error;
  }

  Future<void> _onRegionTap(BodyRegion region) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PainInputSheet(
        region: region,
        existing: _selectedPoints[region.id],
        onSave: (point) => setState(() => _selectedPoints[region.id] = point),
        onRemove: () => setState(() => _selectedPoints.remove(region.id)),
      ),
    );
  }

  Future<void> _submit() async {
    final userId = ref.read(authProvider).value?.userId ?? '';
    ref.read(onboardingProvider.notifier).updatePainPoints(
          _noPain ? [] : _selectedPoints.values.toList(),
        );
    try {
      await ref.read(onboardingProvider.notifier).submitStep2(userId);
      if (mounted) context.go('/onboarding/2');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;
    final regions = _showFront ? _frontRegions : _backRegions;

    return OnboardingShell(
      currentStep: 1,
      child: Stack(
        children: [
          Column(
            children: [
              // ── Headline ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AyushSpacing.pagePadding, AyushSpacing.lg,
                  AyushSpacing.pagePadding, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Show us where\nit hurts', style: AyushTextStyles.h1)
                        .animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Tap any area — helps us understand your pain patterns',
                      style: AyushTextStyles.bodyMedium,
                    ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                    const SizedBox(height: 16),

                    // Front/Back toggle
                    _buildFlipToggle(),
                  ],
                ),
              ),

              // ── Body model ─────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return Stack(
                        children: [
                          // Body silhouette
                          Center(
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _BodyPainter(isFront: _showFront),
                            ),
                          ),

                          // Tappable hotspots
                          ...regions.map((region) {
                            final selected = _selectedPoints.containsKey(region.id);
                            final painPoint = _selectedPoints[region.id];
                            final color = selected
                                ? _severityColor(painPoint!.severity)
                                : Colors.transparent;

                            return Positioned(
                              left: region.position.dx * constraints.maxWidth - region.radius,
                              top: region.position.dy * constraints.maxHeight - region.radius,
                              child: GestureDetector(
                                onTap: _noPain ? null : () => _onRegionTap(region),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: region.radius * 2,
                                  height: region.radius * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? color.withOpacity(0.35)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected ? color : Colors.transparent,
                                      width: selected ? 2 : 0,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.5),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Selected chips ─────────────────────────────────────────────
              if (_selectedPoints.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _selectedPoints.entries.map((e) {
                      final color = _severityColor(e.value.severity);
                      return Chip(
                        label: Text(e.value.region.replaceAll('_', ' ').split(' ').map((w) =>
                          w[0].toUpperCase() + w.substring(1)).join(' ')),
                        avatar: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setState(() => _selectedPoints.remove(e.key)),
                        backgroundColor: color.withOpacity(0.1),
                        side: BorderSide(color: color.withOpacity(0.4)),
                        labelStyle: AyushTextStyles.labelSmall.copyWith(
                          color: AyushColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── No pain checkbox ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _noPain = !_noPain;
                    if (_noPain) _selectedPoints.clear();
                  }),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _noPain ? AyushColors.herbalGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _noPain ? AyushColors.herbalGreen : AyushColors.border,
                            width: 2,
                          ),
                        ),
                        child: _noPain
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "No pain areas — I'm pain-free",
                        style: AyushTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),

          // ── Continue button ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AyushSpacing.pagePadding),
              decoration: BoxDecoration(
                color: AyushColors.background,
                border: Border(top: BorderSide(color: AyushColors.divider)),
              ),
              child: AyushButton(
                label: 'Continue',
                onPressed: (_noPain || _selectedPoints.isNotEmpty) ? _submit : null,
                isLoading: isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AyushColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
          border: Border.all(color: AyushColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleTab('Front', _showFront),
            _buildToggleTab('Back', !_showFront),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab(String label, bool isActive) {
    return GestureDetector(
      onTap: _showFront == (label == 'Front') ? null : _flipBody,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AyushColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AyushTextStyles.labelSmall.copyWith(
            color: isActive ? Colors.white : AyushColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Body silhouette painter ──────────────────────────────────────────────────

class _BodyPainter extends CustomPainter {
  final bool isFront;
  _BodyPainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AyushColors.border.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = AyushColors.surfaceVariant.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final double cx = size.width / 2;
    final double h = size.height;

    // ── Head ──────────────────────────────────────────────────────────────
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, h * 0.06), width: 50, height: 60));
    canvas.drawPath(headPath, fillPaint);
    canvas.drawPath(headPath, outlinePaint);

    // ── Neck ──────────────────────────────────────────────────────────────
    final neckPath = Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, h * 0.12), width: 22, height: 22));
    canvas.drawPath(neckPath, fillPaint);

    // ── Torso ─────────────────────────────────────────────────────────────
    final torsoPath = Path();
    torsoPath.moveTo(cx - 52, h * 0.14); // left shoulder
    torsoPath.lineTo(cx + 52, h * 0.14); // right shoulder
    torsoPath.lineTo(cx + 38, h * 0.46); // right hip
    torsoPath.quadraticBezierTo(cx + 20, h * 0.50, cx, h * 0.50); // right hip curve
    torsoPath.quadraticBezierTo(cx - 20, h * 0.50, cx - 38, h * 0.46); // left hip curve
    torsoPath.close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // ── Left arm ──────────────────────────────────────────────────────────
    _drawArm(canvas, fillPaint, outlinePaint, cx - 55, h * 0.15, true, h);
    // ── Right arm ─────────────────────────────────────────────────────────
    _drawArm(canvas, fillPaint, outlinePaint, cx + 55, h * 0.15, false, h);

    // ── Legs ──────────────────────────────────────────────────────────────
    _drawLeg(canvas, fillPaint, outlinePaint, cx - 22, h * 0.50, h);
    _drawLeg(canvas, fillPaint, outlinePaint, cx + 22, h * 0.50, h);

    // ── Spine line (back view only) ───────────────────────────────────────
    if (!isFront) {
      final spinePaint = Paint()
        ..color = AyushColors.border.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, h * 0.14), Offset(cx, h * 0.46), spinePaint);
    }
  }

  void _drawArm(Canvas canvas, Paint fill, Paint stroke, double x, double y, bool isLeft, double h) {
    final path = Path();
    final sign = isLeft ? -1.0 : 1.0;
    path.moveTo(x - sign * 12, y);
    path.lineTo(x + sign * 12, y);
    path.lineTo(x + sign * 8, y + h * 0.32);
    path.lineTo(x - sign * 8, y + h * 0.32);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawLeg(Canvas canvas, Paint fill, Paint stroke, double x, double y, double h) {
    final path = Path();
    path.moveTo(x - 16, y);
    path.lineTo(x + 16, y);
    path.lineTo(x + 12, y + h * 0.48);
    path.lineTo(x - 12, y + h * 0.48);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) => oldDelegate.isFront != isFront;
}

// ── Pain input bottom sheet ──────────────────────────────────────────────────

class _PainInputSheet extends StatefulWidget {
  final BodyRegion region;
  final PainPoint? existing;
  final ValueChanged<PainPoint> onSave;
  final VoidCallback onRemove;

  const _PainInputSheet({
    required this.region,
    required this.existing,
    required this.onSave,
    required this.onRemove,
  });

  @override
  State<_PainInputSheet> createState() => _PainInputSheetState();
}

class _PainInputSheetState extends State<_PainInputSheet> {
  int _severity = 3;
  List<String> _timing = [];
  String _duration = '';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _severity = widget.existing!.severity;
      _timing = List.from(widget.existing!.timing);
      _duration = widget.existing!.duration;
    }
  }

  Color get _severityColor {
    if (_severity <= 2) return AyushColors.warning;
    if (_severity <= 4) return const Color(0xFFFF7043);
    return AyushColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 8, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AyushColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(widget.region.label, style: AyushTextStyles.h3),
          const SizedBox(height: 4),
          Text('Tell us more about the pain', style: AyushTextStyles.bodyMedium),
          const SizedBox(height: 24),

          // Severity
          Text('How severe is the pain?', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final val = i + 1;
              final isActive = val <= _severity;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _severity = val);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? _severityColor : AyushColors.surfaceVariant,
                    border: Border.all(
                      color: isActive ? _severityColor : AyushColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: AyushTextStyles.labelMedium.copyWith(
                        color: isActive ? Colors.white : AyushColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Timing
          Text('When does it hurt?', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Always', 'During activity', 'Morning', 'Night'].map((t) {
              final selected = _timing.contains(t);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) _timing.remove(t); else _timing.add(t);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                    border: Border.all(
                      color: selected ? AyushColors.primary : AyushColors.border,
                    ),
                  ),
                  child: Text(
                    t,
                    style: AyushTextStyles.labelSmall.copyWith(
                      color: selected ? AyushColors.primary : AyushColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration
          Text('How long have you had this?', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['< 1 week', '1–4 weeks', '1–6 months', '> 6 months'].map((d) {
              final selected = _duration == d;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _duration = d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                    border: Border.all(
                      color: selected ? AyushColors.primary : AyushColors.border,
                    ),
                  ),
                  child: Text(
                    d,
                    style: AyushTextStyles.labelSmall.copyWith(
                      color: selected ? AyushColors.primary : AyushColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              if (widget.existing != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.onRemove();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AyushColors.error,
                      side: const BorderSide(color: AyushColors.error),
                    ),
                  ),
                ),
              if (widget.existing != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(PainPoint(
                      region: widget.region.id,
                      severity: _severity,
                      timing: _timing,
                      duration: _duration,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
