import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import 'websocket_provider.dart';

final adminActionsProvider = Provider<AdminActions>((ref) {
  final dataSource = ref.read(webSocketDataSourceProvider);
  return AdminActions(dataSource);
});

class AdminActions {
  final WebSocketDataSource _dataSource;

  AdminActions(this._dataSource);

  Future<void> createProject({
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
  }) async {
    _dataSource.send({
      'type': 'admin_create_project',
      'data': {
        'titulo': titulo,
        'descripcion': descripcion,
        'temaId': temaId,
        'temaNombre': temaNombre,
        'temaColor': temaColor,
        'imagen': imagen,
        'pitch': pitch,
        'problema': problema,
        'solucion': solucion,
        'estrategiaIngresos': estrategiaIngresos,
        'proyeccionFinanciera': proyeccionFinanciera,
        'participantes': participantes,
      },
    });
  }

  Future<void> updateProject({
    required String id,
    required String titulo,
    required String descripcion,
    String imagen = '',
    bool activo = true,
  }) async {
    _dataSource.send({
      'type': 'admin_update_project',
      'data': {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'imagen': imagen,
        'activo': activo,
      },
    });
  }

  Future<void> deleteProject(String projectId) async {
    _dataSource.send({
      'type': 'admin_delete_project',
      'data': {'projectId': projectId},
    });
  }

  Future<void> createTheme({
    required String nombre,
    required String color,
    required String icono,
    String descripcion = '',
    int orden = 0,
  }) async {
    _dataSource.send({
      'type': 'admin_create_theme',
      'data': {
        'nombre': nombre,
        'descripcion': descripcion,
        'color': color,
        'icono': icono,
        'orden': orden,
      },
    });
  }

  Future<void> updateTheme({
    required String id,
    required String nombre,
    required String color,
    required String icono,
    String descripcion = '',
    int orden = 0,
  }) async {
    _dataSource.send({
      'type': 'admin_update_theme',
      'data': {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'color': color,
        'icono': icono,
        'orden': orden,
      },
    });
  }

  Future<void> deleteTheme(String themeId) async {
    _dataSource.send({
      'type': 'admin_delete_theme',
      'data': {'themeId': themeId},
    });
  }

  Future<void> createUser({
    required String nombre,
    required String correo,
    required String username,
    required String password,
    required String perfil,
    double saldo = 1000000,
    bool activo = true,
  }) async {
    _dataSource.send({
      'type': 'admin_create_user',
      'data': {
        'nombre': nombre,
        'correo': correo,
        'username': username,
        'password': password,
        'perfil': perfil,
        'saldo': saldo,
        'activo': activo,
      },
    });
  }

  Future<void> updateUser({
    required String id,
    String? nombre,
    String? correo,
    String? username,
    String? password,
    String? perfil,
    double? saldo,
    bool? activo,
  }) async {
    _dataSource.send({
      'type': 'admin_update_user',
      'data': {
        'id': id,
        if (nombre != null) 'nombre': nombre,
        if (correo != null) 'correo': correo,
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (perfil != null) 'perfil': perfil,
        if (saldo != null) 'saldo': saldo,
        if (activo != null) 'activo': activo,
      },
    });
  }

  Future<void> deleteUser(String userId) async {
    _dataSource.send({
      'type': 'admin_delete_user',
      'data': {'userId': userId},
    });
  }

  Future<void> deleteInvestment(String investmentId) async {
    _dataSource.send({
      'type': 'admin_delete_investment',
      'data': {'investmentId': investmentId},
    });
  }

  Future<void> cancelInvestment(String investmentId, String motivo) async {
    _dataSource.send({
      'type': 'admin_cancel_investment',
      'data': {
        'investmentId': investmentId,
        'motivo': motivo,
      },
    });
  }

  Future<void> editInvestment({
    required String id,
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
  }) async {
    _dataSource.send({
      'type': 'admin_edit_investment',
      'data': {
        'id': id,
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'perfil': perfil,
        'proyectoId': proyectoId,
        'proyectoNombre': proyectoNombre,
        'temaId': temaId,
        'temaNombre': temaNombre,
        'temaColor': temaColor,
        'monto': monto,
        if (observaciones != null) 'observaciones': observaciones,
      },
    });
  }

  Future<void> createManualInvestment({
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
  }) async {
    _dataSource.send({
      'type': 'admin_create_investment',
      'data': {
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'perfil': perfil,
        'proyectoId': proyectoId,
        'proyectoNombre': proyectoNombre,
        'temaId': temaId,
        'temaNombre': temaNombre,
        'temaColor': temaColor,
        'monto': monto,
        'observaciones': observaciones,
      },
    });
  }

  Future<void> startRound() async {
    _dataSource.send({
      'type': 'admin_start_round',
      'data': {},
    });
  }

  Future<void> pauseRound() async {
    _dataSource.send({
      'type': 'admin_pause_round',
      'data': {},
    });
  }

  Future<void> endRound() async {
    _dataSource.send({
      'type': 'admin_end_round',
      'data': {},
    });
  }

  Future<void> setRoundDuration(int minutes) async {
    _dataSource.send({
      'type': 'admin_set_duration',
      'data': {'minutes': minutes},
    });
  }

  Future<void> resetRound() async {
    _dataSource.send({
      'type': 'admin_reset_round',
      'data': {},
    });
  }
}
