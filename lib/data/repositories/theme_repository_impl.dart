import 'dart:async';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/websocket_datasource.dart';
import '../models/theme_model.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final WebSocketDataSource _dataSource;

  ThemeRepositoryImpl(this._dataSource);

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
  Future<InvestmentTheme> createTheme({
    required String nombre,
    String descripcion = '',
    required String color,
    required String icono,
    int orden = 0,
    bool activo = true,
  }) async {
    // En modo WebSocket, la creación se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.createTheme for WebSocket mode',
    );
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
    // En modo WebSocket, la actualización se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.updateTheme for WebSocket mode',
    );
  }

  @override
  Future<bool> deleteTheme(String id) async {
    // En modo WebSocket, la eliminación se maneja a través de AdminActions
    throw UnimplementedError(
      'Use AdminActions.deleteTheme for WebSocket mode',
    );
  }

  @override
  Future<bool> themeNameExists(String nombre, {String? excludeId}) async {
    try {
      final themes = await getThemes();
      final normalizedNombre = nombre.toLowerCase().trim();

      for (final theme in themes) {
        if (excludeId != null && theme.id == excludeId) {
          continue;
        }
        if (theme.nombre.toLowerCase().trim() == normalizedNombre) {
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
