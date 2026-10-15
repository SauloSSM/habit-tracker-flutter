import '../models/app_user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract class AuthRepository {
  bool get isDemo;
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;
  Future<void> login(String email, String password);
  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
  );
  Future<void> updateName(String name);
  Future<String> requestPasswordReset(String email);
  Future<void> logout();
  Future<void> dispose();
}
