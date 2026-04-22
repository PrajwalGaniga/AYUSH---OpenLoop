import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration
/// All values loaded from .env file — NEVER hardcode keys
class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static bool get isDevelopment => appEnv == 'development';
}
