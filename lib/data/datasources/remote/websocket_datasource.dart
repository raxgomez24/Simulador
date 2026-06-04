import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Estados de conexión del WebSocket
enum ConnectionState {
  /// Desconectado del servidor
  disconnected,
  /// Intentando conectar
  connecting,
  /// Conectado y operativo
  connected,
}

class WebSocketDataSource {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  // Estado de conexión
  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  /// Stream de mensajes recibidos del servidor
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Estado actual de la conexión
  ConnectionState get connectionState => _connectionState;

  /// Indica si está conectado al servidor
  bool get isConnected => _connectionState == ConnectionState.connected;

  /// Conecta al servidor WebSocket
  ///
  /// Establece la conexión e inicia el heartbeat si es exitoso.
  /// Si ya está conectado, no hace nada.
  Future<void> connect(String url) async {
    if (_connectionState == ConnectionState.connected) return;

    try {
      _connectionState = ConnectionState.connecting;
      print('Conectando WebSocket a $url...');

      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _connectionState = ConnectionState.connected;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      // Iniciar heartbeat
      _startHeartbeat();
      print('WebSocket conectado exitosamente');
    } catch (e) {
      _connectionState = ConnectionState.disconnected;
      print('Error al conectar WebSocket: $e');
      throw ConnectionException(
        message: 'Error al conectar con el servidor: ${e.toString()}',
        code: ApiConstants.errorConnectionLost,
      );
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = message is String ? json.decode(message) : message;
      print('Mensaje recibido del servidor: $data');
      _messageController.add(data as Map<String, dynamic>);
    } catch (e) {
      print('Error al decodificar mensaje: $e');
      // Ignore invalid messages
    }
  }

  void _handleError(error) {
    print('Error de WebSocket: $error');
    // No cambiar _isConnected inmediatamente, esperar a onDone
    _messageController.addError(error);
  }

  /// Maneja la desconexión del WebSocket
  ///
  /// Detiene el heartbeat, cambia el estado y programa reconexión
  /// si no se ha excedido el máximo de intentos.
  void _handleDone() {
    print('WebSocket desconectado');

    // Detener heartbeat
    _stopHeartbeat();

    // Cambiar estado a desconectado
    _connectionState = ConnectionState.disconnected;

    // Programar reconexión si intentos < 10
    if (_reconnectAttempts < 10) {
      _scheduleReconnect();
    } else {
      print('Número máximo de reconexiones alcanzado (10 intentos)');
      _messageController.addError(ConnectionException(
        message: 'No se pudo conectar después de 10 intentos',
        code: ApiConstants.errorConnectionLost,
      ));
    }
  }

  /// Programa un reintento de reconexión
  ///
  /// Espera 5 segundos antes de intentar reconectar.
  /// Incrementa el contador de intentos.
  void _scheduleReconnect() {
    _reconnectAttempts++;
    print('Intentando reconexión $_reconnectAttempts/10 en 5 segundos...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(seconds: 5),
      () => connect(ApiConstants.defaultWebSocketUrl),
    );
  }

  /// Inicia el heartbeat (ping) periódico
  ///
  /// Envía un mensaje ping cada 30 segundos para mantener
  /// la conexión activa y detectar desconexiones.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  /// Detiene el heartbeat
  ///
  /// Cancela el timer que envía los pings periódicos.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Envía un mensaje ping al servidor
  void _sendHeartbeat() {
    send({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Envía un mensaje al servidor WebSocket
  ///
  /// Solo envía si está conectado. Otherwise, logea un error.
  void send(Map<String, dynamic> data) {
    if (_channel != null && _connectionState == ConnectionState.connected) {
      try {
        _channel!.sink.add(json.encode(data));
        print('Mensaje enviado: $data');
      } catch (e) {
        print('Error al enviar mensaje: $e');
        _handleError(e);
      }
    } else {
      print('No conectado - no se pudo enviar mensaje');
    }
  }

  /// Desconecta del servidor WebSocket
  ///
  /// Detiene heartbeat, timers y cierra la conexión.
  Future<void> disconnect() async {
    _stopHeartbeat();
    _reconnectTimer?.cancel();

    await _channel?.sink.close();
    _channel = null;
    _connectionState = ConnectionState.disconnected;
    _reconnectAttempts = 0;

    print('WebSocket desconectado');
  }

  /// Libera recursos
  ///
  /// Desconecta y cierra el stream controller.
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
