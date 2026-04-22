import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../screens/onboarding_shell.dart';
import '../../../../features/auth/presentation/widgets/ayush_button.dart';

final _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry', 'Chandigarh', 'Lakshadweep',
];

final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class Step1BasicProfile extends ConsumerStatefulWidget {
  const Step1BasicProfile({super.key});

  @override
  ConsumerState<Step1BasicProfile> createState() => _Step1BasicProfileState();
}

class _Step1BasicProfileState extends ConsumerState<Step1BasicProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  bool _useCm = true;
  double _heightCm = 165;
  double _heightFt = 5.4;
  bool _useKg = true;
  double _weightKg = 65;
  double _weightLbs = 143;
  String? _bloodGroup;
  String _language = 'en';
  String? _region;

  bool get _canContinue =>
      _nameCtrl.text.trim().length >= 2 &&
      _dob != null &&
      _gender != null &&
      _region != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 6, 15),
      firstDate: DateTime(1924),
      lastDate: DateTime.now().subtract(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AyushColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canContinue) return;

    ref.read(onboardingProvider.notifier).updateStep1(
          fullName: _nameCtrl.text.trim(),
          dob: _dob,
          gender: _gender,
          heightCm: _useCm ? _heightCm : (_heightFt * 30.48),
          weightKg: _useKg ? _weightKg : (_weightLbs * 0.453592),
          bloodGroup: _bloodGroup,
          language: _language,
          region: _region,
        );

    final userId = ref.read(authProvider).value?.userId ?? '';
    try {
      await ref.read(onboardingProvider.notifier).submitStep1(userId);
      if (mounted) context.go('/onboarding/1');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save. Please retry.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return OnboardingShell(
      currentStep: 0,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AyushSpacing.pagePadding, AyushSpacing.lg,
              AyushSpacing.pagePadding, 120,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Headline ─────────────────────────────────────────────
                  Text("Let's start with\nthe basics", style: AyushTextStyles.h1)
                      .animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    "We'll personalize everything just for you",
                    style: AyushTextStyles.bodyMedium,
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                  const SizedBox(height: 32),

                  // ── Full name ─────────────────────────────────────────────
                  _buildSectionLabel('Full Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Your full name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: AyushValidators.name,
                  ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Date of birth ─────────────────────────────────────────
                  _buildSectionLabel('Date of Birth'),
                  GestureDetector(
                    onTap: _pickDob,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AyushColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                        border: Border.all(
                          color: _dob != null ? AyushColors.primary : AyushColors.border,
                          width: _dob != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: _dob != null ? AyushColors.primary : AyushColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dob == null
                                ? Text('Select your date of birth', style: AyushTextStyles.bodyMedium)
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                                        style: AyushTextStyles.bodyLarge.copyWith(
                                          color: AyushColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${_computeAge(_dob!)} years old',
                                        style: AyushTextStyles.bodySmall.copyWith(
                                          color: AyushColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (_dob != null)
                            const Icon(Icons.check_circle, color: AyushColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Gender ────────────────────────────────────────────────
                  _buildSectionLabel('Gender'),
                  Row(
                    children: [
                      _buildGenderCard('Male', Icons.male_rounded, 'male'),
                      const SizedBox(width: 12),
                      _buildGenderCard('Female', Icons.female_rounded, 'female'),
                      const SizedBox(width: 12),
                      _buildGenderCard('Other', Icons.transgender_rounded, 'other'),
                    ],
                  ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Height ────────────────────────────────────────────────
                  _buildSectionLabel('Height'),
                  _buildMeasurementField(
                    isMetric: _useCm,
                    value: _useCm ? _heightCm : _heightFt,
                    metricLabel: 'cm',
                    imperialLabel: 'ft',
                    min: _useCm ? 100 : 3.5,
                    max: _useCm ? 250 : 8.0,
                    divisions: _useCm ? 150 : 45,
                    onToggle: () => setState(() => _useCm = !_useCm),
                    onChanged: (v) => setState(() {
                      if (_useCm) _heightCm = v; else _heightFt = v;
                    }),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Weight ────────────────────────────────────────────────
                  _buildSectionLabel('Weight'),
                  _buildMeasurementField(
                    isMetric: _useKg,
                    value: _useKg ? _weightKg : _weightLbs,
                    metricLabel: 'kg',
                    imperialLabel: 'lbs',
                    min: _useKg ? 30 : 66,
                    max: _useKg ? 200 : 440,
                    divisions: _useKg ? 170 : 374,
                    onToggle: () => setState(() => _useKg = !_useKg),
                    onChanged: (v) => setState(() {
                      if (_useKg) _weightKg = v; else _weightLbs = v;
                    }),
                  ).animate(delay: 350.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Blood group ───────────────────────────────────────────
                  _buildSectionLabel('Blood Group (optional)'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _bloodGroups.map((bg) {
                        final isSelected = _bloodGroup == bg;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _bloodGroup = isSelected ? null : bg),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                                border: Border.all(
                                  color: isSelected ? AyushColors.primary : AyushColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                bg,
                                style: AyushTextStyles.labelMedium.copyWith(
                                  color: isSelected ? AyushColors.primary : AyushColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Language ──────────────────────────────────────────────
                  _buildSectionLabel('Preferred Language'),
                  Row(
                    children: [
                      Expanded(child: _buildLangCard('English', 'en', 'A')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLangCard('ಕನ್ನಡ', 'kn', 'ಕ')),
                    ],
                  ).animate(delay: 450.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Region ────────────────────────────────────────────────
                  _buildSectionLabel('Region / State'),
                  DropdownButtonFormField<String>(
                    value: _region,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select your state',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    items: _indianStates
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _region = v),
                  ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Sticky Continue button ────────────────────────────────────────
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
                onPressed: _canContinue ? _submit : null,
                isLoading: isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AyushTextStyles.labelMedium),
    );
  }

  Widget _buildGenderCard(String label, IconData icon, String value) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AyushColors.primary : AyushColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AyushColors.primary : AyushColors.textMuted, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: AyushTextStyles.labelSmall.copyWith(
                  color: isSelected ? AyushColors.primary : AyushColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementField({
    required bool isMetric,
    required double value,
    required String metricLabel,
    required String imperialLabel,
    required double min,
    required double max,
    required int divisions,
    required VoidCallback onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AyushSpacing.cardPaddingSmall),
      decoration: BoxDecoration(
        color: AyushColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
        border: Border.all(color: AyushColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${value.toStringAsFixed(isMetric ? 0 : 1)} ${isMetric ? metricLabel : imperialLabel}',
                style: AyushTextStyles.h3.copyWith(color: AyushColors.primary),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AyushColors.primarySurface,
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
                  ),
                  child: Text(
                    isMetric ? metricLabel : imperialLabel,
                    style: AyushTextStyles.labelSmall.copyWith(color: AyushColors.primary),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String label, String code, String glyph) {
    final isSelected = _language == code;
    return GestureDetector(
      onTap: () => setState(() => _language = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AyushColors.primarySurface : AyushColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AyushColors.primary : AyushColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              glyph,
              style: AyushTextStyles.h2.copyWith(
                color: isSelected ? AyushColors.primary : AyushColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AyushTextStyles.labelSmall.copyWith(
                color: isSelected ? AyushColors.primary : AyushColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
