import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/mentor_type.dart';
import '../../../../services/mentor_service.dart';

class MentorSelectionScreen extends StatefulWidget {
  const MentorSelectionScreen({super.key});

  @override
  State<MentorSelectionScreen> createState() => _MentorSelectionScreenState();
}

class _MentorSelectionScreenState extends State<MentorSelectionScreen> {
  MentorType _selected = MentorType.rabbit;
  bool _isLoading = false;

  void _onContinue() async {
    setState(() => _isLoading = true);
    await MentorService.saveMentor(_selected);
    setState(() => _isLoading = false);
    
    if (mounted) {
      // Navigate to the next screen (e.g. home) after onboarding is done
      context.go('/home');
    }
  }

  Widget _buildMentorCard(MentorType mentor) {
    final isSelected = _selected == mentor;
    final isRabbit = mentor == MentorType.rabbit;

    String bestForText = '';
    if (isRabbit) {
      bestForText = 'Users who prefer focused, no-fluff guidance.';
    } else {
      bestForText = 'Users who feel overwhelmed and need patience.';
    }

    return GestureDetector(
      onTap: () => setState(() => _selected = mentor),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? mentor.accentColor.withOpacity(0.07) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? mentor.accentColor : Colors.grey.shade200,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Lottie.asset(
                    mentor.assetPath,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mentor.accentColor,
                        ),
                      ),
                      Text(
                        mentor.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mentor.personality,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Best for: $bestForText',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: mentor.accentColor,
                    size: 22,
                  )
                else
                  const SizedBox(width: 22), // Placeholder to keep alignment
              ],
            ),
          ),
          if (isRabbit)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mentor.accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Your Guide',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can change this anytime in My Prakriti.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              _buildMentorCard(MentorType.rabbit),
              _buildMentorCard(MentorType.sloth),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Continue with ${_selected.displayName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
