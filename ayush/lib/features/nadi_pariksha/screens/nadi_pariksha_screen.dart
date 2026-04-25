import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

import '../utils/rppg_processor.dart';
import '../utils/nadi_mapper.dart';

class NadiParikshaScreen extends ConsumerStatefulWidget {
  const NadiParikshaScreen({super.key});

  @override
  ConsumerState<NadiParikshaScreen> createState() => _NadiParikshaScreenState();
}

class _NadiParikshaScreenState extends ConsumerState<NadiParikshaScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  final RppgProcessor _processor = RppgProcessor();

  // State
  bool _measuring = false;
  bool _fingerDetected = false;
  double? _currentBPM;
  NadiResult? _result;
  String _statusMessage = 'Place finger firmly on rear camera';
  List<FlSpot> _waveformSpots = [];
  int _frameCount = 0;
  Timer? _measurementTimer;
  int _secondsRemaining = 30;
  bool _isSaving = false;

  // Animation
  late AnimationController _pulseAnim;
  late AnimationController _resultAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _controller = CameraController(
        rear,
        ResolutionPreset.low, // low res = faster frame processing
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera initialization failed: $e';
        });
      }
    }
  }

  void _startMeasurement() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    WakelockPlus.enable();
    _processor.reset();
    _frameCount = 0;
    _currentBPM = null;
    _result = null;
    _waveformSpots = [];
    _secondsRemaining = 30;

    // Turn on flashlight to illuminate finger
    await _controller!.setFlashMode(FlashMode.torch);

    setState(() {
      _measuring = true;
      _statusMessage = 'Hold still... detecting pulse';
    });

    // Countdown timer
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _secondsRemaining--);
      }
      if (_secondsRemaining <= 0) {
        t.cancel();
        _stopMeasurement();
      }
    });

    // Process camera frames
    _controller!.startImageStream((CameraImage image) {
      _processFrame(image);
    });
  }

  void _processFrame(CameraImage image) {
    _frameCount++;
    // Sample every 2nd frame for performance
    if (_frameCount % 2 != 0) return;

    // Extract green channel average from YUV420 format
    final greenAvg = _extractGreen(image);
    final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Finger detection: when finger covers lens, green value drops significantly
    final isFingerCovered = greenAvg < 80.0;

    _processor.addFrame(greenAvg, timestamp);

    // Update waveform (keep last 60 points)
    final spotIndex = _waveformSpots.length.toDouble();
    _waveformSpots.add(FlSpot(spotIndex, greenAvg));
    if (_waveformSpots.length > 60) _waveformSpots.removeAt(0);
    // Re-index x values
    _waveformSpots = _waveformSpots
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.y))
        .toList();

    // Calculate BPM every 30 frames
    if (_frameCount % 30 == 0 && _processor.hasEnoughData) {
      final bpm = _processor.calculateBPM();
      if (mounted) {
        setState(() {
          _fingerDetected = isFingerCovered;
          _currentBPM = bpm;
          _statusMessage = !isFingerCovered
              ? 'Cover the camera completely with your finger'
              : bpm == null
                  ? 'Detecting pulse... hold still'
                  : 'Pulse detected: ${bpm.round()} BPM';
        });
      }
    } else if (_frameCount % 5 == 0 && mounted) {
      // Just update chart and finger detection fast
      setState(() {
        _fingerDetected = isFingerCovered;
      });
    }
  }

  double _extractGreen(CameraImage image) {
    // YUV420 plane 0 = Y (luminance), sufficient for rPPG
    // For better accuracy, use plane 1 (U/Cb) which encodes color
    final plane = image.planes[0];
    final bytes = plane.bytes;
    double sum = 0;
    int count = 0;
    // Sample center region of frame (finger is in center)
    final w = image.width;
    final h = image.height;
    final startX = (w * 0.3).round();
    final endX = (w * 0.7).round();
    final startY = (h * 0.3).round();
    final endY = (h * 0.7).round();

    for (int y = startY; y < endY; y += 4) {
      for (int x = startX; x < endX; x += 4) {
        sum += bytes[y * plane.bytesPerRow + x];
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  void _stopMeasurement() async {
    _measurementTimer?.cancel();
    if (_controller?.value.isStreamingImages == true) {
      await _controller!.stopImageStream();
    }
    await _controller?.setFlashMode(FlashMode.off);
    WakelockPlus.disable();

    final finalBPM = _currentBPM ?? _processor.calculateBPM();

    if (mounted) {
      setState(() {
        _measuring = false;
        if (finalBPM != null) {
          _result = NadiMapper.classify(finalBPM);
          _statusMessage = 'Reading complete. Saving to profile...';
          _resultAnim.forward(from: 0);
        } else {
          _statusMessage = 'Could not detect pulse. Try again in better light.';
        }
      });

      if (_result != null) {
        await _saveNadiResultToBackend(_result!, finalBPM!);
      }
    }
  }

  Future<void> _saveNadiResultToBackend(NadiResult result, double finalBPM) async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final userState = ref.read(authProvider).value;
      if (userState == null) throw Exception("User not logged in");
      
      final dio = ref.read(dioClientProvider);
      
      final payload = {
        "userId": userState.userId,
        "nadiType": result.nadiType,
        "bpm": finalBPM,
        "dominantDosha": result.dominantDosha,
        "confidence": result.confidence,
      };

      final response = await dio.post(
        ApiEndpoints.saveNadiResult,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nadi result saved to your profile!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _statusMessage = 'Result saved to profile';
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: ${e.response?.data?['detail'] ?? e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _measurementTimer?.cancel();
    _pulseAnim.dispose();
    _resultAnim.dispose();
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nadi Pariksha',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'नाडी परीक्षा — Pulse Diagnosis',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildCameraPreview(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            if (_measuring) ...[
              const SizedBox(height: 16),
              _buildWaveform(),
            ],
            if (_currentBPM != null && _measuring) ...[
              const SizedBox(height: 16),
              _buildLiveBPM(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
            const SizedBox(height: 30),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _fingerDetected ? const Color(0xFF4CAF50) : const Color(0xFF333333),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_controller?.value.isInitialized == true)
            Center(
              child: SizedBox(
                width: double.infinity,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.green)),
          // Overlay instructions
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 80 + _pulseAnim.value * 10,
                    height: 80 + _pulseAnim.value * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (_fingerDetected
                                ? const Color(0xFF4CAF50)
                                : Colors.white)
                            .withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _fingerDetected ? 'Finger detected' : 'Place finger here',
                    style: TextStyle(
                      color: _fingerDetected ? const Color(0xFF4CAF50) : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (_measuring)
            Text(
              '$_secondsRemaining s',
              style: const TextStyle(
                color: Color(0xFFE67E22),
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          if (_measuring) const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    if (_waveformSpots.length < 2) return const SizedBox.shrink();
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _waveformSpots,
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  Widget _buildLiveBPM() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Icon(
              Icons.favorite,
              color: Color.lerp(const Color(0xFFE74C3C), const Color(0xFFFF8A80),
                  _pulseAnim.value),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_currentBPM!.round()} BPM',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    final doshaColors = [
      const Color(0xFF9B59B6), // Vata — purple
      const Color(0xFFE74C3C), // Pitta — red
      const Color(0xFF3498DB), // Kapha — blue
    ];
    final color = doshaColors[r.dominantDosha];

    return FadeTransition(
      opacity: _resultAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.nadiType,
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.confidence.round()}% match',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r.sanskritName,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              r.pulse,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              r.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 16),
            _infoRow('Element', r.element, color),
            _infoRow('Imbalance signs', r.imbalanceSign, color),
            _infoRow('Recommendation', r.recommendation, color),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _measuring ? _stopMeasurement : _startMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: _measuring ? const Color(0xFF922B21) : const Color(0xFF1D6A96),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _measuring ? 'Stop measurement' : 'Start Nadi Pariksha',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
