import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';

class PoseCheckScreen extends StatefulWidget {
  final String asanaId;
  const PoseCheckScreen({required this.asanaId, super.key});

  @override
  State<PoseCheckScreen> createState() => _PoseCheckScreenState();
}

class _PoseCheckScreenState extends State<PoseCheckScreen> {
  CameraController? _cameraController;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _lastResponse;
  
  final FlutterTts _tts = FlutterTts();
  String _lastSpokenCorrection = "";
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});

      _startAnalysisLoop();
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _startAnalysisLoop() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (_isAnalyzing || _cameraController == null || !_cameraController!.value.isInitialized) return;
      
      _isAnalyzing = true;
      try {
        final XFile imageFile = await _cameraController!.takePicture();
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Calculate aspect ratio / sizes for the backend
        final int width = _cameraController!.value.previewSize?.height.toInt() ?? 640;
        final int height = _cameraController!.value.previewSize?.width.toInt() ?? 480;

        final response = await DioClient.instance.post(
          '/yoga/check-pose',
          data: {
            "asana_id": widget.asanaId,
            "frame_base64": base64Image,
            "frame_width": width,
            "frame_height": height,
          },
        );

        if (mounted) {
          setState(() {
            _lastResponse = response.data;
          });
          _handleSpeechFeedback(response.data);
        }
      } catch (e) {
        debugPrint("Pose Analysis Error: $e");
      } finally {
        _isAnalyzing = false;
      }
    });
  }

  void _handleSpeechFeedback(Map<String, dynamic> data) {
    if (!data['landmarks_visible']) {
      _speak(data['visibility_message'] ?? "Move back to show your full body.");
      return;
    }

    if (data['overall_correct']) {
      _speak("Good posture. Hold steady.");
    } else {
      _speak(data['primary_correction'] ?? "Adjust your pose.");
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final now = DateTime.now();
    // Don't repeat the exact same text within 5 seconds to avoid spamming
    if (text == _lastSpokenCorrection && now.difference(_lastSpokenTime).inSeconds < 5) {
      return;
    }
    
    await _tts.speak(text);
    _lastSpokenCorrection = text;
    _lastSpokenTime = now;
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AyushColors.primary)),
      );
    }

    final double accuracy = (_lastResponse?['accuracy_percent'] as num?)?.toDouble() ?? 0.0;
    final String correctionText = _lastResponse?['landmarks_visible'] == false 
        ? (_lastResponse?['visibility_message'] ?? "Step back") 
        : (_lastResponse?['primary_correction'] ?? "Analyzing...");
    
    final bool isCorrect = _lastResponse?['overall_correct'] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: Transform.scale(
              scaleX: -1, // Mirror front camera
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Skeleton Overlay
          if (_lastResponse != null && _lastResponse!['landmarks'] != null)
            Positioned.fill(
              child: Transform.scale(
                scaleX: -1,
                child: CustomPaint(
                  painter: SkeletonPainter(
                    landmarks: List<Map<String, dynamic>>.from(_lastResponse!['landmarks']),
                    jointFeedbacks: List<Map<String, dynamic>>.from(_lastResponse!['joint_feedbacks'] ?? []),
                  ),
                ),
              ),
            ),

          // Header
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Accuracy Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCorrect ? Colors.green : (accuracy > 40 ? Colors.orange : Colors.red),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "${accuracy.round()}%",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                )
              ],
            ),
          ),

          // Feedback Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 24, bottom: 40, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                )
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? "POSTURE CORRECT" : "ADJUST POSTURE",
                        style: AyushTextStyles.labelSmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    correctionText,
                    style: AyushTextStyles.h2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw Mediapipe skeleton over the camera preview
class SkeletonPainter extends CustomPainter {
  final List<Map<String, dynamic>> landmarks;
  final List<Map<String, dynamic>> jointFeedbacks;

  static const List<List<int>> connections = [
    [11, 12], [11, 13], [13, 15], [12, 14], [14, 16],
    [11, 23], [12, 24], [23, 24],
    [23, 25], [25, 27], [24, 26], [26, 28]
  ];

  SkeletonPainter({required this.landmarks, required this.jointFeedbacks});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final paintCorrect = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintIncorrect = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    Set<int> incorrectJointIds = {};
    for (var fb in jointFeedbacks) {
      if (fb['is_correct'] == false) {
        final name = fb['joint_name'];
        if (name == 'left_knee_angle') incorrectJointIds.add(25);
        if (name == 'right_knee_angle') incorrectJointIds.add(26);
        if (name == 'left_hip_angle') incorrectJointIds.add(23);
        if (name == 'right_hip_angle') incorrectJointIds.add(24);
        if (name == 'left_elbow_angle') incorrectJointIds.add(13);
        if (name == 'right_elbow_angle') incorrectJointIds.add(14);
        if (name == 'left_shoulder_angle') incorrectJointIds.add(11);
        if (name == 'right_shoulder_angle') incorrectJointIds.add(12);
        if (name == 'spine_vertical_angle') incorrectJointIds.addAll([11, 12, 23, 24]);
      }
    }

    // Draw connections
    for (var conn in connections) {
      if (conn[0] >= landmarks.length || conn[1] >= landmarks.length) continue;
      
      final lm1 = landmarks[conn[0]];
      final lm2 = landmarks[conn[1]];
      if ((lm1['visibility'] ?? 0) < 0.3 || (lm2['visibility'] ?? 0) < 0.3) continue;

      final p1 = Offset(lm1['x'] * size.width, lm1['y'] * size.height);
      final p2 = Offset(lm2['x'] * size.width, lm2['y'] * size.height);

      final hasError = incorrectJointIds.contains(conn[0]) || incorrectJointIds.contains(conn[1]);
      canvas.drawLine(p1, p2, hasError ? paintIncorrect : paintCorrect);
    }

    // Draw points
    for (int i = 0; i < landmarks.length; i++) {
      final lm = landmarks[i];
      if ((lm['visibility'] ?? 0) < 0.3) continue;
      
      final p = Offset(lm['x'] * size.width, lm['y'] * size.height);
      final hasError = incorrectJointIds.contains(i);
      
      canvas.drawCircle(p, 6.0, hasError ? paintIncorrect : paintCorrect);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
