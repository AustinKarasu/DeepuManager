import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService(this._auth);

  final LocalAuthentication _auth;

  static final instance = BiometricService(LocalAuthentication());

  Future<bool> canUseBiometrics() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }

  Future<bool> authenticate() async {
    if (!await canUseBiometrics()) return false;
    return _auth.authenticate(
      localizedReason: 'Authenticate to unlock Deepu Manager',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}
