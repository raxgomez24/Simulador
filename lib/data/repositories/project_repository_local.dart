import 'package:uuid/uuid.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/project_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../database/database_seeder.dart';
import '../database/project_dao.dart';
import '../database/theme_dao.dart';
import '../database/database_helper.dart';
import '../models/project_model.dart';

/// Repositorio local que usa SQLite para persistencia
///
/// Este repositorio permite que la aplicación funcione sin servidor,
/// utilizando SQLite para persistencia de datos
class ProjectRepositoryLocal implements ProjectRepository {
  final DatabaseSeeder _seeder = DatabaseSeeder();
  final ProjectDao _projectDao = ProjectDao();
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

  /// Obtiene todos los proyectos desde SQLite
  @override
  Future<List<Project>> getProjects() async {
    try {
      await _initializeDatabase();

      final projects = await _projectDao.getAllProjects();
      return projects.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw ServerException(
        message: 'Error al obtener proyectos locales: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Obtiene proyectos filtrados por tema
  @override
  Future<List<Project>> getProjectsByTheme(String themeId) async {
    try {
      await _initializeDatabase();

      final projects = await _projectDao.getProjectsByTheme(themeId);
      return projects.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw ServerException(
        message: 'Error al obtener proyectos del tema: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Obtiene un proyecto específico por su ID
  @override
  Future<Project> getProjectById(String id) async {
    try {
      await _initializeDatabase();

      final project = await _projectDao.getProjectById(id);

      if (project == null) {
        throw NotFoundException(
          message: 'Proyecto no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      return project.toEntity();
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al obtener proyecto: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Obtiene todos los temas (categorías) desde SQLite
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

  /// Obtiene un tema específico por su ID
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

  /// Crea un nuevo proyecto
  @override
  Future<Project> createProject({
    required String titulo,
    required String descripcion,
    required String temaId,
    required String temaNombre,
    required String temaColor,
    String imagen = '',
    String pitch = '',
    String problema = '',
    String solucion = '',
    String estrategiaIngresos = '',
    String proyeccionFinanciera = '',
    List<Map<String, String>> participantes = const [],
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      await _initializeDatabase();

      // Validar que el tema existe
      final theme = await _themeDao.getThemeById(temaId);
      if (theme == null) {
        throw NotFoundException(
          message: 'Tema no encontrado con ID: $temaId',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      // Validar que el nombre sea único
      final nameExists = await projectNameExists(titulo);
      if (nameExists) {
        throw ValidationException(
          message: 'Ya existe un proyecto con el nombre: $titulo',
          code: 'DUPLICATE_NAME',
        );
      }

      // Calcular orden automáticamente si no se proporciona
      final currentProjects = await getProjects();
      final finalOrden = orden > 0 ? orden : (currentProjects.length + 1);

      // Crear el modelo del proyecto
      final projectModel = ProjectModel(
        id: _uuid.v4(),
        nombre: titulo,
        descripcion: descripcion,
        imagen: imagen,
        temaId: temaId,
        temaNombre: temaNombre,
        temaColor: temaColor,
        totalInvertido: 0.0,
        numeroInversores: 0,
        createdAt: DateTime.now(),
        activo: activo,
        pitch: pitch,
        problema: problema,
        solucion: solucion,
        estrategiaIngresos: estrategiaIngresos,
        proyeccionFinanciera: proyeccionFinanciera,
        participantes: participantes,
        orden: finalOrden,
      );

      // Insertar en la base de datos
      final inserted = await _projectDao.insertProject(projectModel);
      if (!inserted) {
        throw const DatabaseException(
          message: 'Error al insertar proyecto en la base de datos',
          code: 'INSERT_FAILED',
        );
      }

      // Actualizar estadísticas del tema
      final projectCount = await _projectDao.getProjectCountByTheme(temaId);
      await _themeDao.updateThemeStats(temaId, projectCount, theme.totalInvertido);

      return projectModel.toEntity();
    } catch (e) {
      if (e is ValidationException || e is DatabaseException || e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al crear proyecto: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Actualiza un proyecto existente
  @override
  Future<Project> updateProject({
    required String id,
    required String titulo,
    required String descripcion,
    String imagen = '',
    bool activo = true,
    String pitch = '',
    String problema = '',
    String solucion = '',
    String estrategiaIngresos = '',
    String proyeccionFinanciera = '',
    List<Map<String, String>> participantes = const [],
    int orden = 0,
  }) async {
    try {
      await _initializeDatabase();

      // Verificar que el proyecto existe
      final existingProject = await _projectDao.getProjectById(id);
      if (existingProject == null) {
        throw NotFoundException(
          message: 'Proyecto no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      // Validar que el nombre sea único (excluyendo el proyecto actual)
      final nameExists = await projectNameExists(titulo, excludeId: id);
      if (nameExists) {
        throw ValidationException(
          message: 'Ya existe otro proyecto con el nombre: $titulo',
          code: 'DUPLICATE_NAME',
        );
      }

      // Actualizar el modelo del proyecto
      final updatedProjectModel = ProjectModel(
        id: id,
        nombre: titulo,
        descripcion: descripcion,
        imagen: imagen,
        temaId: existingProject.temaId,
        temaNombre: existingProject.temaNombre,
        temaColor: existingProject.temaColor,
        totalInvertido: existingProject.totalInvertido,
        numeroInversores: existingProject.numeroInversores,
        createdAt: existingProject.createdAt,
        activo: activo,
        pitch: pitch,
        problema: problema,
        solucion: solucion,
        estrategiaIngresos: estrategiaIngresos,
        proyeccionFinanciera: proyeccionFinanciera,
        participantes: participantes,
        orden: orden,
      );

      // Actualizar en la base de datos
      final updated = await _projectDao.updateProject(updatedProjectModel);
      if (!updated) {
        throw const DatabaseException(
          message: 'Error al actualizar proyecto en la base de datos',
          code: 'UPDATE_FAILED',
        );
      }

      return updatedProjectModel.toEntity();
    } catch (e) {
      if (e is ValidationException || e is DatabaseException || e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al actualizar proyecto: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Elimina un proyecto por su ID
  @override
  Future<bool> deleteProject(String id) async {
    try {
      await _initializeDatabase();

      // Verificar que el proyecto existe
      final existingProject = await _projectDao.getProjectById(id);
      if (existingProject == null) {
        throw NotFoundException(
          message: 'Proyecto no encontrado con ID: $id',
          code: ApiConstants.errorProjectNotFound,
        );
      }

      final themeId = existingProject.temaId;

      // Eliminar de la base de datos
      final deleted = await _projectDao.deleteProject(id);
      if (!deleted) {
        throw const DatabaseException(
          message: 'Error al eliminar proyecto de la base de datos',
          code: 'DELETE_FAILED',
        );
      }

      // Actualizar estadísticas del tema
      final theme = await _themeDao.getThemeById(themeId);
      if (theme != null) {
        final projectCount = await _projectDao.getProjectCountByTheme(themeId);
        final projectsByTheme = await _projectDao.getProjectsByTheme(themeId);
        final totalInvested = projectsByTheme.fold<double>(
          0,
          (sum, project) => sum + project.totalInvertido,
        );
        await _themeDao.updateThemeStats(themeId, projectCount, totalInvested);
      }

      return true;
    } catch (e) {
      if (e is ValidationException || e is DatabaseException || e is NotFoundException) rethrow;
      throw ServerException(
        message: 'Error al eliminar proyecto: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }

  /// Verifica si un nombre de proyecto ya existe
  @override
  Future<bool> projectNameExists(String nombre, {String? excludeId}) async {
    try {
      await _initializeDatabase();

      final db = await _dbHelper.database;
      final allProjects = await db.query(
        DatabaseHelper.tableProjects,
      );

      final normalizedNombre = nombre.toLowerCase().trim();

      for (final projectData in allProjects) {
        final projectId = projectData['id'] as String;
        final projectNombre = projectData['nombre'] as String;

        if (excludeId != null && projectId == excludeId) {
          continue; // Skip the project we're excluding
        }

        if (projectNombre.toLowerCase().trim() == normalizedNombre) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw ServerException(
        message: 'Error al verificar nombre de proyecto: ${e.toString()}',
        code: ApiConstants.errorServer,
      );
    }
  }
}
