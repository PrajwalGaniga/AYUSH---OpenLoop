import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<UserModel> register({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {'phone': phone, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    // Register returns userId + token, phone is passed in
    return UserModel(
      userId: data['userId'],
      phone: phone,
      token: data['token'],
      isOnboarded: data['isOnboarded'] ?? false,
      onboardingStep: data['onboardingStep'] ?? 0,
    );
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'phone': phone, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    data['phone'] = phone;
    return UserModel.fromJson(data);
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final data = response.data['data'] as Map<String, dynamic>;
      // getMe doesn't return token — preserve from storage
      return UserModel(
        userId: data['userId'],
        phone: data['phone'] ?? '',
        token: '', // Will be filled from secure storage
        isOnboarded: data['isOnboarded'] ?? false,
        onboardingStep: data['onboardingStep'] ?? 0,
        profile: data['profile'],
      );
    } catch (_) {
      return null;
    }
  }
}
