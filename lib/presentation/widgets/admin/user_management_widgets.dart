import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../providers/users_provider.dart';

/// Diálogo para crear o editar un usuario
class UserFormDialog extends ConsumerStatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole? _selectedPerfil;
  double? _saldo;
  bool _activo = true;
  bool _obscurePassword = true;

  final Map<UserRole, double> _initialBalances = {
    UserRole.admin: 0,
    UserRole.student: 1000000,
    UserRole.guest: 2000000,
    UserRole.teacher: 4000000,
    UserRole.employee: 6000000,
    UserRole.investor: 10000000,
  };

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _initializeWithUser(widget.user!);
    }
  }

  void _initializeWithUser(User user) {
    _nombreController.text = user.nombre;
    _correoController.text = user.correo ?? '';
    _usernameController.text = user.username;
    _selectedPerfil = user.perfil;
    _saldo = user.saldo;
    _activo = user.activo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPerfilChanged(UserRole? perfil) {
    setState(() {
      _selectedPerfil = perfil;
      if (widget.user == null && perfil != null) {
        _saldo = _initialBalances[perfil];
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final perfilStr = User.perfilToString(_selectedPerfil!);

    try {
      if (widget.user == null) {
        // Crear nuevo usuario
        await ref.read(userProvider.notifier).createUser(
              nombre: _nombreController.text.trim(),
              correo: _correoController.text.trim().isEmpty
                  ? null
                  : _correoController.text.trim(),
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              perfil: perfilStr,
              saldo: _saldo,
              activo: _activo,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Actualizar usuario existente
        await ref.read(userProvider.notifier).updateUser(
              id: widget.user!.id,
              nombre: _nombreController.text.trim(),
              correo: _correoController.text.trim().isEmpty
                  ? null
                  : _correoController.text.trim(),
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim().isEmpty
                  ? null
                  : _passwordController.text,
              perfil: perfilStr,
              saldo: _saldo,
              activo: _activo,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'Ej: juan@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Correo inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'Ej: juanperez',
                  prefixIcon: Icon(Icons.attribution),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El username es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Contraseña (dejar vacío para mantener)' : 'Contraseña *',
                  hintText: isEditing ? 'Nueva contraseña' : 'Ej: password123',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (!isEditing && (value == null || value.trim().isEmpty)) {
                    return 'La contraseña es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedPerfil,
                decoration: const InputDecoration(
                  labelText: 'Perfil *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: UserRole.values.map((perfil) {
                  return DropdownMenuItem(
                    value: perfil,
                    child: Text(User.perfilToString(perfil)),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'El perfil es requerido';
                  }
                  return null;
                },
                onChanged: _onPerfilChanged,
              ),
              if (_selectedPerfil != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryAccent.withOpacity( 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saldo inicial: \$${_initialBalances[_selectedPerfil]!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _saldo?.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo (opcional)',
                  hintText: 'Dejar vacío para usar monto inicial del perfil',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    setState(() {
                      _saldo = null;
                    });
                  } else {
                    final parsed = double.tryParse(value.trim());
                    if (parsed != null) {
                      setState(() {
                        _saldo = parsed;
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Usuario activo'),
                subtitle: const Text('Permite al usuario acceder al sistema'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value;
                  });
                },
                activeTrackColor: AppColors.primaryAccent.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Diálogo de confirmación para eliminar usuario
class DeleteUserDialog extends StatelessWidget {
  final User user;

  const DeleteUserDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: const Text('Eliminar Usuario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Estás seguro de que quieres eliminar este usuario?',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryAccent.withOpacity( 0.2),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withOpacity( 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta acción eliminará todas las inversiones y datos asociados al usuario.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

/// Diálogo de información de usuario
class UserInfoDialog extends StatelessWidget {
  final User user;

  const UserInfoDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con avatar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(51, 255, 107, 53),
                    Color.fromARGB(51, 100, 181, 246),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryAccent,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Información del usuario
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'Perfil',
                    value: User.perfilToString(user.perfil),
                  ),
                  const SizedBox(height: 12),
                  if (user.correo != null) ...[
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Correo',
                      value: user.correo!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(
                    icon: Icons.account_balance_wallet,
                    label: 'Saldo',
                    value: '\$${user.saldo.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: user.activo ? Icons.check_circle : Icons.cancel,
                    label: 'Estado',
                    value: user.activo ? 'Activo' : 'Inactivo',
                    valueColor: user.activo ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  if (user.fechaRegistro != null)
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Fecha de registro',
                      value: _formatDate(user.fechaRegistro!),
                    ),
                  const SizedBox(height: 24),
                  // Estadísticas (simuladas)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              label: 'Inversiones',
                              value: '0',
                              icon: Icons.trending_up,
                              color: AppColors.primaryAccent,
                            ),
                            _buildStatItem(
                              label: 'Total invertido',
                              value: '\$0',
                              icon: Icons.account_balance_wallet,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Botón cerrar
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Card para mostrar un usuario en la lista
class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getPerfilColor(user.perfil).withOpacity( 0.2),
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: _getPerfilColor(user.perfil),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Estado activo/inactivo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.activo
                                ? AppColors.success.withOpacity( 0.2)
                                : AppColors.error.withOpacity( 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.activo ? Icons.check_circle : Icons.cancel,
                                size: 12,
                                color: user.activo
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.activo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: user.activo
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.attribution,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.badge,
                          label: User.perfilToString(user.perfil),
                          color: _getPerfilColor(user.perfil),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: Icons.account_balance_wallet,
                          label: '\$${user.saldo.toStringAsFixed(0)}',
                          color: AppColors.primaryAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Botones de acción
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    color: AppColors.primaryAccent,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: AppColors.error,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerfilColor(UserRole perfil) {
    switch (perfil) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.student:
        return AppColors.primaryAccent;
      case UserRole.teacher:
        return AppColors.secondaryAccent;
      case UserRole.employee:
        return AppColors.success;
      case UserRole.investor:
        return AppColors.warning;
      case UserRole.guest:
        return AppColors.textSecondary;
    }
  }
}
