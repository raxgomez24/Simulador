import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_local.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../app/config.dart';
import 'admin_provider.dart';
import 'websocket_provider.dart';

final userProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(
  UsersNotifier.new,
);

class UsersNotifier extends AsyncNotifier<List<User>> {
  late UserRepository _userRepository;
  late AdminActions _adminActions;

  @override
  Future<List<User>> build() async {
    // En web, no usar repositorio local (no SQLite disponible)
    if (AppConfig.isWeb || !AppConfig.useLocalData) {
      final dataSource = ref.read(webSocketDataSourceProvider);
      _userRepository = UserRepositoryImpl(dataSource);
    } else {
      _userRepository = UserRepositoryLocal();
    }
    _adminActions = ref.read(adminActionsProvider);
    return await _userRepository.getAllUsers();
  }

  Future<void> refreshUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _userRepository.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Crear un nuevo usuario
  Future<void> createUser({
    required String nombre,
    String? correo,
    required String username,
    required String password,
    required String perfil,
    double? saldo,
    bool activo = true,
  }) async {
    try {
      // Verificar límite de usuarios antes de crear (100 usuarios máx)
      final currentUsers = await _userRepository.getAllUsers();
      if (currentUsers.length >= 100) {
        throw Exception('El sistema ha alcanzado el límite máximo de 100 usuarios. Contacta al administrador.');
      }

      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _userRepository.createUser(
          nombre: nombre,
          correo: correo,
          username: username,
          password: password,
          perfil: perfil,
          saldo: saldo,
          activo: activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.createUser(
          nombre: nombre,
          correo: correo ?? '',
          username: username,
          password: password,
          perfil: perfil,
          saldo: saldo ?? _getInitialBalance(perfil),
          activo: activo,
        );
      }
      // Recargar usuarios después de crear
      await refreshUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Actualizar un usuario existente
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
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _userRepository.updateUser(
          id: id,
          nombre: nombre,
          correo: correo,
          username: username,
          password: password,
          perfil: perfil,
          saldo: saldo,
          activo: activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.updateUser(
          id: id,
          nombre: nombre,
          correo: correo,
          username: username,
          password: password,
          perfil: perfil,
          saldo: saldo,
          activo: activo,
        );
      }
      // Recargar usuarios después de actualizar
      await refreshUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Eliminar un usuario
  Future<void> deleteUser(String userId) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _userRepository.deleteUser(userId);
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.deleteUser(userId);
      }
      // Recargar usuarios después de eliminar
      await refreshUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Obtener el saldo inicial basado en el perfil
  double _getInitialBalance(String perfil) {
    switch (perfil.toLowerCase()) {
      case 'admin':
        return 0; // Sin límite
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

  // Filtrar usuarios por búsqueda y perfil
  List<User> filterUsers({
    required List<User> users,
    String searchQuery = '',
    String? perfilFilter,
  }) {
    var filtered = users;

    // Filtrar por búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.nombre.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query) ||
            (user.correo?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtrar por perfil
    if (perfilFilter != null && perfilFilter.isNotEmpty) {
      filtered = filtered.where((user) {
        return User.perfilToString(user.perfil).toLowerCase() == perfilFilter.toLowerCase();
      }).toList();
    }

    return filtered;
  }
}

// Providers para filtros
final searchQueryProvider = StateProvider<String>((ref) => '');
final perfilFilterProvider = StateProvider<String?>((ref) => null);

// Provider para usuarios filtrados
final filteredUsersProvider = Provider<List<User>>((ref) {
  final usersAsync = ref.watch(userProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final perfilFilter = ref.watch(perfilFilterProvider);

  return usersAsync.when(
    data: (users) {
      final notifier = ref.read(userProvider.notifier);
      return notifier.filterUsers(
        users: users,
        searchQuery: searchQuery,
        perfilFilter: perfilFilter,
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
