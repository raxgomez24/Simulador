import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/auth_repository_local.dart';
import '../../data/repositories/auth_repository_web.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import '../../app/config.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import 'websocket_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // En web, usar repositorio web con datos mock (sin SQLite)
  if (AppConfig.isWeb) {
    return AuthRepositoryWeb();
  } else if (AppConfig.useLocalData) {
    return AuthRepositoryLocal();
  } else {
    // Usar WebSocket para móvil/desktop cuando no useLocalData
    final dataSource = ref.read(webSocketDataSourceProvider);
    return AuthRepositoryImpl(dataSource);
  }
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  User? _currentUser;
  WebSocketDataSource? _dataSource;

  User? get currentUser => _currentUser;

  @override
  Future<User?> build() async {
    // En web, usar datos mock sin WebSocket
    if (AppConfig.isWeb) {
      print('Modo Web: usando datos mock sin WebSocket');
      return null;
    }
    // Solo conectar al servidor WebSocket si no estamos usando datos locales
    if (!AppConfig.useLocalData) {
      _dataSource = ref.read(webSocketDataSourceProvider);
      if (!_dataSource!.isConnected) {
        print('Conectando al servidor WebSocket...');
        try {
          await _dataSource!.connect(ApiConstants.defaultWebSocketUrl);
          print('Conectado al servidor WebSocket');
        } catch (e) {
          print('Error al conectar al servidor: $e');
          // No lanzar error, permitir reconexión automática
        }
      }
    } else {
      print('Usando datos locales, sin conexión WebSocket');
    }
    return null;
  }

  Future<void> login(String username, String password) async {
    print('Intentando login con: $username');
    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(loginUseCaseProvider);
      state = await AsyncValue.guard(() async {
        final user = await useCase(username, password);
        _currentUser = user;
        print('Login exitoso para usuario: ${user.nombre}');
        return user;
      });
    } catch (e) {
      print('Error en login: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> registerAsGuest(String username, String fullName) async {
    print('Intentando registro como invitado: $username, $fullName');
    state = const AsyncValue.loading();

    try {
      final useCase = ref.read(registerUseCaseProvider);
      state = await AsyncValue.guard(() async {
        final user = await useCase.callAsGuest(username, fullName);
        _currentUser = user;
        print('Registro exitoso para usuario: ${user.nombre}');
        return user;
      });
    } catch (e) {
      print('Error en registro: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    print('Cerrando sesión...');
    if (!AppConfig.useLocalData && _dataSource != null) {
      _dataSource!.send({
        'type': 'auth',
        'action': 'logout',
      });
    }
    _currentUser = null;
    state = const AsyncValue.data(null);
  }

  /// Actualiza el saldo del usuario (se usa después de una inversión)
  void updateBalance(double newBalance) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(saldo: newBalance);
      state = AsyncValue.data(_currentUser);
      print('Saldo actualizado: ${Formatters.formatCurrency(newBalance)}');
    }
  }

  /// Obtiene el saldo actual del usuario
  double get currentBalance => _currentUser?.saldo ?? 0;

  bool get isAuthenticated => _currentUser != null;
}
