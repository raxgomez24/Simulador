import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/themes_provider.dart';

class ThemeFormDialog extends ConsumerStatefulWidget {
  final InvestmentTheme? theme;

  const ThemeFormDialog({
    super.key,
    this.theme,
  });

  @override
  ConsumerState<ThemeFormDialog> createState() => _ThemeFormDialogState();
}

class _ThemeFormDialogState extends ConsumerState<ThemeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _ordenController;
  String _selectedColor = predefinedColors.first;
  String _selectedIcon = predefinedIcons.values.first.first;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.theme?.nombre ?? '');
    _descripcionController =
        TextEditingController(text: widget.theme?.descripcion ?? '');
    _ordenController = TextEditingController(
      text: widget.theme?.orden.toString() ??
          (ref.read(themesManagementProvider).maybeWhen(
                data: (themes) => (themes.length + 1).toString(),
                orElse: () => '1',
              )),
    );
    _selectedColor = widget.theme?.color ?? predefinedColors.first;
    _selectedIcon = widget.theme?.icon ?? predefinedIcons.values.first.first;
    _isActive = widget.theme?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  Future<void> _saveTheme() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      final orden = int.tryParse(_ordenController.text) ?? 0;

      if (widget.theme == null) {
        // Crear nuevo tema
        await ref.read(themesManagementProvider.notifier).createTheme(
              nombre: nombre,
              descripcion: descripcion,
              color: _selectedColor,
              icon: _selectedIcon,
              orden: orden,
              activo: _isActive,
            );
      } else {
        // Actualizar tema existente
        await ref.read(themesManagementProvider.notifier).updateTheme(
              id: widget.theme!.id,
              nombre: nombre,
              descripcion: descripcion,
              color: _selectedColor,
              icon: _selectedIcon,
              orden: orden,
              activo: _isActive,
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.theme == null
                  ? 'Tema creado exitosamente'
                  : 'Tema actualizado exitosamente',
            ),
            backgroundColor: AppColors.success,
          ),
        );
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
    final themeName = widget.theme == null ? 'Crear Tema' : 'Editar Tema';

    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                Text(
                  themeName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del tema *',
                            hintText: 'Ej: Tecnología',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryAccent),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es requerido';
                            }
                            if (value.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo descripción
                        TextField(
                          controller: _descripcionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            hintText: 'Describe el tema...',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryAccent),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),

                        // Selector de color
                        const Text(
                          'Color del tema',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildColorSelector(),
                        const SizedBox(height: 16),

                        // Selector de icono
                        const Text(
                          'Icono del tema',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildIconSelector(),
                        const SizedBox(height: 16),

                        // Campo orden
                        TextFormField(
                          controller: _ordenController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Orden',
                            hintText: '0',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primaryAccent),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final orden = int.tryParse(value);
                            if (orden == null || orden < 0) {
                              return 'El orden debe ser un número positivo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Switch activo
                        Row(
                          children: [
                            const Text(
                              'Tema activo',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Preview del tema
                        _buildThemePreview(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTheme,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
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

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: predefinedColors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: predefinedIcons.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _hexToColor(_selectedColor).withOpacity(0.3)
                          : AppColors.tertiaryBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? _hexToColor(_selectedColor)
                            : AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildThemePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hexToColor(_selectedColor),
          width: 3,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _hexToColor(_selectedColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _selectedIcon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreController.text.isEmpty ? 'Nombre del tema' : _nombreController.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_descripcionController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _descripcionController.text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isActive ? Icons.check_circle : Icons.cancel,
                      color: _isActive ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: _isActive ? AppColors.success : AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
