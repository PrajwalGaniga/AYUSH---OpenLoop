import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env FIRST — all environment config is read from here
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: AyushApp(),
    ),
  );
}
