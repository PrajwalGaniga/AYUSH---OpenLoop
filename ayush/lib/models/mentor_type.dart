import 'package:flutter/material.dart';

enum MentorType {
  rabbit(
    displayName: 'Shashi',
    subtitle: 'The Moon Guide',
    assetPath: 'assets/mentors/rabbit.json',
    accentColor: Color(0xFF7B6CF6),
    personality: 'Calm, focused, mindful. Speaks in short precise sentences.',
  ),
  sloth(
    displayName: 'Manda',
    subtitle: 'The Earth Guide',
    assetPath: 'assets/mentors/sloth.json',
    accentColor: Color(0xFF5D8A3C),
    personality: 'Warm, unhurried, patient. Never makes you feel rushed.',
  );

  final String displayName; // Note: 'name' is reserved for the enum value in Dart
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final String personality;

  const MentorType({
    required this.displayName,
    required this.subtitle,
    required this.assetPath,
    required this.accentColor,
    required this.personality,
  });
}
