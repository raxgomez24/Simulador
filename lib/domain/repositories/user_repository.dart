import '../entities/user.dart';

abstract class UserRepository {
  Future<User> getUserById(String id);
  Future<User> updateBalance(String userId, double newBalance);
  Future<List<User>> getAllUsers();
  Future<List<User>> getRanking();
  Future<User> createUser({
    required String nombre,
    String? correo,
    required String username,
    required String password,
    required String perfil,
    double? saldo,
    bool activo = true,
  });
  Future<User> updateUser({
    required String id,
    String? nombre,
    String? correo,
    String? username,
    String? password,
    String? perfil,
    double? saldo,
    bool? activo,
  });
  Future<bool> deleteUser(String id);
}
