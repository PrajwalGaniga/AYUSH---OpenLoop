import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// AYUSH MaterialTheme — Light + Calm + Spacious
/// Positioning: Clinical-lifestyle hybrid
/// Primary: Deep Teal | Secondary: Herbal Green | Surface: Warm White
class AyushTheme {
  AyushTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AyushColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AyushColors.primarySurface,
      onPrimaryContainer: AyushColors.primaryDark,
      secondary: AyushColors.herbalGreen,
      onSecondary: Colors.white,
      secondaryContainer: AyushColors.herbalGreenLight,
      tertiary: AyushColors.gold,
      onTertiary: Colors.white,
      surface: AyushColors.card,
      onSurface: AyushColors.textPrimary,
      surfaceContainerHighest: AyushColors.surfaceVariant,
      outline: AyushColors.border,
      outlineVariant: AyushColors.divider,
      error: AyushColors.error,
      onError: Colors.white,
    );

    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AyushColors.background,

      // Text Theme — Inter base, Playfair for display
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 40, fontWeight: FontWeight.w700, color: AyushColors.textPrimary,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 32, fontWeight: FontWeight.w700, color: AyushColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w700, color: AyushColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: AyushColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: AyushColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: AyushColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AyushColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AyushColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AyushColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: AyushColors.textSecondary,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AyushColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AyushColors.primary.withOpacity(0.08),
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w700, color: AyushColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AyushColors.textPrimary, size: 24),
      ),

      // Elevated Button — Solid Teal Primary
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AyushColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AyushColors.border,
          disabledForegroundColor: AyushColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, AyushSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button — Teal Outline Secondary
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AyushColors.primary,
          side: const BorderSide(color: AyushColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, AyushSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AyushColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AyushColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          borderSide: const BorderSide(color: AyushColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          borderSide: const BorderSide(color: AyushColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          borderSide: const BorderSide(color: AyushColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          borderSide: const BorderSide(color: AyushColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusMd),
          borderSide: const BorderSide(color: AyushColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: AyushColors.textMuted,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14, color: AyushColors.textSecondary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12, color: AyushColors.error,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AyushColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          side: const BorderSide(color: AyushColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AyushColors.surfaceVariant,
        selectedColor: AyushColors.primarySurface,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusFull),
        ),
        side: const BorderSide(color: AyushColors.border),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AyushColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AyushColors.primary,
        linearTrackColor: AyushColors.divider,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AyushColors.primary,
        inactiveTrackColor: AyushColors.divider,
        thumbColor: AyushColors.primary,
        overlayColor: AyushColors.primary.withOpacity(0.12),
        valueIndicatorColor: AyushColors.primaryDark,
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AyushColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AyushColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
