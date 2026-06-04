import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../mock/mock_data.dart';

/// Repositorio de autenticación para Web (sin SQLite ni WebSocket)
/// Usa los datos mock de mock_data.dart para autenticación
class AuthRepositoryWeb implements AuthRepository {
  User? _currentUser;

  @override
  Future<User> login(String username, String password) async {
    // Buscar usuario en mockUsers
    Map<String, dynamic>? userMatch;
    try {
      userMatch = mockUsers.firstWhere(
        (u) => u['username'] == username && u['password'] == password,
      );
    } catch (e) {
      userMatch = null;
    }

    if (userMatch == null) {
      throw AuthenticationException(
        message: 'Usuario o contraseña incorrectos',
        code: 'INVALID_CREDENTIALS',
      );
    }

    final userModel = UserModel.fromJson(userMatch);

    if (!userModel.activo) {
      throw AuthenticationException(
        message: 'El usuario está inactivo',
        code: 'USER_INACTIVE',
      );
    }

    _currentUser = userModel.toEntity();
    return _currentUser!;
  }

  @override
  Future<User> registerAsGuest(String username, String fullName) async {
    // Verificar si ya existe el username
    try {
      final existingUser = mockUsers.firstWhere(
        (u) => u['username'] == username,
      );
      if (existingUser.isNotEmpty) {
        throw AuthenticationException(
          message: 'El username ya está en uso',
          code: 'USER_EXISTS',
        );
      }
    } catch (e) {
      // Usuario no existe, continuar con registro
    }

    // Crear nuevo usuario guest
    final newUser = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      nombre: fullName,
      correo: null,
      username: username,
      password: 'guest123',
      perfil: 'Invitado',
      saldo: 2000000,
      activo: true,
      fechaRegistro: DateTime.now(),
    );

    _currentUser = newUser.toEntity();
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _currentUser != null;
  }
}
