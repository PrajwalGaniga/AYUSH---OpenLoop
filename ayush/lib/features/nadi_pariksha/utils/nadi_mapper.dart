class NadiResult {
  final String nadiType;       // "Vata", "Pitta", "Kapha"
  final String sanskritName;   // "Vata Nadi", etc.
  final String pulse;          // "Irregular & thin", etc.
  final String description;
  final String element;        // "Air & Space", "Fire & Water", "Earth & Water"
  final String imbalanceSign;
  final String recommendation;
  final int dominantDosha;     // 0=Vata, 1=Pitta, 2=Kapha
  final double confidence;

  const NadiResult({
    required this.nadiType,
    required this.sanskritName,
    required this.pulse,
    required this.description,
    required this.element,
    required this.imbalanceSign,
    required this.recommendation,
    required this.dominantDosha,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'nadiType': nadiType,
      'sanskritName': sanskritName,
      'pulse': pulse,
      'description': description,
      'element': element,
      'imbalanceSign': imbalanceSign,
      'recommendation': recommendation,
      'dominantDosha': dominantDosha,
      'confidence': confidence,
    };
  }
}

class NadiMapper {
  /// Maps BPM to Ayurvedic Nadi Pariksha classification.
  /// Based on classical texts: Vata ~80+, Pitta ~70-80, Kapha ~60-70
  static NadiResult classify(double bpm, {double? heartRateVariability}) {
    if (bpm >= 80) {
      return NadiResult(
        nadiType: 'Vata',
        sanskritName: 'Vata Nadi — वात नाडी',
        pulse: 'Fast, thin & irregular (${bpm.round()} BPM)',
        description:
            'Your pulse moves like a serpent — quick, light, and irregular. '
            'This indicates Vata dominance: heightened nervous energy, creativity, and movement.',
        element: 'Air & Space (Vayu + Akasha)',
        imbalanceSign: 'Anxiety, dry skin, irregular digestion, insomnia',
        recommendation:
            'Favour warm, oily, grounding foods. Sesame oil massage (Abhyanga). '
            'Sleep by 10 PM. Reduce raw foods and cold drinks.',
        dominantDosha: 0,
        confidence: _confidence(bpm, 85, 10),
      );
    } else if (bpm >= 70) {
      return NadiResult(
        nadiType: 'Pitta',
        sanskritName: 'Pitta Nadi — पित्त नाडी',
        pulse: 'Sharp, strong & jumping (${bpm.round()} BPM)',
        description:
            'Your pulse leaps like a frog — sharp, strong, and purposeful. '
            'This indicates Pitta dominance: intelligence, drive, and transformation.',
        element: 'Fire & Water (Agni + Jala)',
        imbalanceSign: 'Inflammation, acidity, anger, skin rashes',
        recommendation:
            'Favour cooling foods — coconut water, coriander, sweet fruits. '
            'Avoid spicy, fried food. Moon-bathing and walks at dusk.',
        dominantDosha: 1,
        confidence: _confidence(bpm, 75, 5),
      );
    } else {
      return NadiResult(
        nadiType: 'Kapha',
        sanskritName: 'Kapha Nadi — कफ नाडी',
        pulse: 'Slow, heavy & steady (${bpm.round()} BPM)',
        description:
            'Your pulse glides like a swan — slow, heavy, and rhythmic. '
            'This indicates Kapha dominance: stability, endurance, and nourishment.',
        element: 'Earth & Water (Prithvi + Jala)',
        imbalanceSign: 'Weight gain, congestion, lethargy, attachment',
        recommendation:
            'Favour light, warm, spiced foods. Daily vigorous exercise. '
            'Dry ginger tea in the morning. Wake before sunrise.',
        dominantDosha: 2,
        confidence: _confidence(bpm, 62, 8),
      );
    }
  }

  static double _confidence(double bpm, double center, double spread) {
    final diff = (bpm - center).abs();
    return (1.0 - (diff / (spread * 3)).clamp(0.0, 1.0)) * 100;
  }
}
