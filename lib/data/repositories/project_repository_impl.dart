import 'dart:async';
import '../../domain/entities/project.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/project_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/websocket_datasource.dart';
import '../models/project_model.dart';
import '../models/theme_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final WebSocketDataSource _dataSource;

  ProjectRepositoryImpl(this._dataSource);

  @override
  Future<List<Project>> getProjects() async {
    try {
      final completer = Completer<List<Project>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeProjects) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> projectsJson = message['data'] ?? [];
            final projects = projectsJson
                .map((json) => ProjectModel.fromJson(json).toEntity())
                .toList();
            completer.complete(projects);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener proyectos',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeProjects,
        'action': 'get_all',
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<List<Project>> getProjectsByTheme(String themeId) async {
    try {
      final completer = Completer<List<Project>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeProjects) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> projectsJson = message['data'] ?? [];
            final projects = projectsJson
                .map((json) => ProjectModel.fromJson(json).toEntity())
                .toList();
            completer.complete(projects);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener proyectos',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeProjects,
        'action': 'get_by_theme',
        'themeId': themeId,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<Project> getProjectById(String id) async {
    try {
      final completer = Completer<Project>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeProjectDetail) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final projectModel = ProjectModel.fromJson(message['data']);
            completer.complete(projectModel.toEntity());
          } else {
            completer.completeError(
              NotFoundException(
                message: message['error'] ?? 'Proyecto no encontrado',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeProjectDetail,
        'action': 'get_by_id',
        'projectId': id,
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<List<InvestmentTheme>> getThemes() async {
    try {
      final completer = Completer<List<InvestmentTheme>>();

      final subscription = _dataSource.messageStream.listen((message) {
        if (message['type'] == ApiConstants.messageTypeProjects) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final List<dynamic> themesJson = message['data'] ?? [];
            final themes = themesJson
                .map((json) => ThemeModel.fromJson(json).toEntity())
                .toList();
            completer.complete(themes);
          } else {
            completer.completeError(
              ServerException(
                message: message['error'] ?? 'Error al obtener temas',
                code: message['errorCode'],
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeProjects,
        'action': 'get_themes',
      });

      final result = await completer.future.timeout(
        ApiConstants.connectionTimeout,
      );
      subscription.cancel();
      return result;
    } on TimeoutException {
      throw const TimeoutException(
        message: 'Tiempo de espera agotado',
        code: ApiConstants.errorServer,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<InvestmentTheme> getThemeById(String id) async {
    try {
      final themes = await getThemes();
      final theme = themes.firstWhere(
        (t) => t.id == id,
        orElse: () => throw NotFoundException(
          message: 'Tema no encontrado',
          code: ApiConstants.errorProjectNotFound,
        ),
      );
      return theme;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

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
    // En modo WebSocket, la creación se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.createProject for WebSocket mode',
    );
  }

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
    // En modo WebSocket, la actualización se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.updateProject for WebSocket mode',
    );
  }

  @override
  Future<bool> deleteProject(String id) async {
    // En modo WebSocket, la eliminación se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.deleteProject for WebSocket mode',
    );
  }

  @override
  Future<bool> projectNameExists(String nombre, {String? excludeId}) async {
    try {
      final projects = await getProjects();
      final normalizedNombre = nombre.toLowerCase().trim();

      for (final project in projects) {
        if (excludeId != null && project.id == excludeId) {
          continue;
        }
        if (project.nombre.toLowerCase().trim() == normalizedNombre) {
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
