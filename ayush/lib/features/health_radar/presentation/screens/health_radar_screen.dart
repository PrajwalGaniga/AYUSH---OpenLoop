import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/radar_provider.dart';

class HealthRadarScreen extends ConsumerStatefulWidget {
  const HealthRadarScreen({super.key});

  @override
  ConsumerState<HealthRadarScreen> createState() => _HealthRadarScreenState();
}

class _HealthRadarScreenState extends ConsumerState<HealthRadarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        ref.read(radarProvider.notifier).fetchRadarAnalysis(user.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final radarState = ref.watch(radarProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B1410), // Deep radar dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text("Health Radar", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _buildBody(radarState),
    );
  }

  Widget _buildBody(RadarState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar, color: Colors.grey, size: 64)
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(authProvider).value;
                if (user != null) {
                  ref.read(radarProvider.notifier).fetchRadarAnalysis(user.userId);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a3a2a)),
              child: const Text("Refresh Radar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    if (state.data == null) {
      return const SizedBox.shrink();
    }

    final analysis = state.data!['analysis'] as Map<String, dynamic>;
    final forecast = analysis['forecast'] ?? 'stable';
    final alertLevel = analysis['alert_level'] ?? 'CLEAR';
    final String explanation = analysis['explanation']?.toString() ?? '';
    final interventions = (analysis['interventions'] as List?) ?? [];

    Color radarColor = const Color(0xFF52b788);
    if (alertLevel == 'CRITICAL') radarColor = Colors.redAccent;
    else if (alertLevel == 'WARNING') radarColor = Colors.orangeAccent;
    else if (alertLevel == 'WATCH') radarColor = Colors.yellowAccent;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Radar Visualization
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radarColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: radarColor.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner circles
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: radarColor.withValues(alpha: 0.5), width: 1),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: radarColor.withValues(alpha: 0.8), width: 1),
                    ),
                  ),
                  // Blinking dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: radarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: radarColor, blurRadius: 10, spreadRadius: 5)
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
                  // Sweep
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: null,
                      color: radarColor.withValues(alpha: 0.2),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          
          const SizedBox(height: 32),
          
          // Trajectory Prediction
          Text(
            "3-Day OJAS Trajectory",
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 2),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                forecast == 'rise' ? Icons.trending_up : (forecast == 'fall' ? Icons.trending_down : Icons.trending_flat),
                color: radarColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                forecast.toString().toUpperCase(),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: radarColor),
              ),
            ],
          ).animate().slideY(begin: 0.2, end: 0, delay: 500.ms).fadeIn(),

          const SizedBox(height: 32),

          // Glassmorphic Explanation Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: radarColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Physiological Insights",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: radarColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...explanation
                          .split('.')
                          .where((s) => s.trim().isNotEmpty)
                          .map((sentence) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: radarColor.withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${sentence.trim()}.',
                                        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, delay: 600.ms).fadeIn(),

          const SizedBox(height: 32),

          // Interventions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recommended Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),
                ...interventions.map((intervention) => _buildInterventionCard(intervention, radarColor)),
              ],
            ),
          ).animate().slideY(begin: 0.2, end: 0, delay: 700.ms).fadeIn(),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(dynamic intervention, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2620),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flash_on, color: accentColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intervention['title'] ?? 'Action Required',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  intervention['description'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.satellite_alt, color: Color(0xFF52b788), size: 64)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms)
              .shake(hz: 2),
          const SizedBox(height: 32),
          const Text(
            "Syncing with Predictive Engine...",
            style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
          const SizedBox(height: 12),
          const Text(
            "Analyzing your biomarkers securely...",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
