import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import '../../app/config.dart';

final webSocketDataSourceProvider = Provider<WebSocketDataSource>((ref) {
  return WebSocketDataSource();
});

final sessionProvider = StreamNotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);

class SessionNotifier extends StreamNotifier<Session> {
  late WebSocketDataSource _dataSource;
  StreamSubscription? _messageSubscription;

  // Timer local para cuando useLocalData = true
  Timer? _localTimer;
  Session? _localSession;
  DateTime? _sessionStartedAt;
  Duration _pauseDuration = Duration.zero;
  DateTime? _pausedAt;

  @override
  Stream<Session> build() {
    _dataSource = ref.read(webSocketDataSourceProvider);

    // Solo conectar al servidor si no estamos usando datos locales
    if (!AppConfig.useLocalData) {
      // Conectar al servidor y escuchar eventos
      _dataSource.connect('ws://localhost:8080');

      // Escuchar mensajes del servidor
      _messageSubscription = _dataSource.messageStream.listen(
        _handleMessage,
        onError: (error) => debugPrint('Error en session provider: $error'),
      );

      // Emitir la sesión inicial cada segundo hasta que recibamos actualizaciones
      return Stream.periodic(const Duration(seconds: 1), (_) {
        return state.value ?? _getDefaultSession();
      });
    } else {
      // Modo local: inicializar sesión local en estado WAITING (no iniciar automáticamente)
      _localSession = _getDefaultSession();
      debugPrint('Usando datos locales, sesión en estado waiting');

      // NO INICIAR AUTOMÁTICAMENTE - Dejar que el admin controle la ronda
      _localSession = _localSession!.copyWith(
        estado: SessionState.waiting, // Changed from active to waiting
        startedAt: null, // No iniciar hasta que el admin lo indique
        tiempoRestante: _localSession!.tiempoTotal,
      );
      _sessionStartedAt = null; // No hay tiempo de inicio hasta iniciar
      _pauseDuration = Duration.zero;

      // NO iniciar el timer automáticamente - esperar a que el admin inicie la ronda
      // _startLocalTimer(); // COMENTADO - No iniciar timer automáticamente

      // Emitir el valor inicial inmediatamente
      state = AsyncValue.data(_localSession!);
      debugPrint('Sesión en estado waiting - esperando que admin inicie la ronda');

      // Retornar stream que emite cada segundo (solo para actualizaciones manuales)
      return Stream.periodic(const Duration(seconds: 1), (_) {
        return _localSession!;
      });
    }
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateLocalSession();
    });
  }

  void _updateLocalSession() {
    if (_localSession == null) return;

    final currentSession = _localSession!;

    // Solo actualizar tiempo si la sesión está activa
    if (currentSession.estado == SessionState.active && _sessionStartedAt != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_sessionStartedAt!) - _pauseDuration;
      final tiempoRestante = currentSession.tiempoTotal - elapsed;

      if (tiempoRestante <= Duration.zero) {
        // El tiempo se ha agotado
        _localSession = currentSession.copyWith(
          tiempoRestante: Duration.zero,
          estado: SessionState.ended,
          endedAt: now,
        );
        _localTimer?.cancel();
        debugPrint('Sesión finalizada - tiempo agotado');

        // Broadcast del evento de sesión finalizada
        _dataSource.send({
          'type': 'session_ended',
          'data': _serializeSession(_localSession!),
        });
      } else {
        _localSession = currentSession.copyWith(
          tiempoRestante: tiempoRestante,
        );

        // Broadcast de actualización de sesión (tiempo restante)
        _dataSource.send({
          'type': 'session_updated',
          'data': _serializeSession(_localSession!),
        });
      }
    }

    // Emitir actualización
    state = AsyncValue.data(_localSession!);
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'session_update':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          state = AsyncValue.data(_parseSession(data));
        }
        break;
      case 'session_updated':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          state = AsyncValue.data(_parseSession(data));
        }
        break;
      case 'session_started':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = _parseSession(data);
          state = AsyncValue.data(session);
          debugPrint('Sesión iniciada (recibido del servidor)');
        }
        break;
      case 'session_paused':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = _parseSession(data);
          state = AsyncValue.data(session);
          debugPrint('Sesión pausada (recibido del servidor)');
        }
        break;
      case 'session_resumed':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = _parseSession(data);
          state = AsyncValue.data(session);
          debugPrint('Sesión reanudada (recibido del servidor)');
        }
        break;
      case 'session_ended':
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final session = _parseSession(data);
          state = AsyncValue.data(session);
          debugPrint('Sesión finalizada (recibido del servidor)');
        }
        break;
      case 'investment_update':
        // Una nueva inversión actualiza la sesión también
        ref.invalidateSelf();
        break;
    }
  }

  Session _parseSession(Map<String, dynamic> data) {
    return Session(
      id: data['id'] as String,
      tiempoRestante: Duration(seconds: data['tiempoRestante'] as int? ?? 0),
      tiempoTotal: Duration(seconds: data['tiempoTotal'] as int? ?? 1800),
      estado: _parseSessionState(data['estado'] as String?),
      numeroParticipantes: data['numeroParticipantes'] as int? ?? 0,
      numeroProyectos: data['numeroProyectos'] as int? ?? 0,
      totalInvertido: (data['totalInvertido'] as num?)?.toDouble() ?? 0,
    );
  }

  SessionState _parseSessionState(String? state) {
    switch (state) {
      case 'waiting':
        return SessionState.waiting;
      case 'active':
        return SessionState.active;
      case 'paused':
        return SessionState.paused;
      case 'ended':
        return SessionState.ended;
      default:
        return SessionState.waiting;
    }
  }

  Session _getDefaultSession() {
    return const Session(
      id: '1',
      tiempoRestante: AppConfig.roundDuration,
      tiempoTotal: AppConfig.roundDuration,
      estado: SessionState.waiting,
      numeroParticipantes: 0,
      numeroProyectos: 0,
      totalInvertido: 0,
    );
  }

  Map<String, dynamic> _serializeSession(Session session) {
    return {
      'id': session.id,
      'tiempoRestante': session.tiempoRestante.inSeconds,
      'tiempoTotal': session.tiempoTotal.inSeconds,
      'estado': session.estado.name,
      'numeroParticipantes': session.numeroParticipantes,
      'numeroProyectos': session.numeroProyectos,
      'totalInvertido': session.totalInvertido,
      'startedAt': session.startedAt?.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
    };
  }

  // Métodos de control para modo local
  void startSession() {
    if (!AppConfig.useLocalData) {
      debugPrint('startSession solo funciona en modo local');
      return;
    }

    _localSession ??= _getDefaultSession();

    final now = DateTime.now();
    _localSession = _localSession!.copyWith(
      estado: SessionState.active,
      startedAt: now,
      tiempoRestante: _localSession!.tiempoTotal,
    );

    _sessionStartedAt = now;
    _pauseDuration = Duration.zero;
    _pausedAt = null;

    // Start the timer to update the session every second
    _startLocalTimer();

    state = AsyncValue.data(_localSession!);

    // Broadcast del evento a través del WebSocket
    _dataSource.send({
      'type': 'session_started',
      'data': _serializeSession(_localSession!),
    });

    final totalDuration = _localSession!.tiempoTotal;
    debugPrint('Sesión iniciada - Duración: ${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s');
  }

  void pauseSession() {
    if (!AppConfig.useLocalData) {
      debugPrint('pauseSession solo funciona en modo local');
      return;
    }

    if (_localSession == null || _localSession!.estado != SessionState.active) {
      debugPrint('No se puede pausar: la sesión no está activa');
      return;
    }

    _pausedAt = DateTime.now();
    _localSession = _localSession!.copyWith(
      estado: SessionState.paused,
    );

    state = AsyncValue.data(_localSession!);

    // Broadcast del evento a través del WebSocket
    _dataSource.send({
      'type': 'session_paused',
      'data': _serializeSession(_localSession!),
    });

    debugPrint('Sesión pausada');
  }

  void resumeSession() {
    if (!AppConfig.useLocalData) {
      debugPrint('resumeSession solo funciona en modo local');
      return;
    }

    if (_localSession == null || _localSession!.estado != SessionState.paused) {
      debugPrint('No se puede reanudar: la sesión no está pausada');
      return;
    }

    if (_pausedAt != null) {
      _pauseDuration += DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
    }

    _localSession = _localSession!.copyWith(
      estado: SessionState.active,
    );

    // Ensure timer is running
    _startLocalTimer();

    state = AsyncValue.data(_localSession!);

    // Broadcast del evento a través del WebSocket
    _dataSource.send({
      'type': 'session_resumed',
      'data': _serializeSession(_localSession!),
    });

    debugPrint('Sesión reanudada');
  }

  void endSession() {
    if (!AppConfig.useLocalData) {
      debugPrint('endSession solo funciona en modo local');
      return;
    }

    if (_localSession == null) {
      return;
    }

    final now = DateTime.now();
    _localSession = _localSession!.copyWith(
      estado: SessionState.ended,
      endedAt: now,
    );

    _localTimer?.cancel();
    state = AsyncValue.data(_localSession!);

    // Broadcast del evento a través del WebSocket
    _dataSource.send({
      'type': 'session_ended',
      'data': _serializeSession(_localSession!),
    });

    debugPrint('Sesión finalizada manualmente');
  }

  void resetSession({Duration? customDuration}) {
    if (!AppConfig.useLocalData) {
      debugPrint('resetSession solo funciona en modo local');
      return;
    }

    final duration = customDuration ?? AppConfig.roundDuration;

    _localSession = Session(
      id: '1',
      tiempoRestante: duration,
      tiempoTotal: duration,
      estado: SessionState.waiting,
      numeroParticipantes: 0,
      numeroProyectos: 0,
      totalInvertido: 0,
    );

    _sessionStartedAt = null;
    _pauseDuration = Duration.zero;
    _pausedAt = null;

    state = AsyncValue.data(_localSession!);
    debugPrint('Sesión reiniciada - Nueva duración: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
  }

  void setSessionDuration(int minutes) {
    if (!AppConfig.useLocalData) {
      debugPrint('setSessionDuration solo funciona en modo local');
      return;
    }

    final newDuration = Duration(minutes: minutes);

    if (_localSession != null) {
      // Si la sesión está activa, ajustar proporcionalmente
      if (_localSession!.estado == SessionState.active && _sessionStartedAt != null) {
        final elapsed = DateTime.now().difference(_sessionStartedAt!) - _pauseDuration;
        var newTiempoRestante = newDuration - elapsed;

        // Asegurar que el tiempo restante no sea negativo
        if (newTiempoRestante.isNegative) {
          newTiempoRestante = Duration.zero;
        }

        _localSession = _localSession!.copyWith(
          tiempoTotal: newDuration,
          tiempoRestante: newTiempoRestante,
        );
      } else {
        // Si no está activa, solo actualizar el tiempo total
        _localSession = _localSession!.copyWith(
          tiempoTotal: newDuration,
          tiempoRestante: newDuration,
        );
      }

      state = AsyncValue.data(_localSession!);

      // Broadcast de actualización
      _dataSource.send({
        'type': 'session_updated',
        'data': _serializeSession(_localSession!),
      });

      debugPrint('Duración de sesión actualizada a $minutes minutos');
    }
  }

  void updateParticipants(int count) {
    if (!AppConfig.useLocalData) {
      debugPrint('updateParticipants solo funciona en modo local');
      return;
    }

    if (_localSession != null) {
      _localSession = _localSession!.copyWith(
        numeroParticipantes: count,
      );
      state = AsyncValue.data(_localSession!);

      // Broadcast de actualización
      _dataSource.send({
        'type': 'session_updated',
        'data': _serializeSession(_localSession!),
      });
    }
  }

  void updateProjects(int count) {
    if (!AppConfig.useLocalData) {
      debugPrint('updateProjects solo funciona en modo local');
      return;
    }

    if (_localSession != null) {
      _localSession = _localSession!.copyWith(
        numeroProyectos: count,
      );
      state = AsyncValue.data(_localSession!);

      // Broadcast de actualización
      _dataSource.send({
        'type': 'session_updated',
        'data': _serializeSession(_localSession!),
      });
    }
  }

  void updateTotalInvested(double amount) {
    if (!AppConfig.useLocalData) {
      debugPrint('updateTotalInvested solo funciona en modo local');
      return;
    }

    if (_localSession != null) {
      _localSession = _localSession!.copyWith(
        totalInvertido: amount,
      );
      state = AsyncValue.data(_localSession!);

      // Broadcast de actualización
      _dataSource.send({
        'type': 'session_updated',
        'data': _serializeSession(_localSession!),
      });
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _localTimer?.cancel();
  }
}
