import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AYUSH Typography System
/// ────────────────────────
/// Headings: Playfair Display (semi-serif — premium feel)
/// Body: Inter (clean, readable)
/// Labels: Inter Medium
class AyushTextStyles {
  AyushTextStyles._();

  // ── Display (Hero headings) ────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AyushColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.15,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AyushColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  // ── Headings ───────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AyushColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static TextStyle get h2 => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AyushColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AyushColors.textPrimary,
        height: 1.35,
      );

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AyushColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AyushColors.textSecondary,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AyushColors.textMuted,
        height: 1.5,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AyushColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AyushColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AyushColors.textSecondary,
        letterSpacing: 0.2,
      );

  // ── Caption ────────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AyushColors.textMuted,
        letterSpacing: 0.3,
      );

  // ── Button ─────────────────────────────────────────────────────────────────
  static TextStyle get buttonPrimary => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AyushColors.textOnPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSecondary => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AyushColors.primary,
        letterSpacing: 0.2,
      );

  // ── Dosha Labels ───────────────────────────────────────────────────────────
  static TextStyle get doshaBadge => GoogleFonts.playfairDisplay(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // ── OJAS Score ─────────────────────────────────────────────────────────────
  static TextStyle get ojasScore => GoogleFonts.playfairDisplay(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );
}
