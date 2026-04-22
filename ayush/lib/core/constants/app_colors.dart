import 'package:flutter/material.dart';

/// AYUSH Design System — Color Constants
/// ──────────────────────────────────────
/// Positioning: Clinical-lifestyle hybrid
/// Primary: Deep Teal (trust + modern healthcare)
/// Secondary: Muted Herbal Green + Warm Sand (Ayurvedic grounding)
/// Accent: Soft Gold (premium, used sparingly)
class AyushColors {
  AyushColors._();

  // ── Primary: Deep Teal ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1F7A8C);
  static const Color primaryDark = Color(0xFF0F4C5C);
  static const Color primaryLight = Color(0xFF3DA0B4);
  static const Color primarySurface = Color(0xFFE8F5F8); // Teal tint for surfaces

  // ── Secondary: Herbal Green ────────────────────────────────────────────────
  static const Color herbalGreen = Color(0xFF6BA368);
  static const Color herbalGreenLight = Color(0xFFE8F3E8);

  // ── Secondary: Warm Sand ───────────────────────────────────────────────────
  static const Color sand = Color(0xFFF4EDE4);
  static const Color sandDark = Color(0xFFE8D9CA);

  // ── Accent: Soft Gold (use sparingly) ─────────────────────────────────────
  static const Color gold = Color(0xFFC8A951);
  static const Color goldLight = Color(0xFFF7EACA);

  // ── Neutral System ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAFAFA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7F9);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dosha Colors ───────────────────────────────────────────────────────────
  static const Color vata = Color(0xFF7B68EE);   // Indigo-purple (Air + Space)
  static const Color pitta = Color(0xFFE07B54);  // Warm terracotta (Fire + Water)
  static const Color kapha = Color(0xFF4DB6AC);  // Teal-green (Earth + Water)
  static const Color vataLight = Color(0xFFF0EEFF);
  static const Color pittaLight = Color(0xFFFFF0EB);
  static const Color kaphaLight = Color(0xFFE8F7F6);

  // ── OJAS Score Bands ───────────────────────────────────────────────────────
  static const Color ojasExcellent = Color(0xFF22C55E); // 80–100
  static const Color ojasGood = Color(0xFF14B8A6);      // 60–79
  static const Color ojasAttention = Color(0xFFF59E0B); // 40–59
  static const Color ojasCritical = Color(0xFFEF4444);  // <40

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1F7A8C).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1F7A8C), Color(0xFF0F4C5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient herbalGradient = LinearGradient(
    colors: [Color(0xFF6BA368), Color(0xFF4A8A47)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC8A951), Color(0xFFB8922A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFF0F7F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
