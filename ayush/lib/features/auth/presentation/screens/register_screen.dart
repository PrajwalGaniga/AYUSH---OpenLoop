import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../widgets/ayush_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _countryCode = '+91';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      setState(() {
        _passwordStrength = AyushValidators.passwordStrength(_passCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _register() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).register(
            phone: _fullPhone,
            password: _passCtrl.text,
          );
      if (!mounted) return;
      context.go('/onboarding/0');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AyushSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              _buildHeader()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2),

              const SizedBox(height: 48),

              _buildForm()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 32),

              AyushButton(
                label: 'Create Account',
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
              ).animate(delay: 400.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AyushColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
                    border: Border.all(color: AyushColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AyushColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AyushTextStyles.bodySmall.copyWith(color: AyushColors.error),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).shakeX(),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: AyushTextStyles.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: AyushTextStyles.bodyMedium.copyWith(
                            color: AyushColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AyushColors.herbalGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.spa_outlined, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        Text('Begin your journey', style: AyushTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Create your AYUSH account — takes 2 minutes',
          style: AyushTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Phone ───────────────────────────────────────────────────────
          Text('Phone Number', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AyushColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
              border: Border.all(color: AyushColors.border),
            ),
            child: Row(
              children: [
                CountryCodePicker(
                  onChanged: (code) => setState(() => _countryCode = code.dialCode ?? '+91'),
                  initialSelection: 'IN',
                  favorite: const ['+91', 'IN'],
                  textStyle: AyushTextStyles.bodyLarge,
                ),
                Container(width: 1, height: 24, color: AyushColors.border),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'XXXXX XXXXX',
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                      fillColor: Colors.transparent,
                      filled: false,
                    ),
                    validator: (v) => AyushValidators.phone('$_countryCode${v?.trim() ?? ''}'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Password ─────────────────────────────────────────────────────
          Text('Password', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: 'Create a password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AyushColors.textMuted, size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: AyushValidators.password,
          ),

          // ── Password strength bar ─────────────────────────────────────────
          if (_passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStrengthBar(),
          ],

          const SizedBox(height: 20),

          // ── Confirm password ──────────────────────────────────────────────
          Text('Confirm Password', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Repeat your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AyushColors.textMuted, size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) => AyushValidators.confirmPassword(v, _passCtrl.text),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar() {
    const labels = ['', 'Weak', 'Fair', 'Strong'];
    const colors = [
      Colors.transparent,
      AyushColors.error,
      AyushColors.warning,
      AyushColors.herbalGreen,
    ];

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength / 3,
              backgroundColor: AyushColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(colors[_passwordStrength]),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          labels[_passwordStrength],
          style: AyushTextStyles.labelSmall.copyWith(
            color: colors[_passwordStrength],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
