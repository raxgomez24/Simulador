import 'dart:async';
import '../../domain/entities/investment.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../core/errors/exceptions.dart';
import '../../app/config.dart';
import '../database/database_seeder.dart';
import '../database/investment_dao.dart';
import '../database/user_dao.dart';
import '../database/project_dao.dart';
import '../models/investment_model.dart';

/// Almacenamiento local de inversiones usando SQLite
/// Implementa persistencia completa de datos en base de datos local
class InvestmentRepositoryLocal implements InvestmentRepository {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  final InvestmentDao _investmentDao = InvestmentDao();
  final UserDao _userDao = UserDao();
  final ProjectDao _projectDao = ProjectDao();

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

  /// Obtiene todas las inversiones almacenadas (compatibilidad con código existente)
  static Future<List<Investment>> get allInvestments async {
    final repo = InvestmentRepositoryLocal();
    return await repo.getAllInvestments();
  }

  /// Agrega una inversión directamente (para edición)
  static Future<void> addInvestment(Investment investment) async {
    final repo = InvestmentRepositoryLocal();
    final model = InvestmentModel.fromEntity(investment);
    await repo._investmentDao.insertInvestment(model);
  }

  /// Limpia todas las inversiones (para testing o reinicio)
  static Future<void> clearAll() async {
    final repo = InvestmentRepositoryLocal();
    await repo._seeder.resetDatabase();
  }

