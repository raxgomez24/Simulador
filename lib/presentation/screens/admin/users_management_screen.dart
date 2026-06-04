import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../providers/users_provider.dart';
import '../../widgets/admin/user_management_widgets.dart';

/// Pantalla completa de gestión de usuarios
class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UserFormDialog(),
    );
    if (result == true) {
      // Limpiar filtros después de crear
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(perfilFilterProvider.notifier).state = null;
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  Future<void> _showDeleteUserDialog(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteUserDialog(user: user),
    );

    if (confirmed == true) {
      try {
        await ref.read(userProvider.notifier).deleteUser(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar usuario: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showUserInfoDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserInfoDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final perfilFilter = ref.watch(perfilFilterProvider);

    return Column(
      children: [
        // Back button header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios),
                tooltip: 'Volver',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gestión de Usuarios',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // User limit indicator
              _buildUserLimitIndicator(usersAsync),
            ],
          ),
        ),
        // Barra de búsqueda y filtros
        _buildSearchAndFilters(searchQuery, perfilFilter),

        // Lista de usuarios
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(userProvider.notifier).refreshUsers();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
            data: (users) {
              if (users.isEmpty) {
                return _buildEmptyState();
              }

              if (filteredUsers.isEmpty) {
                return _buildNoResultsState(searchQuery, perfilFilter);
              }

              return _buildUsersList(filteredUsers);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(String searchQuery, String? perfilFilter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, username o correo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardBackground,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primaryAccent),
              ),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 12),
          // Filtro por perfil
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtrar por perfil:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: perfilFilter,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: AppColors.primaryAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los perfiles'),
                    ),
                    ...UserRole.values.map((perfil) {
                      return DropdownMenuItem(
                        value: User.perfilToString(perfil),
                        child: Text(User.perfilToString(perfil)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ref.read(perfilFilterProvider.notifier).state = value;
                  },
                ),
              ),
              if (perfilFilter != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(perfilFilterProvider.notifier).state = null;
                  },
                  tooltip: 'Limpiar filtro',
                ),
              ],
            ],
          ),
          // Contador de resultados
          if (searchQuery.isNotEmpty || perfilFilter != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${ref.watch(filteredUsersProvider).length} usuario(s) encontrado(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea el primer usuario para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Primer Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String searchQuery, String? perfilFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Intenta con otra búsqueda'
                : 'No hay usuarios con este perfil',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (searchQuery.isNotEmpty || perfilFilter != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(perfilFilterProvider.notifier).state = null;
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    final paginatedUsers = users.take(_currentPage * _itemsPerPage).toList();
    final hasMore = users.length > paginatedUsers.length;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: paginatedUsers.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == paginatedUsers.length) {
                // Indicador de carga para más usuarios
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final user = paginatedUsers[index];
              return UserCard(
                user: user,
                onTap: () => _showUserInfoDialog(user),
                onEdit: () => _showEditUserDialog(user),
                onDelete: () => _showDeleteUserDialog(user),
              );
            },
          ),
        ),
        // Botón flotante para crear usuario
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _showCreateUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Usuario'),
            backgroundColor: AppColors.primaryAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLimitIndicator(AsyncValue<List<User>> usersAsync) {
    return usersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (users) {
        final currentCount = users.length;
        final limit = 100;
        final percentage = currentCount / limit;
        final isNearLimit = percentage >= 0.9;
        final isOverLimit = percentage >= 1.0;

        Color getColor() {
          if (isOverLimit) return AppColors.error;
          if (isNearLimit) return AppColors.warning;
          return AppColors.success;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: getColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: getColor().withOpacity(0.5),
              width: isNearLimit || isOverLimit ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOverLimit
                    ? Icons.block
                    : isNearLimit
                        ? Icons.warning
                        : Icons.people,
                size: 16,
                color: getColor(),
              ),
              const SizedBox(width: 6),
              Text(
                '$currentCount/$limit',
                style: TextStyle(
                  color: getColor(),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
