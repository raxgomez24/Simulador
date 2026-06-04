import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/remote/websocket_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final WebSocketDataSource _dataSource;
  User? _currentUser;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<User> login(String username, String password) async {
    try {
      final completer = Completer<User>();

      final subscription = _dataSource.messageStream.listen((message) {
        print('Mensaje recibido en auth_repository: $message');

        if (message['type'] == ApiConstants.messageTypeAuth) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final userModel = UserModel.fromJson(message['data']);
            _currentUser = userModel.toEntity();
            completer.complete(_currentUser!);
          } else {
            // Manejo mejorado de errores
            String errorMessage = 'Error de autenticación';
            String? errorCode;

            if (message['error'] is Map) {
              errorMessage = message['error']['message'] ?? errorMessage;
              errorCode = message['error']['code'];
            } else if (message['error'] != null) {
              errorMessage = message['error'].toString();
            }

            if (message['errorCode'] != null) {
              errorCode = message['errorCode'];
            }

            completer.completeError(
              AuthenticationException(
                message: errorMessage,
                code: errorCode,
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeAuth,
        'action': 'login',
        'username': username,
        'password': password,
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
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<User> registerAsGuest(String username, String fullName) async {
    try {
      final completer = Completer<User>();

      final subscription = _dataSource.messageStream.listen((message) {
        print('Mensaje recibido en auth_repository (registro): $message');

        if (message['type'] == ApiConstants.messageTypeAuth) {
          if (message['status'] == ApiConstants.statusSuccess) {
            final userModel = UserModel.fromJson(message['data']);
            _currentUser = userModel.toEntity();
            completer.complete(_currentUser!);
          } else {
            // Manejo mejorado de errores
            String errorMessage = 'Error al registrar';
            String? errorCode;

            if (message['error'] is Map) {
              errorMessage = message['error']['message'] ?? errorMessage;
              errorCode = message['error']['code'];
            } else if (message['error'] != null) {
              errorMessage = message['error'].toString();
            }

            if (message['errorCode'] != null) {
              errorCode = message['errorCode'];
            }

            completer.completeError(
              AuthenticationException(
                message: errorMessage,
                code: errorCode,
              ),
            );
          }
        }
      });

      _dataSource.send({
        'type': ApiConstants.messageTypeAuth,
        'action': 'register_guest',
        'username': username,
        'nombre': fullName,
        'correo': '',
        'password': 'guest123',
        'perfil': 'Invitado',
        'saldo': 5000000,
        'activo': true,
        'fechaRegistro': DateTime.now().toIso8601String(),
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
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        message: e.toString(),
        code: ApiConstants.errorServer,
      );
    }
  }

  @override
  Future<void> logout() async {
    _dataSource.send({
      'type': ApiConstants.messageTypeAuth,
      'action': 'logout',
    });
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _currentUser != null && _dataSource.isConnected;
  }
}
