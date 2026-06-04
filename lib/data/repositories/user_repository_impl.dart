import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/websocket_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final WebSocketDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<User> getUserById(String id) async {
    final completer = Completer<User>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'user_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && data['id'] == id) {
          completer.complete(UserModel.fromJson(data).toEntity());
        }
      }
    });

    _dataSource.send({
      'type': 'get_user',
      'data': {'userId': id},
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<User> updateBalance(String userId, double newBalance) async {
    final completer = Completer<User>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'user_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && data['id'] == userId) {
          completer.complete(UserModel.fromJson(data).toEntity());
        }
      }
    });

    _dataSource.send({
      'type': 'admin_update_user',
      'data': {
        'id': userId,
        'saldo': newBalance,
      },
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<List<User>> getAllUsers() async {
    final completer = Completer<List<User>>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'users_response') {
        final data = message['data'] as List<dynamic>?;
        if (data != null) {
          completer.complete(
            data.map((u) => UserModel.fromJson(u).toEntity()).toList(),
          );
        }
      }
    });

    _dataSource.send({
      'type': 'users',
      'data': {},
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<List<User>> getRanking() async {
    final completer = Completer<List<User>>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'ranking_response') {
        final data = message['data'] as List<dynamic>?;
        if (data != null) {
          completer.complete(
            data.map((u) => UserModel.fromJson(u).toEntity()).toList(),
          );
        }
      }
    });

    _dataSource.send({
      'type': 'ranking',
      'data': {},
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<User> createUser({
    required String nombre,
    String? correo,
    required String username,
    required String password,
    required String perfil,
    double? saldo,
    bool activo = true,
  }) async {
    final completer = Completer<User>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'user_created' || message['type'] == 'user_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          completer.complete(UserModel.fromJson(data).toEntity());
        }
      }
    });

    _dataSource.send({
      'type': 'admin_create_user',
      'data': {
        'nombre': nombre,
        'correo': correo ?? '',
        'username': username,
        'password': password,
        'perfil': perfil,
        'saldo': saldo ?? _getInitialBalance(perfil),
        'activo': activo,
      },
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<User> updateUser({
    required String id,
    String? nombre,
    String? correo,
    String? username,
    String? password,
    String? perfil,
    double? saldo,
    bool? activo,
  }) async {
    final completer = Completer<User>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'user_updated' || message['type'] == 'user_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && data['id'] == id) {
          completer.complete(UserModel.fromJson(data).toEntity());
        }
      }
    });

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

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  @override
  Future<bool> deleteUser(String id) async {
    final completer = Completer<bool>();
    final subscription = _dataSource.messageStream.listen((message) {
      if (message['type'] == 'user_deleted') {
        completer.complete(true);
      }
    });

    _dataSource.send({
      'type': 'admin_delete_user',
      'data': {'userId': id},
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    subscription.cancel();
    return result;
  }

  // Get initial balance based on profile
  double _getInitialBalance(String perfil) {
    switch (perfil.toLowerCase()) {
      case 'admin':
        return 0;
      case 'alumno':
      case 'student':
        return 1000000;
      case 'docente':
      case 'teacher':
        return 4000000;
      case 'administrativo':
      case 'employee':
        return 6000000;
      case 'inversionista':
      case 'investor':
        return 10000000;
      case 'invitado':
      case 'guest':
        return 2000000;
      default:
        return 1000000;
    }
  }
}
