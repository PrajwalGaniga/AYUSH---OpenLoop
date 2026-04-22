import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../env/env.dart';
import '../storage/secure_storage.dart';

/// Dio singleton with auth interceptor
/// Automatically attaches Bearer token from secure storage
class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _buildDio();
    return _instance!;
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor — attach token automatically
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Log errors in development
          if (Env.isDevelopment) {
            // ignore: avoid_print
            print('[Dio Error] ${error.requestOptions.path}: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

/// Riverpod provider for Dio instance
final dioClientProvider = Provider<Dio>((ref) => DioClient.instance);
