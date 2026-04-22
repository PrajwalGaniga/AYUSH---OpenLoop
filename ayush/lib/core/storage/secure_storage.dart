import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper — uses platform keychain (iOS Keychain / Android Keystore)
/// All auth tokens and user state persist here
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'ayush_token';
  static const _userIdKey = 'ayush_user_id';
  static const _isOnboardedKey = 'ayush_is_onboarded';
  static const _onboardingStepKey = 'ayush_onboarding_step';
  static const _phoneKey = 'ayush_phone';

  // ── Token ───────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── User ID ─────────────────────────────────────────────────────────────────
  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // ── Onboarding state ────────────────────────────────────────────────────────
  static Future<void> setOnboarded(bool value) =>
      _storage.write(key: _isOnboardedKey, value: value.toString());

  static Future<bool> isOnboarded() async {
    final val = await _storage.read(key: _isOnboardedKey);
    return val == 'true';
  }

  static Future<void> saveOnboardingStep(int step) =>
      _storage.write(key: _onboardingStepKey, value: step.toString());

  static Future<int> getOnboardingStep() async {
    final val = await _storage.read(key: _onboardingStepKey);
    return int.tryParse(val ?? '0') ?? 0;
  }

  // ── Phone ───────────────────────────────────────────────────────────────────
  static Future<void> savePhone(String phone) =>
      _storage.write(key: _phoneKey, value: phone);

  static Future<String?> getPhone() => _storage.read(key: _phoneKey);

  // ── Clear all (logout) ──────────────────────────────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();
}
