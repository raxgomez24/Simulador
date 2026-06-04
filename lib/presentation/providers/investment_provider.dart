import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../domain/usecases/investment/invest_usecase.dart';
import '../../domain/usecases/investment/get_investments_usecase.dart';
import '../../data/repositories/investment_repository_impl.dart';
import '../../data/repositories/investment_repository_local.dart';
import '../../data/models/websocket_message.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import '../../app/config.dart';
import 'websocket_provider.dart';
import 'project_provider.dart';

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  // En web, no usar repositorio local (no SQLite disponible)
  if (AppConfig.isWeb || !AppConfig.useLocalData) {
    final dataSource = ref.read(webSocketDataSourceProvider);
    return InvestmentRepositoryImpl(dataSource);
  } else {
    return InvestmentRepositoryLocal();
  }
});

/// Provider principal que gestiona la integración WebSocket-Inversiones
///
/// Escucha eventos de inversión del WebSocket y actualiza:
/// - Lista de inversiones del usuario actual
/// - Rankings de inversión
/// - Montos totales de proyectos
final investmentWebSocketProvider = Provider<InvestmentWebSocketNotifier>((ref) {
  final dataSource = ref.watch(webSocketDataSourceProvider);
  final notifier = InvestmentWebSocketNotifier(ref, dataSource);

  // Escuchar mensajes del WebSocket
  final subscription = dataSource.messageStream.listen((message) {
    notifier.handleWebSocketMessage(message);
  });

  // Limpiar recursos al dispose
  ref.onDispose(() {
    subscription.cancel();
    notifier.dispose();
  });

  return notifier;
});

/// Notifier que gestiona eventos de inversión via WebSocket
class InvestmentWebSocketNotifier {
  final Ref _ref;
  final WebSocketDataSource _dataSource;

  InvestmentWebSocketNotifier(this._ref, this._dataSource);

  /// Procesa mensajes recibidos del WebSocket
  void handleWebSocketMessage(Map<String, dynamic> message) {
    try {
      final wsMessage = WSMessage.fromJson(message);

      // Solo procesar mensajes de inversión
      if (wsMessage.type != WSMessage.TYPE_INVESTMENT) return;

      print('📊 Mensaje de inversión recibido: ${wsMessage.action}');

      switch (wsMessage.action) {
        case WSMessage.ACTION_INVESTMENT_CREATED:
          _handleInvestmentCreated(wsMessage.data);
          break;
        case WSMessage.ACTION_INVESTMENT_UPDATED:
          _handleInvestmentUpdated(wsMessage.data);
          break;
        case WSMessage.ACTION_INVESTMENT_DELETED:
          _handleInvestmentDeleted(wsMessage.data);
          break;
      }
    } catch (e) {
      print('❌ Error procesando mensaje de inversión: $e');
    }
  }

