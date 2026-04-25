import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:convert';
import '../models/plant_prediction.dart';

class PlantClassifierService {
  static PlantClassifierService? _instance;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Constants configured for plant_classifier_int8.tflite
  static const int kInputSize = 380;

  static PlantClassifierService get instance {
    _instance ??= PlantClassifierService._();
    return _instance!;
  }
  PlantClassifierService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load labels from metadata
    final metaString = await rootBundle.loadString('assets/data/plant_knowledge.json');
    final meta = jsonDecode(metaString);
    _labels = List<String>.from(meta['metadata']['tflite_class_order']);

    // Load TFLite model
    final options = InterpreterOptions()..threads = 2;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/plant_classifier_int8.tflite',
      options: options,
    );

    _isInitialized = true;
  }

  Future<List<PlantPrediction>> classify(File imageFile) async {
    if (!_isInitialized) await initialize();

    // 1. Decode and resize image
    final rawImage = img.decodeImage(await imageFile.readAsBytes());
    if (rawImage == null) throw Exception('Could not decode image');

    final resized = img.copyResize(rawImage, width: kInputSize, height: kInputSize);

    // 2. Build input tensor (Uint8, 380x380)
    // The Python code casts the image directly to uint8, so no normalization is applied.
    final inputBytes = Uint8List(kInputSize * kInputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < kInputSize; y++) {
      for (int x = 0; x < kInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputBytes[pixelIndex++] = pixel.r.round().clamp(0, 255);
        inputBytes[pixelIndex++] = pixel.g.round().clamp(0, 255);
        inputBytes[pixelIndex++] = pixel.b.round().clamp(0, 255);
      }
    }

    // Input shape: [1, 380, 380, 3]
    final input = inputBytes.reshape([1, kInputSize, kInputSize, 3]);

    // 3. Prepare output tensor
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputType = _interpreter!.getOutputTensor(0).type;
    
    // Check if output is int8 or float32 and run interpreter
    List<double> floatScores;
    
    if (outputType == TensorType.float32) {
      final outputBuffer = List<double>.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);
      _interpreter!.run(input, outputBuffer);
      floatScores = List<double>.from(outputBuffer[0]);
    } else {
      // Int8 output handling
      final outputBuffer = Int8List(outputShape[1]).reshape([1, outputShape[1]]);
      _interpreter!.run(input, outputBuffer);
      
      final outputTensor = _interpreter!.getOutputTensor(0);
      final scale = outputTensor.params.scale;
      final zeroPoint = outputTensor.params.zeroPoint;
      
      final rawOutput = outputBuffer[0] as List;
      floatScores = List<double>.generate(
        rawOutput.length,
        (i) => (rawOutput[i] - zeroPoint) * scale,
      );
    }

    // 4. Apply softmax
    final maxScore = floatScores.reduce((a, b) => a > b ? a : b);
    final expList = floatScores.map((s) {
      final e = s - maxScore;
      return e < -88 ? 0.0 : math.exp(e);
    }).toList();
    final sumExp = expList.reduce((a, b) => a + b);
    final softmax = expList.map((e) => e / sumExp).toList();

    // 5. Sort and take top 3
    final indexed = List.generate(softmax.length, (i) => MapEntry(i, softmax[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));
    final top3 = indexed.take(3).toList();

    return top3.map((entry) {
      final labelKey = entry.key < _labels.length ? _labels[entry.key] : 'unknown';
      return PlantPrediction(
        plantKey: labelKey,
        plantName: labelKey.replaceAll('_', ' ').replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase()),
        confidence: entry.value,
      );
    }).toList();
  }
}
