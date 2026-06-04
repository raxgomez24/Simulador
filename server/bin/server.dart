import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Modelos de datos
class User {
  final String id;
  String nombre;
  String correo;
  String username;
  String password;
  String perfil;
  double saldo;
  bool activo;
  final DateTime fechaRegistro;

  User({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.username,
    required this.password,
    required this.perfil,
    required this.saldo,
    this.activo = true,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'correo': correo,
    'username': username,
    'perfil': perfil,
    'saldo': saldo,
    'activo': activo,
    'fechaRegistro': fechaRegistro.toIso8601String(),
    'isAdmin': perfil == 'Admin',
    'initials': nombre.split(' ').map((n) => n[0]).join(),
  };

  bool get isAdmin => perfil == 'Admin';

  static User fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nombre: json['nombre'],
    correo: json['correo'],
    username: json['username'],
    password: json['password'],
    perfil: json['perfil'],
    saldo: (json['saldo'] as num).toDouble(),
    activo: json['activo'] ?? true,
    fechaRegistro: DateTime.parse(json['fechaRegistro']),
  );
}

class InvestmentTheme {
  final String id;
  String nombre;
  String descripcion;
  String color;
  String icono;
  int orden;

  InvestmentTheme({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.color,
    required this.icono,
    this.orden = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'color': color,
    'icono': icono,
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  };
}

class Project {
  final String id;
  String titulo;
  String descripcion;
  final String temaId;
  final String temaNombre;
  final String temaColor;
  String imagen;
  final String pitch;
  final String problema;
  final String solucion;
  final String estrategiaIngresos;
  final String proyeccionFinanciera;
  final List<Participant> participantes;
  double totalInvertido;
  int numeroInversores;
  bool activo;

  Project({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.temaId,
    required this.temaNombre,
    required this.temaColor,
    this.imagen = '',
    this.pitch = '',
    this.problema = '',
    this.solucion = '',
    this.estrategiaIngresos = '',
    this.proyeccionFinanciera = '',
    List<Participant>? participantes,
    this.totalInvertido = 0,
    this.numeroInversores = 0,
    this.activo = true,
  }) : participantes = participantes ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': titulo,
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
    'participantes': participantes.map((p) => p.toJson()).toList(),
    'totalInvertido': totalInvertido,
    'numeroInversores': numeroInversores,
    'activo': activo,
  };
}

class Participant {
  final String nombre;
  final String rol;
  final String foto;

  Participant({required this.nombre, required this.rol, this.foto = ''});

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'rol': rol,
    'foto': foto,
  };
}

class Investment {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final String proyectoId;
  final String proyectoNombre;
  final double monto;
  final DateTime fechaHora;
  final String perfilUsuario;
  String observaciones;

  Investment({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.monto,
    required this.fechaHora,
    required this.perfilUsuario,
    this.observaciones = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioId': usuarioId,
    'usuarioNombre': usuarioNombre,
    'proyectoId': proyectoId,
    'proyectoNombre': proyectoNombre,
    'montoInvertido': monto,
    'fechaHora': fechaHora.toIso8601String(),
    'perfilUsuario': perfilUsuario,
    'observaciones': observaciones,
  };
}

class Session {
  final String id;
  Duration tiempoRestante;
  Duration tiempoTotal;
  String estado; // waiting, active, paused, ended
  int numeroParticipantes;
  int numeroProyectos;
  double totalInvertido;

  Session({
    required this.id,
    required this.tiempoRestante,
    required this.tiempoTotal,
    this.estado = 'waiting',
    this.numeroParticipantes = 0,
    this.numeroProyectos = 0,
    this.totalInvertido = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tiempoRestante': tiempoRestante.inSeconds,
    'tiempoTotal': tiempoTotal.inSeconds,
    'estado': estado,
    'numeroParticipantes': numeroParticipantes,
    'numeroProyectos': numeroProyectos,
    'totalInvertido': totalInvertido,
  };
}

// Estados del servidor
class ServerState {
  final Map<String, User> users = {};
  final Map<String, InvestmentTheme> themes = {};
  final Map<String, Project> projects = {};
  final List<Investment> investments = [];
  final Map<String, WebSocketConnection> connections = {};
  Session session = Session(
    id: '1',
    tiempoRestante: const Duration(minutes: 30),
    tiempoTotal: const Duration(minutes: 30),
  );

