class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.mobile = '',
    required this.role,
    required this.status,
    required this.deviceId,
    required this.biometricEnabled,
  });

  final String id;
  final String email;
  final String name;
  final int? age;
  final String mobile;
  final String role;
  final String status;
  final String deviceId;
  final bool biometricEnabled;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as String,
        email: map['email'] as String,
        name: map['name'] as String,
        age: map['age'] as int?,
        mobile: (map['mobile'] as String?) ?? '',
        role: map['role'] as String,
        status: map['status'] as String,
        deviceId: map['device_id'] as String,
        biometricEnabled: (map['biometric_enabled'] as int) == 1,
      );

  factory AppUser.fromApi(Map<String, Object?> map) => AppUser(
        id: map['id'] as String,
        email: map['email'] as String,
        name: map['name'] as String,
        age: map['age'] as int?,
        mobile: (map['mobile'] as String?) ?? '',
        role: map['role'] as String,
        status: (map['status'] as String?) ?? 'active',
        deviceId: (map['deviceId'] as String?) ?? (map['device_id'] as String?) ?? '',
        biometricEnabled: (map['biometricEnabled'] as bool?) ?? false,
      );
}
