import 'package:uuid/uuid.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../database/database_seeder.dart';
import '../database/theme_dao.dart';
import '../database/database_helper.dart';
import '../models/theme_model.dart';

/// Repositorio local que usa SQLite para persistencia de temas
///
/// Este repositorio permite CRUD completo de temas sin servidor
class ThemeRepositoryLocal implements ThemeRepository {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  final ThemeDao _themeDao = ThemeDao();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

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
  Future<List<InvestmentTheme>> getThemes() async {
    try {
      await _initializeDatabase();

      final themes = await _themeDao.getAllThemes();
      return themes.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw ServerException(
        message: 'Error al obtener temas: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<InvestmentTheme> getThemeById(String id) async {
    try {
      await _initializeDatabase();

      final theme = await _themeDao.getThemeById(id);

      if (theme == null) {
        throw NotFoundException(
          message: 'Tema no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      return theme.toEntity();
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al obtener tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<InvestmentTheme> createTheme({
    required String nombre,
    String descripcion = '',
    required String color,
    required String icono,
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      await _initializeDatabase();

      // Validar que el nombre sea único
      final nameExists = await themeNameExists(nombre);
      if (nameExists) {
        throw ValidationException(
          message: 'Ya existe un tema con el nombre: $nombre',
          code: 'DUPLICATE_NAME',
        );
      }

      // Calcular orden automáticamente si no se proporciona
      final currentThemes = await getThemes();
      final finalOrden = orden > 0 ? orden : (currentThemes.length + 1);

      // Crear el modelo del tema
      final themeModel = ThemeModel(
        id: _uuid.v4(),
        nombre: nombre,
        descripcion: descripcion,
        color: color,
        icon: icono,
        orden: finalOrden,
        activo: activo,
        numeroProyectos: 0,
        totalInvertido: 0.0,
      );

      // Insertar en la base de datos
      final inserted = await _themeDao.insertTheme(themeModel);
      if (!inserted) {
        throw const DatabaseException(
          message: 'Error al insertar tema en la base de datos',
          code: 'INSERT_FAILED',
        );
      }

      return themeModel.toEntity();
    } catch (e) {
      if (e is ValidationException || e is DatabaseException) rethrow;
      throw ServerException(
        message: 'Error al crear tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<InvestmentTheme> updateTheme({
    required String id,
    required String nombre,
    String descripcion = '',
    required String color,
    required String icono,
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      await _initializeDatabase();

      // Verificar que el tema existe
      final existingTheme = await _themeDao.getThemeById(id);
      if (existingTheme == null) {
        throw NotFoundException(
          message: 'Tema no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      // Validar que el nombre sea único (excluyendo el tema actual)
      final nameExists = await themeNameExists(nombre, excludeId: id);
      if (nameExists) {
        throw ValidationException(
          message: 'Ya existe otro tema con el nombre: $nombre',
          code: 'DUPLICATE_NAME',
        );
      }

      // Actualizar el modelo del tema
      final updatedThemeModel = ThemeModel(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        color: color,
        icon: icono,
        orden: orden,
        activo: activo,
        numeroProyectos: existingTheme.numeroProyectos,
        totalInvertido: existingTheme.totalInvertido,
      );

      // Actualizar en la base de datos
      final updated = await _themeDao.updateTheme(updatedThemeModel);
      if (!updated) {
        throw const DatabaseException(
          message: 'Error al actualizar tema en la base de datos',
          code: 'UPDATE_FAILED',
        );
      }

      return updatedThemeModel.toEntity();
    } catch (e) {
      if (e is ValidationException || e is DatabaseException || e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al actualizar tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<bool> deleteTheme(String id) async {
    try {
      await _initializeDatabase();

      // Verificar que el tema existe
      final existingTheme = await _themeDao.getThemeById(id);
      if (existingTheme == null) {
        throw NotFoundException(
          message: 'Tema no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      // Verificar que no tenga proyectos asociados
      if (existingTheme.numeroProyectos > 0) {
        throw ValidationException(
          message: 'No se puede eliminar un tema que tiene proyectos asociados',
          code: 'HAS_PROJECTS',
        );
      }

      // Eliminar de la base de datos
      final deleted = await _themeDao.deleteTheme(id);
      if (!deleted) {
        throw const DatabaseException(
          message: 'Error al eliminar tema de la base de datos',
          code: 'DELETE_FAILED',
        );
      }

      return true;
    } catch (e) {
      if (e is ValidationException || e is DatabaseException || e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al eliminar tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<bool> themeNameExists(String nombre, {String? excludeId}) async {
    try {
      await _initializeDatabase();

      final db = await _dbHelper.database;
      final allThemes = await db.query(
        DatabaseHelper.tableThemes,
      );

      final normalizedNombre = nombre.toLowerCase().trim();

      for (final themeData in allThemes) {
        final themeId = themeData['id'] as String;
        final themeNombre = themeData['nombre'] as String;

        if (excludeId != null && themeId == excludeId) {
          continue; // Skip the theme we're excluding
        }

        if (themeNombre.toLowerCase().trim() == normalizedNombre) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw ServerException(
        message: 'Error al verificar nombre de tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }
}
