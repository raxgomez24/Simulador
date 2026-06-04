import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile.dart';

class ProfileEditDialog extends StatefulWidget {
  final Profile profile;

  const ProfileEditDialog({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController _displayNameController;
  late TextEditingController _balanceController;
  late TextEditingController _descriptionController;
  late bool _canCreate;
  late bool _canEdit;
  late bool _canDelete;
  late bool _canInvest;
  late bool _isActive;
  late String _selectedColor;

  final List<String> _availableColors = [
    '#EF4444', // Red
    '#00D4AA', // Teal
    '#007AFF', // Blue
    '#FFB800', // Yellow
    '#A78BFA', // Purple
    '#10B981', // Green
    '#F59E0B', // Orange
    '#EC4899', // Pink
    '#6366F1', // Indigo
    '#14B8A6', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _balanceController = TextEditingController(
      text: widget.profile.initialBalance.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.profile.description ?? '',
    );
    _canCreate = widget.profile.canCreate;
    _canEdit = widget.profile.canEdit;
    _canDelete = widget.profile.canDelete;
    _canInvest = widget.profile.canInvest;
    _isActive = widget.profile.isActive;
    _selectedColor = widget.profile.color;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(_selectedColor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getProfileIcon(widget.profile.id),
                        color: _parseColor(_selectedColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Editar Perfil',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Name (read-only for system profiles)
                TextField(
                  controller: _displayNameController,
                  readOnly: widget.profile.isSystemProfile,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.profile.isSystemProfile
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Perfil',
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.5)),
                    ),
                    suffixIcon: widget.profile.isSystemProfile
                        ? const Icon(Icons.lock, color: AppColors.textSecondary, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Initial Balance
                TextField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Saldo Inicial',
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixText: '\$',
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    helperText: 'Cantidad de dinero inicial para este perfil',
                    helperStyle: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Permissions Section
                Text(
                  'Permisos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPermissionCheckbox('Puede Crear', _canCreate, (value) {
                  setState(() => _canCreate = value ?? false);
                }),
                _buildPermissionCheckbox('Puede Editar', _canEdit, (value) {
                  setState(() => _canEdit = value ?? false);
                }),
                _buildPermissionCheckbox('Puede Eliminar', _canDelete, (value) {
                  setState(() => _canDelete = value ?? false);
                }),
                _buildPermissionCheckbox('Puede Invertir', _canInvest, (value) {
                  setState(() => _canInvest = value ?? false);
                }),
                const SizedBox(height: 24),

                // Active Status
                SwitchListTile(
                  title: Text(
                    'Perfil Activo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Los usuarios con este perfil pueden acceder al sistema',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Color Selection
                Text(
                  'Color del Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _parseColor(color),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Descripción opcional del perfil...',
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _validateAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _parseColor(_selectedColor),
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: _parseColor(_selectedColor),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _validateAndSave() {
    // Validate balance
    final balance = double.tryParse(_balanceController.text);
    if (balance == null || balance < 0) {
      _showError('El saldo inicial debe ser un número válido mayor o igual a 0');
      return;
    }

    // Validate at least one permission
    if (!_canCreate && !_canEdit && !_canDelete && !_canInvest) {
      _showError('El perfil debe tener al menos un permiso activo');
      return;
    }

    // Create updated profile
    final updatedProfile = widget.profile.copyWith(
      displayName: _displayNameController.text.trim(),
      initialBalance: balance,
      canCreate: _canCreate,
      canEdit: _canEdit,
      canDelete: _canDelete,
      canInvest: _canInvest,
      isActive: _isActive,
      color: _selectedColor,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    Navigator.pop(context, updatedProfile);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final colorCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$colorCode', radix: 16));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }

  IconData _getProfileIcon(String profileId) {
    switch (profileId) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'student':
        return Icons.school;
      case 'teacher':
        return Icons.person;
      case 'employee':
        return Icons.work;
      case 'guest':
        return Icons.card_giftcard;
      case 'investor':
        return Icons.trending_up;
      default:
        return Icons.person;
    }
  }
}
