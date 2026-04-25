import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/sos/fall_detection_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env FIRST — all environment config is read from here
  await dotenv.load(fileName: '.env');

  // Initialize fall detection foreground service (does NOT start it — waits for user toggle)
  await FallDetectionManager.initialize();

  runApp(
    const ProviderScope(
      child: AyushApp(),
    ),
  );
}
