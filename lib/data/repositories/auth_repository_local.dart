import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/exceptions.dart';
import '../database/database_seeder.dart';
import '../database/user_dao.dart';
import '../models/user_model.dart';
import '../../core/services/credentials_service.dart';

class AuthRepositoryLocal implements AuthRepository {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  final UserDao _userDao = UserDao();
  final CredentialsService _credentialsService = CredentialsService();

  User? _currentUser;
  bool _isInitialized = false;

  /// Initialize database and seed data if needed
  Future<void> _initializeDatabase() async {
    if (_isInitialized) return;

    try {
      await _seeder.seedAll();
      _isInitialized = true;
    } catch (e) {
      throw DatabaseException(
        message: 'Error initializing database: $e',
        code: 'DB_INIT_ERROR',
      );
    }
  }

  @override
  Future<User> login(String username, String password) async {
    await _initializeDatabase();

    try {
      UserModel? userModel;

      // Primero intentar autenticar usando el archivo de credenciales externo
      try {
        final credentialsFileExists = await _credentialsService.credentialsFileExists();
        if (credentialsFileExists) {
          final userCredentials = await _credentialsService.findUser(username, password);
          if (userCredentials != null) {
            // Usuario encontrado en archivo de credenciales
            userModel = UserModel.fromJson(userCredentials);

            // Verificar si el usuario está activo
            if (!userModel.activo) {
              throw AuthenticationException(
                message: 'El usuario está inactivo',
                code: 'USER_INACTIVE',
              );
            }

            _currentUser = userModel.toEntity();
            return _currentUser!;
          }
          // Si no se encuentra en el archivo, continuar con la base de datos
        }
      } catch (e) {
        // Si hay error al leer el archivo, continuar con base de datos
        print('Error al leer archivo de credenciales, usando base de datos: $e');
      }

      // Si no se encontró en el archivo o el archivo no existe, buscar en base de datos
      userModel = await _userDao.authenticate(username, password);

      if (userModel == null) {
        throw AuthenticationException(
          message: 'Usuario o contraseña incorrectos',
          code: 'INVALID_CREDENTIALS',
        );
      }

      if (!userModel.activo) {
        throw AuthenticationException(
          message: 'El usuario está inactivo',
          code: 'USER_INACTIVE',
        );
      }

      _currentUser = userModel.toEntity();

      return _currentUser!;
    } catch (e) {
      // Log the error for debugging
      if (e is AuthenticationException) rethrow;
      throw DatabaseException(
        message: 'Error al iniciar sesión: $e',
        code: 'LOGIN_ERROR',
      );
    }
  }

  @override
  Future<User> registerAsGuest(String username, String fullName) async {
    await _initializeDatabase();

    // Check if user limit has been reached (100 users)
    final userCount = await _userDao.getUserCount();
    if (userCount >= 100) {
      throw AuthenticationException(
        message: 'El sistema ha alcanzado el límite máximo de 100 usuarios. Contacta al administrador.',
        code: 'USER_LIMIT_REACHED',
      );
    }

    // Check if username already exists
    final existingUser = await _userDao.getUserByUsername(username);
    if (existingUser != null) {
      throw AuthenticationException(
        message: 'El username ya está en uso',
        code: 'USER_EXISTS',
      );
    }

    final newUser = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      nombre: fullName,
      correo: null,
      username: username,
      password: 'guest123', // Default password for guest accounts
      perfil: 'Invitado',
      saldo: 5000000,
      activo: true,
      fechaRegistro: DateTime.now(),
    );

    await _userDao.insertUser(newUser);

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