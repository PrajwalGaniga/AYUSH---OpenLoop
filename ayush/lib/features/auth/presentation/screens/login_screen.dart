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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _countryCode = '+91';
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _login() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authProvider.notifier).login(
            phone: _fullPhone,
            password: _passCtrl.text,
          );
      if (!mounted) return;
      if (user.isOnboarded) {
        context.go('/home');
      } else {
        context.go('/onboarding/${user.onboardingStep}');
      }
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

              // ── Header ────────────────────────────────────────────────────
              _buildHeader()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2),

              const SizedBox(height: 48),

              // ── Form Card ─────────────────────────────────────────────────
              _buildFormCard()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 32),

              // ── Sign in button ────────────────────────────────────────────
              AyushButton(
                label: 'Sign In',
                onPressed: _isLoading ? null : _login,
                isLoading: _isLoading,
              ).animate(delay: 400.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 16),

              // ── Error message ─────────────────────────────────────────────
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

              // ── Register link ─────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: RichText(
                    text: TextSpan(
                      text: "New here? ",
                      style: AyushTextStyles.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Create account',
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
        // Logo mark
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AyushColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'आ',
              style: AyushTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Welcome back', style: AyushTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your wellness journey',
          style: AyushTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Phone field ────────────────────────────────────────────────
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
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  alignLeft: false,
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
                    validator: (v) {
                      final full = '$_countryCode${v?.trim() ?? ''}';
                      return AyushValidators.phone(full);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Password field ─────────────────────────────────────────────
          Text('Password', style: AyushTextStyles.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AyushColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: AyushValidators.password,
          ),
        ],
      ),
    );
  }
}
