// BUGFIX #001 — Clé canonique unique pour FlutterSecureStorage.
// Avant ce fix, api_service.dart écrivait sous 'token' et points_service.dart
// lisait sous 'auth_token', provoquant des 401 silencieux sur tous les appels points.
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String biometricEnabled = 'biometric_enabled';
}