  bool get roundActive => session.estado == 'active';
  bool get roundPaused => session.estado == 'paused';
}

class WebSocketConnection {
  final WebSocket socket;
  final String id;
  User? user;

  WebSocketConnection(this.socket, this.id);
}

// Servidor
class AmerikeServer {
  final ServerState state = ServerState();
  Timer? _sessionTimer;

  Future<void> start() async {
    final port = 8080;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Servidor WebSocket ejecutándose en ws://$port');

    // Iniciar temporizador de sesión primero
    _startSessionTimer();

    // Inicializar datos de prueba
    _initializeMockData();

    await for (var request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        _handleWebSocket(await WebSocketTransformer.upgrade(request));
      } else {
        // Manejar peticiones HTTP normales (opcional)
        request.response.close();
      }
    }
  }

  void _handleWebSocket(WebSocket socket) {
    final connectionId = _generateId();
    final connection = WebSocketConnection(socket, connectionId);
    state.connections[connectionId] = connection;

    print('Cliente conectado: $connectionId');

    socket.listen(
      (message) => _handleMessage(connection, message),
      onError: (error) => print('Error en socket $connectionId: $error'),
      onDone: () => _handleDisconnect(connectionId),
      cancelOnError: false,
    );
  }

  void _handleMessage(WebSocketConnection connection, dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      print('Mensaje recibido de ${connection.id}: $message');
      final type = data['type'] as String?;

      switch (type) {
        case 'auth':
          _handleAuth(connection, data);
          break;
        case 'projects':
          _sendProjects(connection);
          break;
        case 'themes':
          _sendThemes(connection);
          break;
        case 'project_detail':
          _sendProjectDetail(connection, data);
          break;
        case 'invest':
          _handleInvestment(connection, data);
          break;
        case 'session':
          _sendSession(connection);
          break;
        case 'ranking':
          _sendRanking(connection);
          break;
        case 'users':
          _sendUsers(connection);
          break;
        case 'investments':
          _sendUserInvestments(connection, data);
          break;
        case 'admin_start_round':
          _handleStartRound(connection, data);
          break;
        case 'admin_pause_round':
          _handlePauseRound(connection);
          break;
        case 'admin_end_round':
          _handleEndRound(connection);
          break;
        case 'admin_set_duration':
          _handleSetDuration(connection, data);
          break;
        case 'admin_reset_round':
          _handleResetRound(connection, data);
          break;
        case 'admin_create_user':
          _handleCreateUser(connection, data);
          break;
        case 'admin_update_user':
          _handleUpdateUser(connection, data);
          break;
        case 'admin_delete_user':
          _handleDeleteUser(connection, data);
          break;
        case 'admin_create_theme':
          _handleCreateTheme(connection, data);
          break;
        case 'admin_update_theme':
          _handleUpdateTheme(connection, data);
          break;
        case 'admin_delete_theme':
          _handleDeleteTheme(connection, data);
          break;
        case 'admin_create_project':
          _handleCreateProject(connection, data);
          break;
        case 'admin_update_project':
          _handleUpdateProject(connection, data);
          break;
        case 'admin_delete_project':
          _handleDeleteProject(connection, data);
          break;
        case 'admin_delete_investment':
          _handleDeleteInvestment(connection, data);
          break;
        case 'heartbeat':
          _handleHeartbeat(connection);
          break;
        default:
          _sendError(connection, 'Tipo de mensaje desconocido: $type');
      }
    } catch (e) {
      print('Error procesando mensaje: $e');
      _sendError(connection, 'Error al procesar mensaje');
    }
  }

  void _handleDisconnect(String connectionId) {
    print('Cliente desconectado: $connectionId');
    state.connections.remove(connectionId);
  }

