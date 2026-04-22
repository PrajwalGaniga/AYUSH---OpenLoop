import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

// ── Repository provider ──────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioClientProvider));
});

// ── Current user state ───────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  /// Called on splash — check saved token and restore session
  Future<void> restoreSession() async {
    state = const AsyncValue.loading();
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _repo.getMe();
      if (user == null) {
        await SecureStorage.clearAll();
        state = const AsyncValue.data(null);
        return;
      }
      // Restore token from storage
      final fullUser = user.copyWith(token: token);
      state = AsyncValue.data(fullUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(phone: phone, password: password);
      await _persistUser(user);
      state = AsyncValue.data(user);
      return user;
    } on DioException catch (e) {
      state = const AsyncValue.data(null);
      final msg = e.response?.data?['detail'] ?? 'Login failed';
      throw Exception(msg);
    }
  }

  Future<UserModel> register({
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(phone: phone, password: password);
      await _persistUser(user);
      state = AsyncValue.data(user);
      return user;
    } on DioException catch (e) {
      state = const AsyncValue.data(null);
      final msg = e.response?.data?['detail'] ?? 'Registration failed';
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AsyncValue.data(null);
  }

  Future<void> _persistUser(UserModel user) async {
    await SecureStorage.saveToken(user.token);
    await SecureStorage.saveUserId(user.userId);
    await SecureStorage.setOnboarded(user.isOnboarded);
    await SecureStorage.saveOnboardingStep(user.onboardingStep);
    await SecureStorage.savePhone(user.phone);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value != null;
});
