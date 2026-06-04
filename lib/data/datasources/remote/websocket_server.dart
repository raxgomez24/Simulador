import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../data/models/websocket_message.dart';

/// Servidor WebSocket básico para sincronización en tiempo real
///
/// Esta clase proporciona la infraestructura base para manejar conexiones
/// WebSocket y broadcast de mensajes a todos los clientes conectados.
///
/// Requisitos del sistema:
/// - Soporta 70+ usuarios concurrentes
/// - Sincronización en tiempo real de datos de inversión
/// - Manejo robusto de conexiones y desconexiones
class WebSocketServer {
  /// Lista de clientes WebSocket conectados
  final List<WebSocketChannel> _clients = [];

  /// Servidor HTTP que contiene el endpoint WebSocket
  HttpServer? _server;

  /// StreamController para broadcast de mensajes a todos los clientes
  final StreamController<Map<String, dynamic>> _broadcastController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Inicia el servidor WebSocket
  ///
  /// [host] Dirección de escucha (default: '0.0.0.0' para aceptar conexiones de cualquier IP)
  /// [port] Puerto de escucha (default: 8080)
  ///
  /// Retorna un Future que completa cuando el servidor está iniciado
  Future<void> startServer({
    String host = '0.0.0.0',
    int port = 8080,
  }) async {
    // Crear handler WebSocket
    final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
      print('Cliente conectado: ${webSocket.hashCode}');

      // Agregar cliente a la lista de conectados
      _clients.add(webSocket);

      // Suscribirse a mensajes del cliente
      webSocket.stream.listen(
        (data) {
          _handleMessage(data, webSocket);
        },
        onError: (error) {
          print('Error en cliente ${webSocket.hashCode}: $error');
          _removeClient(webSocket);
        },
        onDone: () {
          print('Cliente desconectado: ${webSocket.hashCode}');
          _removeClient(webSocket);
        },
        cancelOnError: false,
      );

      // Enviar mensaje de bienvenida
      webSocket.sink.add({
        'type': 'connection',
        'status': 'connected',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Conexión WebSocket establecida',
      });
    });

    // Crear y configurar el servidor
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(wsHandler);

    // Iniciar servidor
    _server = await shelf_io.serve(handler, host, port);
    print('Servidor WebSocket iniciado en $host:$port');
    print('Esperando conexiones...');

    // Suscribirse al stream de broadcast
    _broadcastController.stream.listen((message) {
      broadcast(message);
    });
  }

  /// Procesa mensajes recibidos desde un cliente
  ///
  /// [data] Datos recibidos del cliente (debe ser un Map JSON)
  /// [client] Canal WebSocket del cliente que envió el mensaje
  void _handleMessage(dynamic data, WebSocketChannel client) {
    print('Mensaje recibido de cliente ${client.hashCode}: $data');

    try {
      // Validar que data es un Map
      if (data is! Map<String, dynamic>) {
        print('Error: Mensaje no es un Map válido');
        _sendError(client, 'Formato de mensaje inválido');
        return;
      }

      // Parsear el mensaje a WSMessage
      final message = WSMessage.fromJson(data);
      print('Mensaje parseado: ${message.toString()}');

      // Routing al handler correcto según el tipo de mensaje
      switch (message.type) {
        case WSMessage.TYPE_INVESTMENT:
          _handleInvestmentMessage(message, client);
          break;

        case WSMessage.TYPE_SESSION:
          _handleSessionMessage(message, client);
          break;

        case WSMessage.TYPE_USER:
          _handleUserMessage(message, client);
          break;

        case WSMessage.TYPE_PROJECT:
          _handleProjectMessage(message, client);
          break;

        default:
          print('Tipo de mensaje desconocido: ${message.type}');
          _sendError(client, 'Tipo de mensaje desconocido: ${message.type}');
      }

    } catch (e) {
      print('Error procesando mensaje: $e');

      // Enviar error al cliente
      _sendError(client, 'Error procesando mensaje: $e');
    }
  }

  /// Maneja mensajes relacionados con inversiones
  ///
  /// [message] Mensaje de tipo inversión
  /// [sender] Cliente que envió el mensaje
  void _handleInvestmentMessage(WSMessage message, WebSocketChannel sender) {
    print('🔔 Handler INVESTMENT: ${message.type}/${message.action}');

    // Broadcast del mensaje a todos los clientes conectados
    // NOTA: Por ahora solo hacemos broadcast sin lógica de negocio
    broadcast(message.toJson());
  }

  /// Maneja mensajes relacionados con sesiones (timer sessions)
  ///
  /// [message] Mensaje de tipo sesión
  /// [sender] Cliente que envió el mensaje
  void _handleSessionMessage(WSMessage message, WebSocketChannel sender) {
    print('⏱️ Handler SESSION: ${message.type}/${message.action}');

    // Broadcast del mensaje a todos los clientes conectados
    // NOTA: Por ahora solo hacemos broadcast sin lógica de negocio
    broadcast(message.toJson());
  }

  /// Maneja mensajes relacionados con usuarios
  ///
  /// [message] Mensaje de tipo usuario
  /// [sender] Cliente que envió el mensaje
  void _handleUserMessage(WSMessage message, WebSocketChannel sender) {
    print('👤 Handler USER: ${message.type}/${message.action}');

    // Broadcast del mensaje a todos los clientes conectados
    // NOTA: Por ahora solo hacemos broadcast sin lógica de negocio
    broadcast(message.toJson());
  }

  /// Maneja mensajes relacionados con proyectos
  ///
  /// [message] Mensaje de tipo proyecto
  /// [sender] Cliente que envió el mensaje
  void _handleProjectMessage(WSMessage message, WebSocketChannel sender) {
    print('📁 Handler PROJECT: ${message.type}/${message.action}');

    // Broadcast del mensaje a todos los clientes conectados
    // NOTA: Por ahora solo hacemos broadcast sin lógica de negocio
    broadcast(message.toJson());
  }

  /// Envía un mensaje de error a un cliente específico
  ///
  /// [client] Cliente que recibirá el error
  /// [errorMessage] Descripción del error
  void _sendError(WebSocketChannel client, String errorMessage) {
    client.sink.add({
      'type': 'error',
      'message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Envía un mensaje a todos los clientes conectados (broadcast)
  ///
  /// [message] Mapa con el mensaje a enviar
  void broadcast(Map<String, dynamic> message) {
    print('Broadcasting a ${_clients.length} clientes: $message');

    // Enviar a todos los clientes conectados
    final clientsToRemove = <WebSocketChannel>[];

    for (final client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        print('Error enviando a cliente ${client.hashCode}: $e');
        clientsToRemove.add(client);
      }
    }

    // Remover clientes que fallaron
    for (final client in clientsToRemove) {
      _removeClient(client);
    }
  }

  /// Remueve un cliente de la lista de conectados
  ///
  /// [client] Canal WebSocket a remover
  void _removeClient(WebSocketChannel client) {
    _clients.remove(client);
    print('Cliente removido. Conectados actuales: ${_clients.length}');
  }

  /// Detiene el servidor WebSocket
  Future<void> stopServer() async {
    print('Deteniendo servidor WebSocket...');

    // Cerrar todas las conexiones de clientes
    for (final client in _clients) {
      try {
        client.sink.close();
      } catch (e) {
        print('Error cerrando conexión: $e');
      }
    }

    // Limpiar lista de clientes
    _clients.clear();

    // Cerrar el broadcast controller
    await _broadcastController.close();

    // Detener el servidor
    await _server?.close();
    _server = null;

    print('Servidor detenido');
  }

  /// Retorna el número de clientes conectados
  int get connectedClientsCount => _clients.length;

  /// Indica si el servidor está corriendo
  bool get isRunning => _server != null;
}

// Tipo alias para compatibilidad
typedef WebSocketSocket = WebSocketChannel;