  /// Maneja el evento de inversión creada
  void _handleInvestmentCreated(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      print('💰 Nueva inversión creada: $data');

      // Invalidar providers para forzar recarga
      _ref.invalidate(investmentsProvider);
      _ref.invalidate(projectInvestmentsProvider);
      _ref.invalidate(projectsProvider);
      _ref.invalidate(projectDetailProvider);

      print('✅ Providers invalidados tras nueva inversión');
    } catch (e) {
      print('❌ Error manejando inversión creada: $e');
    }
  }

  /// Maneja el evento de inversión actualizada
  void _handleInvestmentUpdated(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      print('🔄 Inversión actualizada: $data');

      // Invalidar providers para reflejar cambios
      _ref.invalidate(investmentsProvider);
      _ref.invalidate(projectInvestmentsProvider);
      _ref.invalidate(projectsProvider);
      _ref.invalidate(projectDetailProvider);

      print('✅ Providers invalidados tras inversión actualizada');
    } catch (e) {
      print('❌ Error manejando inversión actualizada: $e');
    }
  }

  /// Maneja el evento de inversión eliminada/cancelada
  void _handleInvestmentDeleted(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      print('🗑️ Inversión eliminada: $data');

      // Invalidar providers para reflejar eliminación
      _ref.invalidate(investmentsProvider);
      _ref.invalidate(projectInvestmentsProvider);
      _ref.invalidate(projectsProvider);
      _ref.invalidate(projectDetailProvider);

      print('✅ Providers invalidados tras inversión eliminada');
    } catch (e) {
      print('❌ Error manejando inversión eliminada: $e');
    }
  }

  /// Broadcast evento de inversión creada
  ///
  /// Se llama después de crear exitosamente una inversión
  void broadcastInvestmentCreated(Investment investment) {
    final message = WSMessage(
      type: WSMessage.TYPE_INVESTMENT,
      action: WSMessage.ACTION_INVESTMENT_CREATED,
      data: _investmentToJson(investment),
      timestamp: DateTime.now().toIso8601String(),
    );

    _dataSource.send(message.toJson());
    print('📢 Broadcasting investment_created: ${investment.id}');
  }

  /// Broadcast evento de inversión actualizada
  void broadcastInvestmentUpdated(Investment investment) {
    final message = WSMessage(
      type: WSMessage.TYPE_INVESTMENT,
      action: WSMessage.ACTION_INVESTMENT_UPDATED,
      data: _investmentToJson(investment),
      timestamp: DateTime.now().toIso8601String(),
    );

    _dataSource.send(message.toJson());
    print('📢 Broadcasting investment_updated: ${investment.id}');
  }

  /// Broadcast evento de inversión cancelada/eliminada
  void broadcastInvestmentDeleted(String investmentId) {
    final message = WSMessage(
      type: WSMessage.TYPE_INVESTMENT,
      action: WSMessage.ACTION_INVESTMENT_DELETED,
      data: {'id': investmentId},
      timestamp: DateTime.now().toIso8601String(),
    );

    _dataSource.send(message.toJson());
    print('📢 Broadcasting investment_deleted: $investmentId');
  }

  /// Convierte una entidad Investment a JSON para WebSocket
  Map<String, dynamic> _investmentToJson(Investment investment) {
    return {
      'id': investment.id,
      'usuario_id': investment.usuarioId,
      'usuario_nombre': investment.usuarioNombre,
      'perfil': investment.perfil.toString().split('.').last,
      'proyecto_id': investment.proyectoId,
      'proyecto_nombre': investment.proyectoNombre,
      'tema_id': investment.temaId,
      'tema_nombre': investment.temaNombre,
      'tema_color': investment.temaColor,
      'monto': investment.monto,
      'fecha_hora': investment.fechaHora.toIso8601String(),
      'observaciones': investment.observaciones,
      'estado': investment.estado.toServerString,
    };
  }

  void dispose() {
    // Limpieza adicional si es necesaria
  }
}

final investUseCaseProvider = Provider<InvestUseCase>((ref) {
  return InvestUseCase(ref.read(investmentRepositoryProvider));
});

final getInvestmentsUseCaseProvider = Provider<GetInvestmentsUseCase>((ref) {
  return GetInvestmentsUseCase(ref.read(investmentRepositoryProvider));
});

final investmentsProvider = FutureProvider.autoDispose
    .family<List<Investment>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  final useCase = ref.read(getInvestmentsUseCaseProvider);
  return await useCase.callByUser(userId);
});

class ProjectInvestmentsNotifier extends FamilyAsyncNotifier<List<Investment>, String> {
  String? _currentProjectId;

  @override
  Future<List<Investment>> build(String arg) async {
    final projectId = arg;
    if (projectId.isEmpty) return [];
    _currentProjectId = projectId;
    final useCase = ref.read(getInvestmentsUseCaseProvider);
    return await useCase.callByProject(projectId);
  }

  Future<void> refresh() async {
    if (_currentProjectId == null) return;
    state = const AsyncValue.loading();
    final useCase = ref.read(getInvestmentsUseCaseProvider);
    state = await AsyncValue.guard(() => useCase.callByProject(_currentProjectId!));
  }
}