  @override
  Future<List<Investment>> getAllInvestments() async {
    await _initializeDatabase();
    final investments = await _investmentDao.getAllInvestments();
    return investments.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Investment>> getInvestmentsByUser(String userId) async {
    await _initializeDatabase();
    final investments = await _investmentDao.getInvestmentsByUser(userId);
    return investments.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Investment>> getInvestmentsByProject(String projectId) async {
    await _initializeDatabase();
    final investments = await _investmentDao.getInvestmentsByProject(projectId);
    return investments.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Investment> makeInvestment({
    required String userId,
    required String projectId,
    required double amount,
    SessionState? sessionState,
  }) async {
    await _initializeDatabase();

    // Validar el estado de la sesión
    if (sessionState != null && sessionState != SessionState.active) {
      String message;
      switch (sessionState) {
        case SessionState.ended:
          message = 'La ronda de inversión ha finalizado. No se permiten nuevas inversiones.';
          break;
        case SessionState.paused:
          message = 'La ronda está pausada temporalmente. Intente más tarde.';
          break;
        case SessionState.waiting:
          message = 'La ronda aún no ha comenzado. Espere a que el administrador la inicie.';
          break;
        default:
          message = 'No se pueden realizar inversiones en este momento.';
      }
      throw SessionClosedException(
        message: message,
        code: 'SESSION_NOT_ACTIVE',
      );
    }

    // Validar el monto mínimo
    if (amount < AppConfig.minimumInvestment) {
      throw const InvalidAmountException(
        message: 'El monto mínimo de inversión es ${AppConfig.minimumInvestment}',
        code: 'INVALID_AMOUNT',
      );
    }

    // Validar el monto máximo
    if (amount > AppConfig.maximumInvestment) {
      throw const InvalidAmountException(
        message: 'El monto máximo de inversión es ${AppConfig.maximumInvestment}',
        code: 'INVALID_AMOUNT',
      );
    }

    // Obtener información del usuario y proyecto
    final user = await _userDao.getUserById(userId);
    final project = await _projectDao.getProjectById(projectId);

    if (user == null) {
      throw DatabaseException(
        message: 'Usuario no encontrado: $userId',
        code: 'USER_NOT_FOUND',
      );
    }

    if (project == null) {
      throw DatabaseException(
        message: 'Proyecto no encontrado: $projectId',
        code: 'PROJECT_NOT_FOUND',
      );
    }

    // Validar que el usuario tenga saldo suficiente
    final totalInvested = await _investmentDao.getTotalInvestedByUser(userId);
    final remainingBalance = user.saldo - totalInvested;

    if (remainingBalance < amount) {
      throw InsufficientBalanceException(
        message: 'Saldo insuficiente. Disponible: \$${remainingBalance.toStringAsFixed(2)}, Solicitado: \$${amount.toStringAsFixed(2)}',
        code: 'INSUFFICIENT_BALANCE',
        availableBalance: remainingBalance,
      );
    }

    // Crear la inversión
    final investment = Investment(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      usuarioId: userId,
      usuarioNombre: user.nombre,
      perfil: User.fromString(user.perfil),
      proyectoId: projectId,
      proyectoNombre: project.nombre,
      temaId: project.temaId,
      temaNombre: project.temaNombre,
      temaColor: project.temaColor ?? '#00D4AA',
      monto: amount,
      fechaHora: DateTime.now(),
      observaciones: null,
      estado: InvestmentStatus.activa,
    );

    // Guardar la inversión en la base de datos
    final model = InvestmentModel.fromEntity(investment);
    await _investmentDao.insertInvestment(model);

    return investment;
  }

  @override
  Future<double> getTotalInvestedByUser(String userId) async {
    await _initializeDatabase();
    return await _investmentDao.getTotalInvestedByUser(userId);
  }

  @override
  Future<double> getTotalInvestedInProject(String projectId) async {
    await _initializeDatabase();
    return await _investmentDao.getTotalInvestedInProject(projectId);
  }

  /// Método adicional para eliminar una inversión (para testing)
  Future<void> cancelInvestment(String investmentId) async {
    await _initializeDatabase();
    await _investmentDao.deleteInvestment(investmentId);
  }

  @override
  Future<Investment> createInvestment({
    required String usuarioId,
    required String usuarioNombre,
    required String perfil,
    required String proyectoId,
    required String proyectoNombre,
    required String temaId,
    required String temaNombre,
    required String temaColor,
    required double monto,
    String? observaciones,
    SessionState? sessionState,
  }) async {
    await _initializeDatabase();

    // Validar el estado de la sesión
    if (sessionState != null && sessionState != SessionState.active) {
      String message;
      switch (sessionState) {
        case SessionState.ended:
          message = 'La ronda de inversión ha finalizado. No se permiten nuevas inversiones.';
          break;
        case SessionState.paused:
          message = 'La ronda está pausada temporalmente. Intente más tarde.';
          break;
        case SessionState.waiting:
          message = 'La ronda aún no ha comenzado. Espere a que el administrador la inicie.';
          break;
        default:
          message = 'No se pueden realizar inversiones en este momento.';
      }
      throw SessionClosedException(
        message: message,
        code: 'SESSION_NOT_ACTIVE',
      );
    }

    // Validar el monto mínimo
    if (monto < AppConfig.minimumInvestment) {
      throw const InvalidAmountException(
        message: 'El monto mínimo de inversión es ${AppConfig.minimumInvestment}',
        code: 'INVALID_AMOUNT',
      );
    }

    // Validar el monto máximo
    if (monto > AppConfig.maximumInvestment) {
      throw const InvalidAmountException(
        message: 'El monto máximo de inversión es ${AppConfig.maximumInvestment}',
        code: 'INVALID_AMOUNT',
      );
    }

    // Obtener información del usuario y proyecto
    final user = await _userDao.getUserById(usuarioId);
    final project = await _projectDao.getProjectById(proyectoId);

    if (user == null) {
      throw DatabaseException(
        message: 'Usuario no encontrado: $usuarioId',
        code: 'USER_NOT_FOUND',
      );
    }

    if (project == null) {
      throw DatabaseException(
        message: 'Proyecto no encontrado: $proyectoId',
        code: 'PROJECT_NOT_FOUND',
      );
    }

    // Validar que el usuario tenga saldo suficiente
    final totalInvested = await _investmentDao.getTotalInvestedByUser(usuarioId);
    final remainingBalance = user.saldo - totalInvested;

    if (remainingBalance < monto) {
      throw InsufficientBalanceException(
        message: 'Saldo insuficiente. Disponible: \$${remainingBalance.toStringAsFixed(2)}, Solicitado: \$${monto.toStringAsFixed(2)}',
        code: 'INSUFFICIENT_BALANCE',
        availableBalance: remainingBalance,
      );
    }

    // Crear la inversión
    final investment = Investment(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      perfil: User.fromString(perfil),
      proyectoId: proyectoId,
      proyectoNombre: proyectoNombre,
      temaId: temaId,
      temaNombre: temaNombre,
      temaColor: temaColor,
      monto: monto,
      fechaHora: DateTime.now(),
      observaciones: observaciones,
      estado: InvestmentStatus.activa,
    );

    // Guardar la inversión en la base de datos
    final model = InvestmentModel.fromEntity(investment);
    await _investmentDao.insertInvestment(model);

    return investment;
  }

  @override
  Future<Investment> updateInvestment({
    required String id,
    String? usuarioId,
    String? usuarioNombre,
    String? perfil,
    String? proyectoId,
    String? proyectoNombre,
    String? temaId,
    String? temaNombre,
    String? temaColor,
    double? monto,
    String? observaciones,
    String? estado,
  }) async {
    await _initializeDatabase();

    // Obtener la inversión existente
    final existingInvestment = await _investmentDao.getInvestmentById(id);
    if (existingInvestment == null) {
      throw DatabaseException(
        message: 'Inversión no encontrada: $id',
        code: 'INVESTMENT_NOT_FOUND',
      );
    }

    // Si se actualiza el monto, validar que el usuario tenga saldo suficiente
    if (monto != null && monto != existingInvestment.monto) {
      final userId = usuarioId ?? existingInvestment.usuarioId;

      // Calcular el nuevo total invertido (restando el monto anterior y sumando el nuevo)
      final totalInvested = await _investmentDao.getTotalInvestedByUser(userId);
      final totalWithoutCurrent = totalInvested - existingInvestment.monto;
      final newTotalInvested = totalWithoutCurrent + monto;

      final user = await _userDao.getUserById(userId);
      if (user == null) {
        throw DatabaseException(
          message: 'Usuario no encontrado: $userId',
          code: 'USER_NOT_FOUND',
        );
      }

      if (newTotalInvested > user.saldo) {
        throw InsufficientBalanceException(
          message: 'Saldo insuficiente. Disponible: \$${user.saldo.toStringAsFixed(2)}, Total actualizado: \$${newTotalInvested.toStringAsFixed(2)}',
          code: 'INSUFFICIENT_BALANCE',
          availableBalance: user.saldo - totalInvested + existingInvestment.monto,
        );
      }

      // Validar el monto mínimo y máximo
      if (monto < AppConfig.minimumInvestment) {
        throw const InvalidAmountException(
          message: 'El monto mínimo de inversión es ${AppConfig.minimumInvestment}',
          code: 'INVALID_AMOUNT',
        );
      }

      if (monto > AppConfig.maximumInvestment) {
        throw const InvalidAmountException(
          message: 'El monto máximo de inversión es ${AppConfig.maximumInvestment}',
          code: 'INVALID_AMOUNT',
        );
      }
    }

    // Crear la inversión actualizada
    final updatedInvestment = existingInvestment.copyWith(
      usuarioId: usuarioId ?? existingInvestment.usuarioId,
      usuarioNombre: usuarioNombre ?? existingInvestment.usuarioNombre,
      perfil: perfil ?? existingInvestment.perfil,
      proyectoId: proyectoId ?? existingInvestment.proyectoId,
      proyectoNombre: proyectoNombre ?? existingInvestment.proyectoNombre,
      temaId: temaId ?? existingInvestment.temaId,
      temaNombre: temaNombre ?? existingInvestment.temaNombre,
      temaColor: temaColor ?? existingInvestment.temaColor,
      monto: monto ?? existingInvestment.monto,
      observaciones: observaciones,
      estado: estado ?? existingInvestment.estado,
    );

    // Actualizar la inversión en la base de datos
    final success = await _investmentDao.updateInvestment(updatedInvestment);

    if (!success) {
      throw const DatabaseException(
        message: 'Error al actualizar la inversión',
        code: 'UPDATE_FAILED',
      );
    }

    return updatedInvestment.toEntity();
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    await _initializeDatabase();

    // Obtener la inversión antes de eliminarla para devolver el saldo
    final investment = await _investmentDao.getInvestmentById(investmentId);
    if (investment == null) {
      throw const DatabaseException(
        message: 'Inversión no encontrada',
        code: 'INVESTMENT_NOT_FOUND',
      );
    }

    // Eliminar la inversión (esto automáticamente recalcula estadísticas)
    final success = await _investmentDao.deleteInvestment(investmentId);
    if (!success) {
      throw const DatabaseException(
        message: 'Error al eliminar la inversión',
        code: 'DELETE_FAILED',
      );
    }

    // Nota: El saldo del usuario se mantiene, ya que las estadísticas se recalculan automáticamente
    // cuando se elimina la inversión en InvestmentDao
  }
}