import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

class TongueCaptureScreen extends ConsumerStatefulWidget {
  const TongueCaptureScreen({super.key});

  @override
  ConsumerState<TongueCaptureScreen> createState() => _TongueCaptureScreenState();
}

class _TongueCaptureScreenState extends ConsumerState<TongueCaptureScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  
  bool _isBusy = false;
  bool _faceAligned = false;
  bool _useFrontCamera = true;
  int _countdown = 0;
  Timer? _countdownTimer;
  String _instructionText = "Align your face in the oval";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final targetDirection = _useFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
      final targetCamera = cameras.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      if (mounted) {
        setState(() {
          _instructionText = "Failed to initialize camera: $e";
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted) return;
    _isBusy = true;

    try {
      final inputImage = _createInputImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      
      bool isAligned = false;
      if (faces.isNotEmpty) {
        final face = faces.first;
        // Simple heuristic: face should cover a decent portion of the screen 
        // but not be completely off-center.
        final imgSize = image.width * image.height;
        final faceSize = face.boundingBox.width * face.boundingBox.height;
        
        if (faceSize > imgSize * 0.15) {
          isAligned = true;
        }
      }

      if (mounted) {
        if (isAligned && !_faceAligned) {
          setState(() {
            _faceAligned = true;
            _instructionText = "Stick out your tongue! Capturing in 3...";
          });
          _startCountdown();
        } else if (!isAligned && _faceAligned) {
          _cancelCountdown();
          setState(() {
            _faceAligned = false;
            _instructionText = "Align your face in the oval";
          });
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    if (format == null || 
       (Platform.isAndroid && format != InputImageFormat.nv21) ||
       (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown > 0) {
          _instructionText = "Stick out your tongue! Capturing in $_countdown...";
        } else {
          _instructionText = "Capturing...";
          _captureAndAnalyze();
          timer.cancel();
        }
      });
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdown = 0;
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      await _cameraController!.stopImageStream();
      final XFile file = await _cameraController!.takePicture();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text(
                  "Analyzing Tongue...",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );

      final dio = ref.read(dioClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'tongue.jpg'),
      });

      final response = await dio.post(
        ApiEndpoints.tongueAnalyze,
        data: formData,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog

      if (response.statusCode == 200) {
        context.pushReplacement('/tongue-result', extra: response.data['data']);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close dialog if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze tongue: $e'), backgroundColor: Colors.red),
        );
        // Restart stream so user can try again
        _faceAligned = false;
        _instructionText = "Align your face in the oval";
        _cameraController!.startImageStream(_processCameraImage);
      }
    }
  }

  void _switchCamera() {
    setState(() {
      _useFrontCamera = !_useFrontCamera;
    });
    _cameraController?.dispose();
    _cameraController = null;
    _initializeCamera();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraController?.value.isInitialized == true)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator()),
          
          // Oval overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.black, // This creates the cutout
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border for the oval
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _faceAligned ? Colors.green : Colors.white54,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // Top App Bar
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _instructionText,
                  style: TextStyle(
                    color: _faceAligned ? Colors.green : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Manual Capture Button (Fallback)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _cancelCountdown();
                  _captureAndAnalyze();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
