import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/exceptions.dart';
import '../database/database_seeder.dart';
import '../database/user_dao.dart';
import '../database/investment_dao.dart';
import '../models/user_model.dart';

class UserRepositoryLocal implements UserRepository {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  final UserDao _userDao = UserDao();
  final InvestmentDao _investmentDao = InvestmentDao();

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
  Future<User> getUserById(String id) async {
    await _initializeDatabase();

    final userModel = await _userDao.getUserById(id);

    if (userModel == null) {
      throw NotFoundException(
        message: 'Usuario no encontrado con ID: $id',
        code: 'USER_NOT_FOUND',
      );
    }

    return userModel.toEntity();
  }

  @override
  Future<User> updateBalance(String userId, double newBalance) async {
    await _initializeDatabase();

    // Update user balance in database
    final success = await _userDao.updateBalance(userId, newBalance);

    if (!success) {
      throw DatabaseException(
        message: 'No se pudo actualizar el saldo del usuario',
        code: 'BALANCE_UPDATE_FAILED',
      );
    }

    return await getUserById(userId);
  }

  @override
  Future<List<User>> getAllUsers() async {
    await _initializeDatabase();

    final userModels = await _userDao.getAllUsers();
    return userModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<User>> getRanking() async {
    await _initializeDatabase();

    final userModels = await _userDao.getActiveUsers();
    final usersWithBalance = <User>[];

    // Calculate actual balance for each user based on investments
    for (final userModel in userModels) {
      final totalInvested = await _investmentDao.getTotalInvestedByUser(userModel.id);
      final actualBalance = userModel.saldo - totalInvested;

      final user = userModel.toEntity();
      final userWithActualBalance = user.copyWith(saldo: actualBalance);
      usersWithBalance.add(userWithActualBalance);
    }

    // Sort by balance descending
    usersWithBalance.sort((a, b) => b.saldo.compareTo(a.saldo));

    return usersWithBalance;
  }

  @override
  Future<User> createUser({
    required String nombre,
    String? correo,
    required String username,
    required String password,
    required String perfil,
    double? saldo,
    bool activo = true,
  }) async {
    await _initializeDatabase();

    // Check if username already exists
    final usernameExists = await _userDao.usernameExists(username);
    if (usernameExists) {
      throw DatabaseException(
        message: 'El username $username ya existe',
        code: 'USERNAME_EXISTS',
      );
    }

    // Generate unique ID
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';

    // Use default balance if not provided
    final defaultBalance = saldo ?? _getInitialBalance(perfil);

    final userModel = UserModel(
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      password: password,
      perfil: perfil,
      saldo: defaultBalance,
      activo: activo,
      fechaRegistro: DateTime.now(),
    );

    final success = await _userDao.insertUser(userModel);

    if (!success) {
      throw DatabaseException(
        message: 'No se pudo crear el usuario',
        code: 'USER_CREATE_FAILED',
      );
    }

    return userModel.toEntity();
  }

  @override
  Future<User> updateUser({
    required String id,
    String? nombre,
    String? correo,
    String? username,
    String? password,
    String? perfil,
    double? saldo,
    bool? activo,
  }) async {
    await _initializeDatabase();

    // Get existing user
    final existingUserModel = await _userDao.getUserById(id);
    if (existingUserModel == null) {
      throw NotFoundException(
        message: 'Usuario no encontrado con ID: $id',
        code: 'USER_NOT_FOUND',
      );
    }

    // Check if new username already exists (if changing username)
    if (username != null && username != existingUserModel.username) {
      final usernameExists = await _userDao.usernameExists(username);
      if (usernameExists) {
        throw DatabaseException(
          message: 'El username $username ya existe',
          code: 'USERNAME_EXISTS',
        );
      }
    }

    // Create updated user model
    final updatedUserModel = UserModel(
      id: existingUserModel.id,
      nombre: nombre ?? existingUserModel.nombre,
      correo: correo ?? existingUserModel.correo,
      username: username ?? existingUserModel.username,
      password: password ?? existingUserModel.password,
      perfil: perfil ?? existingUserModel.perfil,
      saldo: saldo ?? existingUserModel.saldo,
      activo: activo ?? existingUserModel.activo,
      fechaRegistro: existingUserModel.fechaRegistro,
    );

    final success = await _userDao.updateUser(updatedUserModel);

    if (!success) {
      throw DatabaseException(
        message: 'No se pudo actualizar el usuario',
        code: 'USER_UPDATE_FAILED',
      );
    }

    return updatedUserModel.toEntity();
  }

  @override
  Future<bool> deleteUser(String id) async {
    await _initializeDatabase();

    // Check if user exists
    final existingUser = await _userDao.getUserById(id);
    if (existingUser == null) {
      throw NotFoundException(
        message: 'Usuario no encontrado con ID: $id',
        code: 'USER_NOT_FOUND',
      );
    }

    final success = await _userDao.deleteUser(id);

    if (!success) {
      throw DatabaseException(
        message: 'No se pudo eliminar el usuario',
        code: 'USER_DELETE_FAILED',
      );
    }

    return true;
  }

  // Get initial balance based on profile
  double _getInitialBalance(String perfil) {
    switch (perfil.toLowerCase()) {
      case 'admin':
        return 0;
      case 'alumno':
      case 'student':
        return 1000000;
      case 'docente':
      case 'teacher':
        return 4000000;
      case 'administrativo':
      case 'employee':
        return 6000000;
      case 'inversionista':
      case 'investor':
        return 10000000;
      case 'invitado':
      case 'guest':
        return 2000000;
      default:
        return 1000000;
    }
  }
}