  void _handleAuth(WebSocketConnection connection, Map<String, dynamic> data) {
    final action = data['action'] as String?;

    if (action == 'login') {
      final username = data['username'] as String?;
      final password = data['password'] as String?;

      final user = state.users.values.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw Exception('Credenciales inválidas'),
      );

      if (!user.activo) {
        _sendError(connection, 'Usuario inactivo');
        return;
      }

      connection.user = user;
      _sendResponse(connection, 'auth', 'success', user.toJson());
    } else if (action == 'register_guest') {
      final username = data['username'] as String?;
      final fullName = data['nombre'] as String?;

      // Verificar que el username no exista
      if (state.users.values.any((u) => u.username == username)) {
        _sendError(connection, 'El username ya existe');
        return;
      }

      if (username == null || fullName == null) {
        _sendError(connection, 'Faltan datos requeridos');
        return;
      }

      final user = User(
        id: _generateId(),
        nombre: fullName,
        correo: '',
        username: username,
        password: 'guest123',
        perfil: 'Invitado',
        saldo: 5000000, // $5,000,000 para invitados
        fechaRegistro: DateTime.now(),
      );

      state.users[user.id] = user;
      connection.user = user;
      _sendResponse(connection, 'auth', 'success', user.toJson());
    } else {
      _sendError(connection, 'Acción desconocida');
    }
  }

  void _sendProjects(WebSocketConnection connection) {
    final projects = state.projects.values.map((p) => p.toJson()).toList();
    _sendResponse(connection, 'projects', 'success', projects);
  }

  void _sendThemes(WebSocketConnection connection) {
    final themes = state.themes.values.map((t) {
      final themeProjects = state.projects.values.where((p) => p.temaId == t.id);
      return {
        'id': t.id,
        'nombre': t.nombre,
        'color': t.color,
        'icono': t.icono,
        'numeroProyectos': themeProjects.length,
        'totalInvertido': themeProjects.fold(0.0, (sum, p) => sum + p.totalInvertido),
      };
    }).toList();
    _sendResponse(connection, 'themes', 'success', themes);
  }

  void _sendProjectDetail(WebSocketConnection connection, Map<String, dynamic> data) {
    final projectId = data['projectId'] as String?;
    final project = state.projects[projectId];

    if (project == null) {
      _sendError(connection, 'Proyecto no encontrado');
      return;
    }

    _sendResponse(connection, 'project_detail', 'success', project.toJson());
  }

  void _handleInvestment(WebSocketConnection connection, Map<String, dynamic> data) {
    final user = connection.user;
    if (user == null) {
      _sendError(connection, 'Usuario no autenticado');
      return;
    }

    if (!state.roundActive) {
      _sendError(connection, 'La ronda de inversión está cerrada');
      return;
    }

    final projectId = data['projectId'] as String?;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;

    final project = state.projects[projectId];
    if (project == null) {
      _sendError(connection, 'Proyecto no encontrado');
      return;
    }

    if (!project.activo) {
      _sendError(connection, 'El proyecto no está activo');
      return;
    }

    if (amount <= 0) {
      _sendError(connection, 'El monto debe ser mayor a cero');
      return;
    }

    if (amount > user.saldo) {
      _sendError(connection, 'Saldo insuficiente');
      return;
    }

    if (amount < 10000) {
      _sendError(connection, 'La inversión mínima es de \$10,000');
      return;
    }

    if (amount > 500000) {
      _sendError(connection, 'La inversión máxima es de \$500,000');
      return;
    }

    // Registrar inversión
    final investment = Investment(
      id: _generateId(),
      usuarioId: user.id,
      usuarioNombre: user.nombre,
      proyectoId: project.id,
      proyectoNombre: project.titulo,
      monto: amount,
      fechaHora: DateTime.now(),
      perfilUsuario: user.perfil,
    );

    state.investments.add(investment);

    // Actualizar saldo del usuario
    user.saldo -= amount;
    final updatedUser = state.users[user.id]!;
    state.users[user.id] = updatedUser;

    // Actualizar proyecto
    project.totalInvertido += amount;
    project.numeroInversores += 1;
    state.projects[project.id] = project;

    // Actualizar sesión
    state.session.totalInvertido += amount;

    // Notificar a todos sobre la nueva inversión
    _broadcastInvestmentUpdate(investment);

    // Enviar confirmación al usuario
    _sendResponse(connection, 'invest', 'success', {
      'investment': investment.toJson(),
      'userBalance': updatedUser.saldo,
      'projectTotal': project.totalInvertido,
    });
  }

  void _sendSession(WebSocketConnection connection) {
    _sendResponse(connection, 'session', 'success', state.session.toJson());
  }

  void _sendRanking(WebSocketConnection connection) {
    final projects = state.projects.values.toList()
      ..sort((a, b) => b.totalInvertido.compareTo(a.totalInvertido));

    _sendResponse(connection, 'ranking', 'success', {
      'projects': projects.map((p) => p.toJson()).toList(),
      'totalInvested': state.session.totalInvertido,
    });
  }

  void _sendUsers(WebSocketConnection connection) {
    final users = state.users.values.map((u) => u.toJson()).toList();
    _sendResponse(connection, 'users', 'success', users);
  }

  void _sendUserInvestments(WebSocketConnection connection, Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final investments = state.investments
        .where((inv) => inv.usuarioId == userId)
        .map((inv) => inv.toJson())
        .toList();

    _sendResponse(connection, 'investments', 'success', investments);
  }

  void _handleStartRound(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    state.session.estado = 'active';
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_start_round', 'success', {});
  }

  void _handlePauseRound(WebSocketConnection connection) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    state.session.estado = 'paused';
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_pause_round', 'success', {});
  }

  void _handleEndRound(WebSocketConnection connection) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    state.session.estado = 'ended';
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_end_round', 'success', {});
  }

  void _handleSetDuration(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final minutes = (data['minutes'] as num?)?.toInt() ?? 30;
    state.session.tiempoTotal = Duration(minutes: minutes);
    state.session.tiempoRestante = Duration(minutes: minutes);
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_set_duration', 'success', {});
  }

  void _handleHeartbeat(WebSocketConnection connection) {
    connection.socket.add(json.encode({'type': 'pong'}));
  }

  void _sendResponse(WebSocketConnection connection, String type, String status, dynamic data) {
    connection.socket.add(json.encode({
      'type': type,
      'status': status,
      if (data != null) 'data': data,
    }));
  }

  void _sendError(WebSocketConnection connection, String message) {
    _sendResponse(connection, 'error', 'error', {'message': message});
  }

  void _broadcastInvestmentUpdate(Investment investment) {
    final message = json.encode({
      'type': 'investment_update',
      'status': 'success',
      'data': investment.toJson(),
    });

    for (final conn in state.connections.values) {
      conn.socket.add(message);
    }
  }

  void _broadcastSessionUpdate() {
    final message = json.encode({
      'type': 'session_update',
      'status': 'success',
      'data': state.session.toJson(),
    });

    for (final conn in state.connections.values) {
      conn.socket.add(message);
    }
  }

  void _handleResetRound(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    state.session.tiempoRestante = state.session.tiempoTotal;
    state.session.estado = 'waiting';
    state.session.totalInvertido = 0;
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_reset_round', 'success', {});
  }

  void _handleCreateUser(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final nombre = data['nombre'] as String?;
    final correo = data['correo'] as String?;
    final username = data['username'] as String?;
    final password = data['password'] as String?;
    final perfil = data['perfil'] as String?;
    final saldo = (data['saldo'] as num?)?.toDouble() ?? 1000000;
    final activo = data['activo'] as bool? ?? true;

    if (nombre == null || correo == null || username == null || password == null || perfil == null) {
      _sendError(connection, 'Faltan datos requeridos');
      return;
    }

    if (state.users.values.any((u) => u.username == username)) {
      _sendError(connection, 'El username ya existe');
      return;
    }

    final user = User(
      id: _generateId(),
      nombre: nombre,
      correo: correo,
      username: username,
      password: password,
      perfil: perfil,
      saldo: saldo,
      activo: activo,
      fechaRegistro: DateTime.now(),
    );

    state.users[user.id] = user;
    state.session.numeroParticipantes = state.users.length;
    _broadcastUsersUpdate();
    _sendResponse(connection, 'admin_create_user', 'success', user.toJson());
  }

  void _handleUpdateUser(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final id = data['id'] as String?;
    if (id == null) {
      _sendError(connection, 'ID de usuario requerido');
      return;
    }

    final user = state.users[id];
    if (user == null) {
      _sendError(connection, 'Usuario no encontrado');
      return;
    }

    if (data['nombre'] != null) user.nombre = data['nombre'];
    if (data['correo'] != null) user.correo = data['correo'];
    if (data['username'] != null) user.username = data['username'];
    if (data['password'] != null) user.password = data['password'];
    if (data['perfil'] != null) user.perfil = data['perfil'];
    if (data['saldo'] != null) user.saldo = (data['saldo'] as num).toDouble();
    if (data['activo'] != null) user.activo = data['activo'];

    _broadcastUsersUpdate();
    _sendResponse(connection, 'admin_update_user', 'success', user.toJson());
  }

  void _handleDeleteUser(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final userId = data['userId'] as String?;
    if (userId == null) {
      _sendError(connection, 'ID de usuario requerido');
      return;
    }

    // Verificar si tiene inversiones
    final hasInvestments = state.investments.any((inv) => inv.usuarioId == userId);
    if (hasInvestments) {
      // En lugar de eliminar, marcar como inactivo
      final user = state.users[userId];
      if (user != null) {
        user.activo = false;
        _broadcastUsersUpdate();
        _sendResponse(connection, 'admin_delete_user', 'success', {'message': 'Usuario desactivado por tener inversiones'});
      }
      return;
    }

    state.users.remove(userId);
    state.session.numeroParticipantes = state.users.length;
    _broadcastUsersUpdate();
    _sendResponse(connection, 'admin_delete_user', 'success', {'message': 'Usuario eliminado'});
  }

  void _handleCreateTheme(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final nombre = data['nombre'] as String?;
    final color = data['color'] as String?;
    final icono = data['icono'] as String?;
    final descripcion = data['descripcion'] as String? ?? '';
    final orden = (data['orden'] as num?)?.toInt() ?? 0;

    if (nombre == null || color == null || icono == null) {
      _sendError(connection, 'Faltan datos requeridos');
      return;
    }

    final theme = InvestmentTheme(
      id: _generateId(),
      nombre: nombre,
      descripcion: descripcion,
      color: color,
      icono: icono,
      orden: orden,
    );

    state.themes[theme.id] = theme;
    _broadcastThemesUpdate();
    _sendResponse(connection, 'admin_create_theme', 'success', theme.toJson());
  }

  void _handleUpdateTheme(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final id = data['id'] as String?;
    if (id == null) {
      _sendError(connection, 'ID de tema requerido');
      return;
    }

    final theme = state.themes[id];
    if (theme == null) {
      _sendError(connection, 'Tema no encontrado');
      return;
    }

    if (data['nombre'] != null) theme.nombre = data['nombre'];
    if (data['descripcion'] != null) theme.descripcion = data['descripcion'];
    if (data['color'] != null) theme.color = data['color'];
    if (data['icono'] != null) theme.icono = data['icono'];
    if (data['orden'] != null) theme.orden = (data['orden'] as num).toInt();

    _broadcastThemesUpdate();
    _sendResponse(connection, 'admin_update_theme', 'success', theme.toJson());
  }

  void _handleDeleteTheme(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final themeId = data['themeId'] as String?;
    if (themeId == null) {
      _sendError(connection, 'ID de tema requerido');
      return;
    }

    // Verificar si tiene proyectos
    final hasProjects = state.projects.values.any((p) => p.temaId == themeId);
    if (hasProjects) {
      _sendError(connection, 'No se puede eliminar el tema porque tiene proyectos asociados');
      return;
    }

    state.themes.remove(themeId);
    _broadcastThemesUpdate();
    _sendResponse(connection, 'admin_delete_theme', 'success', {'message': 'Tema eliminado'});
  }

  void _handleCreateProject(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final titulo = data['titulo'] as String?;
    final descripcion = data['descripcion'] as String?;
    final temaId = data['temaId'] as String?;
    final temaNombre = data['temaNombre'] as String?;
    final temaColor = data['temaColor'] as String?;
    final imagen = data['imagen'] as String? ?? '';
    final pitch = data['pitch'] as String? ?? '';
    final problema = data['problema'] as String? ?? '';
    final solucion = data['solucion'] as String? ?? '';
    final estrategiaIngresos = data['estrategiaIngresos'] as String? ?? '';
    final proyeccionFinanciera = data['proyeccionFinanciera'] as String? ?? '';
    final participantesData = data['participantes'] as List<dynamic>? ?? [];

    if (titulo == null || descripcion == null || temaId == null || temaNombre == null || temaColor == null) {
      _sendError(connection, 'Faltan datos requeridos');
      return;
    }

    final participantes = participantesData.map((p) {
      return Participant(
        nombre: p['nombre'] as String? ?? '',
        rol: p['rol'] as String? ?? '',
        foto: p['foto'] as String? ?? '',
      );
    }).toList();

    final project = Project(
      id: _generateId(),
      titulo: titulo,
      descripcion: descripcion,
      temaId: temaId,
      temaNombre: temaNombre,
      temaColor: temaColor,
      imagen: imagen,
      pitch: pitch,
      problema: problema,
      solucion: solucion,
      estrategiaIngresos: estrategiaIngresos,
      proyeccionFinanciera: proyeccionFinanciera,
      participantes: participantes,
    );

    state.projects[project.id] = project;
    state.session.numeroProyectos = state.projects.length;
    _broadcastProjectsUpdate();
    _sendResponse(connection, 'admin_create_project', 'success', project.toJson());
  }

  void _handleUpdateProject(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final id = data['id'] as String?;
    if (id == null) {
      _sendError(connection, 'ID de proyecto requerido');
      return;
    }

    final project = state.projects[id];
    if (project == null) {
      _sendError(connection, 'Proyecto no encontrado');
      return;
    }

    if (data['titulo'] != null) project.titulo = data['titulo'];
    if (data['descripcion'] != null) project.descripcion = data['descripcion'];
    if (data['imagen'] != null) project.imagen = data['imagen'];
    if (data['activo'] != null) project.activo = data['activo'];

    _broadcastProjectsUpdate();
    _sendResponse(connection, 'admin_update_project', 'success', project.toJson());
  }

  void _handleDeleteProject(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final projectId = data['projectId'] as String?;
    if (projectId == null) {
      _sendError(connection, 'ID de proyecto requerido');
      return;
    }

    // Verificar si tiene inversiones
    final projectInvestments = state.investments.where((inv) => inv.proyectoId == projectId);
    if (projectInvestments.isNotEmpty) {
      // En lugar de eliminar, marcar como inactivo
      final project = state.projects[projectId];
      if (project != null) {
        project.activo = false;
        _broadcastProjectsUpdate();
        _sendResponse(connection, 'admin_delete_project', 'success', {'message': 'Proyecto desactivado por tener inversiones'});
      }
      return;
    }

    state.projects.remove(projectId);
    state.session.numeroProyectos = state.projects.length;
    _broadcastProjectsUpdate();
    _sendResponse(connection, 'admin_delete_project', 'success', {'message': 'Proyecto eliminado'});
  }

  void _handleDeleteInvestment(WebSocketConnection connection, Map<String, dynamic> data) {
    if (connection.user?.isAdmin != true) {
      _sendError(connection, 'No autorizado');
      return;
    }

    final investmentId = data['investmentId'] as String?;
    if (investmentId == null) {
      _sendError(connection, 'ID de inversión requerido');
      return;
    }

    final investmentIndex = state.investments.indexWhere((inv) => inv.id == investmentId);
    if (investmentIndex == -1) {
      _sendError(connection, 'Inversión no encontrada');
      return;
    }

    final investment = state.investments[investmentIndex];

    // Reembolsar al usuario
    final user = state.users[investment.usuarioId];
    if (user != null) {
      user.saldo += investment.monto;
    }

    // Restar del proyecto
    final project = state.projects[investment.proyectoId];
    if (project != null) {
      project.totalInvertido -= investment.monto;
      project.numeroInversores -= 1;
    }

    // Actualizar sesión
    state.session.totalInvertido -= investment.monto;

    // Eliminar inversión
    state.investments.removeAt(investmentIndex);

    _broadcastInvestmentUpdate(investment); // Envía la actualización
    _broadcastUsersUpdate();
    _broadcastProjectsUpdate();
    _broadcastSessionUpdate();
    _sendResponse(connection, 'admin_delete_investment', 'success', {'message': 'Inversión eliminada'});
  }

  void _broadcastUsersUpdate() {
    final message = json.encode({
      'type': 'users_update',
      'status': 'success',
      'data': state.users.values.map((u) => u.toJson()).toList(),
    });

    for (final conn in state.connections.values) {
      conn.socket.add(message);
    }
  }

  void _broadcastThemesUpdate() {
    final themes = state.themes.values.map((t) {
      final themeProjects = state.projects.values.where((p) => p.temaId == t.id);
      return {
        'id': t.id,
        'nombre': t.nombre,
        'color': t.color,
        'icono': t.icono,
        'numeroProyectos': themeProjects.length,
        'totalInvertido': themeProjects.fold(0.0, (sum, p) => sum + p.totalInvertido),
      };
    }).toList();

    final message = json.encode({
      'type': 'themes_update',
      'status': 'success',
      'data': themes,
    });

    for (final conn in state.connections.values) {
      conn.socket.add(message);
    }
  }

  void _broadcastProjectsUpdate() {
    final message = json.encode({
      'type': 'projects_update',
      'status': 'success',
      'data': state.projects.values.map((p) => p.toJson()).toList(),
    });

    for (final conn in state.connections.values) {
      conn.socket.add(message);
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.roundActive && !state.roundPaused) {
        if (state.session.tiempoRestante > Duration.zero) {
          state.session.tiempoRestante -= const Duration(seconds: 1);
          _broadcastSessionUpdate();

          if (state.session.tiempoRestante <= Duration.zero) {
            state.session.estado = 'ended';
            _broadcastSessionUpdate();
            print('Ronda de inversión finalizada');
          }
        }
      }
    });
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _initializeMockData() {
    print('Inicializando datos de prueba...');

    // Crear temas
    state.themes['1'] = InvestmentTheme(
      id: '1',
      nombre: 'Tecnología',
      descripcion: 'Proyectos tecnológicos innovadores',
      color: '#00D4AA',
      icono: 'rocket_launch',
      orden: 1,
    );

    state.themes['2'] = InvestmentTheme(
      id: '2',
      nombre: 'Salud',
      descripcion: 'Proyectos de bienestar y salud',
      color: '#FF6B6B',
      icono: 'favorite',
      orden: 2,
    );

    state.themes['3'] = InvestmentTheme(
      id: '3',
      nombre: 'Educación',
      descripcion: 'Plataformas educativas',
      color: '#4ECDC4',
      icono: 'school',
      orden: 3,
    );

    state.themes['4'] = InvestmentTheme(
      id: '4',
      nombre: 'Sostenibilidad',
      descripcion: 'Proyectos eco-amigables',
      color: '#FFD93D',
      icono: 'eco',
      orden: 4,
    );

    // Crear admin
    state.users['admin'] = User(
      id: 'admin',
      nombre: 'Administrador',
      correo: 'admin@amerike.com',
      username: 'admin',
      password: 'admin123',
      perfil: 'Admin',
      saldo: 0,
      fechaRegistro: DateTime.now(),
    );

    // Crear usuarios de prueba
    state.users['1'] = User(
      id: '1',
      nombre: 'Juan Pérez',
      correo: 'juan@email.com',
      username: 'juanperez',
      password: 'password123',
      perfil: 'Alumno',
      saldo: 1000000,
      fechaRegistro: DateTime.now(),
    );

    state.users['2'] = User(
      id: '2',
      nombre: 'María García',
      correo: 'maria@email.com',
      username: 'mariagarcia',
      password: 'password123',
      perfil: 'Docente',
      saldo: 3000000,
      fechaRegistro: DateTime.now(),
    );

    state.users['3'] = User(
      id: '3',
      nombre: 'Carlos López',
      correo: 'carlos@email.com',
      username: 'carloslopez',
      password: 'password123',
      perfil: 'Inversionista',
      saldo: 10000000,
      fechaRegistro: DateTime.now(),
    );

    // Crear proyectos
    state.projects['p1'] = Project(
      id: 'p1',
      titulo: 'EcoTech Solutions',
      descripcion: 'Plataforma inteligente para gestión de residuos urbanos',
      temaId: '1',
      temaNombre: 'Tecnología',
      temaColor: '#00D4AA',
      pitch: 'Transformamos la gestión de residuos con IA y IoT',
      problema: 'Las ciudades pierden hasta 50% de residuos reciclables',
      solucion: 'Sensores inteligentes que identifican y separan residuos',
      estrategiaIngresos: 'SaaS B2B con suscripciones anuales y por volumen',
      proyeccionFinanciera: 'ARR de \$2M en año 2, ROI 18 meses',
      participantes: [
        Participant(nombre: 'Ana Martínez', rol: 'CEO'),
        Participant(nombre: 'Pedro Sánchez', rol: 'CTO'),
      ],
    );

    state.projects['p2'] = Project(
      id: 'p2',
      titulo: 'SaludMóvil',
      descripcion: 'App de telemedicina para comunidades rurales',
      temaId: '2',
      temaNombre: 'Salud',
      temaColor: '#FF6B6B',
      pitch: 'Salud accesible para todos, en cualquier lugar',
      problema: 'Acceso limitado a servicios médicos en áreas rurales',
      solucion: 'Plataforma que conecta pacientes con médicos especializados',
      estrategiaIngresos: 'Freemium con premium y servicios B2B a clínicas',
      proyeccionFinanciera: '1M usuarios en año 1, ingresos \$5M en año 3',
      participantes: [
        Participant(nombre: 'Laura Rodríguez', rol: 'Fundadora'),
      ],
    );

    state.projects['p3'] = Project(
      id: 'p3',
      titulo: 'EduSmart',
      descripcion: 'Plataforma de aprendizaje personalizado con IA',
      temaId: '3',
      temaNombre: 'Educación',
      temaColor: '#4ECDC4',
      pitch: 'Educación adaptativa para cada estudiante',
      problema: 'Métodos de enseñanza uniformes que ignoran diferencias individuales',
      solucion: 'Algoritmos de IA que crean rutas de aprendizaje personalizadas',
      estrategiaIngresos: 'Suscripciones para estudiantes y licencias B2B a escuelas',
      proyeccionFinanciera: '100 escuelas en año 1, 50,000 estudiantes en año 2',
      participantes: [
        Participant(nombre: 'Roberto Fernández', rol: 'Líder de Producto'),
        Participant(nombre: 'Sofía Hernández', rol: 'CTO'),
      ],
    );

    state.projects['p4'] = Project(
      id: 'p4',
      titulo: 'GreenPack',
      descripcion: 'Empaques biodegradables hechos de algas',
      temaId: '4',
      temaNombre: 'Sostenibilidad',
      temaColor: '#FFD93D',
      pitch: 'Empaques que se descomponen en 90 días, alimentando el suelo',
      problema: 'El plástico tarda 400 años en descomponerse',
      solucion: 'Tecnología patentada que convierte algas en empaques resistentes',
      estrategiaIngresos: 'Venta B2B a empresas de alimentos y comercio electrónico',
      proyeccionFinanciera: 'Clientes en 10 países en año 2, ingresos \$8M en año 3',
      participantes: [
        Participant(nombre: 'Carmen Díaz', rol: 'CEO'),
      ],
    );

    state.projects['p5'] = Project(
      id: 'p5',
      titulo: 'SmartFarm AI',
      descripcion: 'Sistema de agricultura de precisión con drones y sensores',
      temaId: '1',
      temaNombre: 'Tecnología',
      temaColor: '#00D4AA',
      pitch: 'Maximizar cosechas minimizando recursos',
      problema: 'Uso ineficiente de agua y fertilizantes en agricultura tradicional',
      solucion: 'Drones y sensores que aplican recursos exactamente donde se necesitan',
      estrategiaIngresos: 'Venta de hardware y suscripción de software de análisis',
      proyeccionFinanciera: '500 fincas en año 1, \$15M ingresos en año 3',
      participantes: [
        Participant(nombre: 'Miguel Torres', rol: 'CEO'),
        Participant(nombre: 'Isabela Ramos', rol: 'Directora Técnica'),
      ],
    );

    // Crear algunas inversiones iniciales
    state.investments.add(Investment(
      id: 'inv1',
      usuarioId: '2',
      usuarioNombre: 'María García',
      proyectoId: 'p1',
      proyectoNombre: 'EcoTech Solutions',
      monto: 200000,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 30)),
      perfilUsuario: 'Docente',
    ));

    state.investments.add(Investment(
      id: 'inv2',
      usuarioId: '3',
      usuarioNombre: 'Carlos López',
      proyectoId: 'p4',
      proyectoNombre: 'GreenPack',
      monto: 500000,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 25)),
      perfilUsuario: 'Inversionista',
    ));

    state.investments.add(Investment(
      id: 'inv3',
      usuarioId: '2',
      usuarioNombre: 'María García',
      proyectoId: 'p5',
      proyectoNombre: 'SmartFarm AI',
      monto: 150000,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 20)),
      perfilUsuario: 'Docente',
    ));

    state.investments.add(Investment(
      id: 'inv4',
      usuarioId: '1',
      usuarioNombre: 'Juan Pérez',
      proyectoId: 'p3',
      proyectoNombre: 'EduSmart',
      monto: 100000,
      fechaHora: DateTime.now().subtract(const Duration(minutes: 15)),
      perfilUsuario: 'Alumno',
    ));

    // Actualizar totales de proyectos
    for (final inv in state.investments) {
      final project = state.projects[inv.proyectoId];
      if (project != null) {
        project.totalInvertido += inv.monto;
        project.numeroInversores += 1;
      }
    }

    // Actualizar sesión
    state.session.totalInvertido = state.investments.fold(
      0.0,
      (sum, inv) => sum + inv.monto,
    );
    state.session.numeroProyectos = state.projects.length;
    state.session.numeroParticipantes = state.users.length;

    print('Datos de prueba inicializados: ${state.themes.length} temas, ${state.projects.length} proyectos, ${state.users.length} usuarios, ${state.investments.length} inversiones');
  }
}

void main() async {
  final server = AmerikeServer();
  await server.start();
}