final projectInvestmentsProvider = Provider
    .family<ProjectInvestmentsNotifier, String>(
  (ref, projectId) => ProjectInvestmentsNotifier()..build(projectId),
);

/// Provider para operaciones de inversión con broadcast WebSocket
///
/// Usa este provider para crear, actualizar o eliminar inversiones
/// cuando quieras que todos los dispositivos vean los cambios.
final investmentOperationsProvider = Provider<InvestmentOperationsNotifier>((ref) {
  final repository = ref.read(investmentRepositoryProvider);
  final wsNotifier = ref.read(investmentWebSocketProvider);
  return InvestmentOperationsNotifier(ref, repository, wsNotifier);
});

/// Notifier que envuelve operaciones de inversión con broadcast WebSocket
class InvestmentOperationsNotifier {
  final Ref _ref;
  final InvestmentRepository _repository;
  final InvestmentWebSocketNotifier _wsNotifier;

  InvestmentOperationsNotifier(this._ref, this._repository, this._wsNotifier);

  /// Crea una inversión y broadcast a todos los dispositivos
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
    try {
      // Crear la inversión
      final investment = await _repository.createInvestment(
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        perfil: perfil,
        proyectoId: proyectoId,
        proyectoNombre: proyectoNombre,
        temaId: temaId,
        temaNombre: temaNombre,
        temaColor: temaColor,
        monto: monto,
        observaciones: observaciones,
        sessionState: sessionState,
      );

      // Broadcast del evento a todos los dispositivos
      _wsNotifier.broadcastInvestmentCreated(investment);

      return investment;
    } catch (e) {
      print('❌ Error creando inversión: $e');
      rethrow;
    }
  }

  /// Actualiza una inversión y broadcast a todos los dispositivos
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
    try {
      // Actualizar la inversión
      final investment = await _repository.updateInvestment(
        id: id,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        perfil: perfil,
        proyectoId: proyectoId,
        proyectoNombre: proyectoNombre,
        temaId: temaId,
        temaNombre: temaNombre,
        temaColor: temaColor,
        monto: monto,
        observaciones: observaciones,
        estado: estado,
      );

      // Broadcast del evento a todos los dispositivos
      _wsNotifier.broadcastInvestmentUpdated(investment);

      return investment;
    } catch (e) {
      print('❌ Error actualizando inversión: $e');
      rethrow;
    }
  }

  /// Elimina una inversión y broadcast a todos los dispositivos
  Future<void> deleteInvestment(String investmentId) async {
    try {
      // Eliminar la inversión
      await _repository.deleteInvestment(investmentId);

      // Broadcast del evento a todos los dispositivos
      _wsNotifier.broadcastInvestmentDeleted(investmentId);
    } catch (e) {
      print('❌ Error eliminando inversión: $e');
      rethrow;
    }
  }

  /// Invierte en un proyecto (método simplificado)
  Future<Investment> makeInvestment({
    required String userId,
    required String projectId,
    required double amount,
    SessionState? sessionState,
  }) async {
    try {
      // NOTA: Este método es un wrapper simplificado.
      // En producción, deberías obtener los datos completos del usuario
      // y proyecto desde sus respectivos providers antes de llamar a createInvestment.

      // Por ahora, creamos una inversión con datos mínimos.
      // El usuario de este método es responsable de proporcionar
      // los datos completos del proyecto y usuario.
      final investment = await createInvestment(
        usuarioId: userId,
        usuarioNombre: 'Usuario', // Debería obtenerse del user provider
        perfil: 'student',
        proyectoId: projectId,
        proyectoNombre: 'Proyecto', // Debería obtenerse del project provider
        temaId: '',
        temaNombre: '',
        temaColor: '#00D4AA',
        monto: amount,
        sessionState: sessionState,
      );

      return investment;
    } catch (e) {
      print('❌ Error en makeInvestment: $e');
      rethrow;
    }
  }
}
