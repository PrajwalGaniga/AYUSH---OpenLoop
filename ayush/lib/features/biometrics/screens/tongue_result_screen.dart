import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TongueResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const TongueResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final int coatingScore = result['coating_score'] ?? 0;
    final int colorScore = result['color_score'] ?? 0;
    final int healthScore = result['tongue_health_score'] ?? 0;
    final String amaLevel = result['ama_level'] ?? 'unknown';
    final String doshaSignal = result['dosha_signal'] ?? 'unknown';
    final String colorClass = result['color_classification'] ?? 'unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tongue Analysis Result', style: TextStyle(color: Colors.white)),
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
                        const Text('Overall Health', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
            
            // Ama Level
            _buildInsightCard(
              title: 'Ama (Toxins) Level',
              value: amaLevel.toUpperCase(),
              description: 'Coating Score: $coatingScore/100',
              icon: Icons.bubble_chart,
              color: _getAmaColor(amaLevel),
            ),
            
            const SizedBox(height: 16),
            
            // Color Classification
            _buildInsightCard(
              title: 'Tongue Color',
              value: colorClass.replaceAll('_', ' ').toUpperCase(),
              description: 'Color Health: $colorScore/100',
              icon: Icons.palette,
              color: _getColorClassColor(colorClass),
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
                      Icon(Icons.monitor_heart_outlined, color: Colors.orangeAccent),
                      SizedBox(width: 12),
                      Text('Dosha Signal', style: TextStyle(color: Colors.white70, fontSize: 16)),
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

  Color _getAmaColor(String ama) {
    switch (ama) {
      case 'none': return Colors.green;
      case 'mild': return Colors.lightGreen;
      case 'moderate': return Colors.orange;
      case 'heavy': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Color _getColorClassColor(String colorClass) {
    switch (colorClass) {
      case 'pink_healthy': return Colors.pinkAccent;
      case 'pale_white': return Colors.white70;
      case 'red': return Colors.red;
      case 'yellow': return Colors.amber;
      default: return Colors.grey;
    }
  }
}
