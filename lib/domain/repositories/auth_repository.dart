import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> registerAsGuest(String username, String fullName);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isAuthenticated();
}
