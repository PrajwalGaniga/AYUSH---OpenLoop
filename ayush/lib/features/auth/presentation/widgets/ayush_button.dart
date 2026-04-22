import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Premium full-width button — the primary CTA throughout AYUSH
/// Supports: loading state, disabled state, icon prefix
class AyushButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final double? width;

  const AyushButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: AyushSpacing.buttonHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: isOutlined ? _buildOutlined(isDisabled) : _buildPrimary(isDisabled),
      ),
    );
  }

  Widget _buildPrimary(bool isDisabled) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? AyushColors.border
            : (backgroundColor ?? AyushColors.primary),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildOutlined(bool isDisabled) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled ? AyushColors.textMuted : AyushColors.primary,
        side: BorderSide(
          color: isDisabled ? AyushColors.border : AyushColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AyushTextStyles.buttonPrimary),
        ],
      );
    }

    return Text(
      label,
      style: isOutlined ? AyushTextStyles.buttonSecondary : AyushTextStyles.buttonPrimary,
    );
  }
}
