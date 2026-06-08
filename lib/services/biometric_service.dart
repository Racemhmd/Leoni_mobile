import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/storage_keys.dart';

class BiometricService {
  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns true if authentication succeeded.
  Future<bool> authenticate({
    String reason = 'Confirmez votre identité pour accéder à MotivUp',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final val = await _storage.read(key: StorageKeys.biometricEnabled);
    return val == 'true';
  }

  /// True when a JWT is already persisted (i.e. user has logged in at least once).
  Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: StorageKeys.authToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> enable() async {
    await _storage.write(key: StorageKeys.biometricEnabled, value: 'true');
  }

  Future<void> disable() async {
    await _storage.write(key: StorageKeys.biometricEnabled, value: 'false');
  }
}
