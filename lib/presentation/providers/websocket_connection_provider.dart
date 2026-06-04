import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config.dart';
import 'project_provider.dart';
import 'auth_provider.dart';
import 'websocket_provider.dart';

/// Estado de la conexión WebSocket
class WebSocketConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final DateTime? lastConnectedAt;
  final int reconnectAttempts;

  const WebSocketConnectionState({
    required this.isConnected,
    this.isConnecting = false,
    this.error,
    this.lastConnectedAt,
    this.reconnectAttempts = 0,
  });

  WebSocketConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    DateTime? lastConnectedAt,
    int? reconnectAttempts,
  }) {
    return WebSocketConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

/// Notifier que gestiona la conexión WebSocket y actualiza providers
class WebSocketConnectionNotifier extends StateNotifier<WebSocketConnectionState> {
  StreamSubscription? _messageSubscription;

  WebSocketConnectionNotifier() : super(const WebSocketConnectionState(isConnected: false));

  Future<void> connect(Ref ref) async {
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(isConnecting: true, error: null);

    try {
      // Usar la instancia compartida de WebSocketDataSource del authProvider
      final dataSource = ref.read(webSocketDataSourceProvider);

      // Conectar si no está conectado
      if (!dataSource.isConnected) {
        await dataSource.connect(AppConfig.defaultWebSocketUrl);
      }

      // Escuchar mensajes del servidor
      _messageSubscription = dataSource.messageStream.listen(
        (message) => _handleMessage(message, ref),
        onError: (error) => state = state.copyWith(
          isConnected: false,
          isConnecting: false,
          error: error.toString(),
        ),
        onDone: () => state = state.copyWith(isConnected: false),
      );

      state = WebSocketConnectionState(
        isConnected: true,
        isConnecting: false,
        lastConnectedAt: DateTime.now(),
        reconnectAttempts: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: e.toString(),
        reconnectAttempts: state.reconnectAttempts + 1,
      );
    }
  }

  void _handleMessage(Map<String, dynamic> message, Ref ref) {
    final messageType = message['type'] as String?;

    switch (messageType) {
      case 'invest':
        // Alguien invirtió - invalidar providers de proyectos para actualizar ranking
        ref.invalidate(projectsProvider);
        ref.invalidate(themesProvider);

        // Actualizar saldo del usuario actual si él hizo la inversión
        _updateUserBalanceIfNecessary(message, ref);
        break;

      case 'timer_update':
        // El temporizador cambió - invalidar providers del temporizador
        // TODO: Implementar cuando exista timer_provider
        break;

      case 'round_state_update':
        // El estado de la ronda cambió (pausa/reanudación)
        // TODO: Implementar cuando exista timer_provider
        break;

      case 'sync_response':
        // Respuesta de sincronización - invalidar todos los providers
        ref.invalidate(projectsProvider);
        ref.invalidate(themesProvider);

        // Actualizar saldo del usuario actual si está en el mensaje
        _updateUserBalanceIfNecessary(message, ref);
        break;

      case 'heartbeat':
        // Heartbeat del servidor - mantener conexión viva
        break;

      default:
        debugPrint('Mensaje no manejado: $messageType');
    }
  }

  /// Actualiza el saldo del usuario actual si el mensaje contiene información de su saldo
  void _updateUserBalanceIfNecessary(Map<String, dynamic> message, Ref ref) {
    final authNotifier = ref.read(authProvider.notifier);
    final currentUserId = authNotifier.currentUser?.id;

    if (currentUserId == null) return;

    // Verificar si el mensaje contiene actualización de saldo para este usuario
    final userData = message['user'] as Map<String, dynamic>?;
    if (userData != null && userData['id'] == currentUserId) {
      final newBalance = userData['saldo'] as double?;
      if (newBalance != null) {
        authNotifier.updateBalance(newBalance);
        debugPrint('Saldo actualizado desde WebSocket: $newBalance');
      }
    }
  }

  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    state = const WebSocketConnectionState(isConnected: false);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider para el estado de conexión WebSocket
final webSocketConnectionProvider =
    StateNotifierProvider<WebSocketConnectionNotifier, WebSocketConnectionState>(
  (ref) {
    final notifier = WebSocketConnectionNotifier();

    // Conectar automáticamente al iniciar
    Future.microtask(() => notifier.connect(ref));

    // Limpiar al disposing
    ref.onDispose(() => notifier.dispose());

    return notifier;
  },
);
