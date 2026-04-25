import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EyeResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const EyeResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final int rednessIndex = result['redness_index'] ?? 0;
    final int jaundiceScore = result['jaundice_score'] ?? 0;
    final int healthScore = result['eye_health_score'] ?? 0;
    final bool jaundiceFlag = result['jaundice_flag'] ?? false;
    final String doshaSignal = result['dosha_signal'] ?? 'unknown';
    final String rednessClass = result['redness_classification'] ?? 'unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eye Analysis Result', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF161B22), Color(0xFF1D232C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: healthScore / 100,
                          backgroundColor: Colors.white10,
                          color: _getScoreColor(healthScore),
                          strokeWidth: 8,
                        ),
                      ),
                      Text(
                        '$healthScore',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Eye Health', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          _getHealthText(healthScore),
                          style: TextStyle(color: _getScoreColor(healthScore), fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Ayurvedic Insights', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            
            // Redness Classification
            _buildInsightCard(
              title: 'Sclera Redness',
              value: rednessClass.replaceAll('_', ' ').toUpperCase(),
              description: 'Redness Index: $rednessIndex/100',
              icon: Icons.remove_red_eye,
              color: _getRednessColor(rednessClass),
            ),
            
            const SizedBox(height: 16),
            
            // Jaundice Flag
            _buildInsightCard(
              title: 'Jaundice / Liver Health',
              value: jaundiceFlag ? 'DETECTED' : 'CLEAR',
              description: 'Yellowing Score: $jaundiceScore/100',
              icon: Icons.health_and_safety,
              color: jaundiceFlag ? Colors.amber : Colors.green,
            ),

            const SizedBox(height: 16),
            
            // Dosha Signal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.spa, color: Colors.blueAccent),
                      SizedBox(width: 12),
                      Text('Ayurvedic Recommendation', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doshaSignal,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  String _getHealthText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  Color _getRednessColor(String redness) {
    switch (redness) {
      case 'clear': return Colors.green;
      case 'mild_redness': return Colors.orangeAccent;
      case 'moderate_redness': return Colors.orange;
      case 'severe_redness': return Colors.redAccent;
      default: return Colors.grey;
    }
  }
}
