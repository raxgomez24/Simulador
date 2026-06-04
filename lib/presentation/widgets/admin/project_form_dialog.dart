import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/projects_management_provider.dart';
import '../../providers/themes_provider.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  final Project? project;

  const ProjectFormDialog({
    super.key,
    this.project,
  });

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _imagenController;
  late TextEditingController _pitchController;
  late TextEditingController _problemaController;
  late TextEditingController _solucionController;
  late TextEditingController _estrategiaIngresosController;
  late TextEditingController _proyeccionFinancieraController;
  late TextEditingController _ordenController;

  String _selectedTemaId = '';
  bool _isActive = true;
  int _currentStep = 0;
  List<Map<String, String>> _participantes = [];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.project?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.project?.descripcion ?? '');
    _imagenController = TextEditingController(text: widget.project?.imagen ?? '');
    _pitchController = TextEditingController(text: widget.project?.pitch ?? '');
    _problemaController = TextEditingController(text: widget.project?.problema ?? '');
    _solucionController = TextEditingController(text: widget.project?.solucion ?? '');
    _estrategiaIngresosController = TextEditingController(text: widget.project?.estrategiaIngresos ?? '');
    _proyeccionFinancieraController = TextEditingController(text: widget.project?.proyeccionFinanciera ?? '');
    _ordenController = TextEditingController(text: widget.project?.orden?.toString() ?? '0');
    _isActive = widget.project?.activo ?? true;
    _selectedTemaId = widget.project?.temaId ?? '';
    _participantes = widget.project?.participantes ?? [];
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _imagenController.dispose();
    _pitchController.dispose();
    _problemaController.dispose();
    _solucionController.dispose();
    _estrategiaIngresosController.dispose();
    _proyeccionFinancieraController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    return _formKeys[_currentStep].currentState?.validate() ?? false;
  }

  Future<void> _saveProject() async {
    if (!_validateCurrentStep()) return;

    try {
      final tema = ref.read(themesManagementProvider).maybeWhen(
            data: (themes) => themes.firstWhere(
              (t) => t.id == _selectedTemaId,
              orElse: () => themes.first,
            ),
            orElse: () => throw Exception('No hay temas disponibles'),
          );

      if (widget.project == null) {
        // Crear nuevo proyecto
        await ref.read(projectsManagementProvider.notifier).createProject(
              titulo: _tituloController.text.trim(),
              descripcion: _descripcionController.text.trim(),
              temaId: tema.id,
              temaNombre: tema.nombre,
              temaColor: tema.color,
              imagen: _imagenController.text.trim(),
              pitch: _pitchController.text.trim(),
              problema: _problemaController.text.trim(),
              solucion: _solucionController.text.trim(),
              estrategiaIngresos: _estrategiaIngresosController.text.trim(),
              proyeccionFinanciera: _proyeccionFinancieraController.text.trim(),
              participantes: _participantes,
              orden: int.tryParse(_ordenController.text) ?? 0,
              activo: _isActive,
            );
      } else {
        // Actualizar proyecto existente
        await ref.read(projectsManagementProvider.notifier).updateProject(
              id: widget.project!.id,
              titulo: _tituloController.text.trim(),
              descripcion: _descripcionController.text.trim(),
              imagen: _imagenController.text.trim(),
              activo: _isActive,
              pitch: _pitchController.text.trim(),
              problema: _problemaController.text.trim(),
              solucion: _solucionController.text.trim(),
              estrategiaIngresos: _estrategiaIngresosController.text.trim(),
              proyeccionFinanciera: _proyeccionFinancieraController.text.trim(),
              participantes: _participantes,
              orden: int.tryParse(_ordenController.text) ?? 0,
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.project == null
                  ? 'Proyecto creado exitosamente'
                  : 'Proyecto actualizado exitosamente',
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

  void _addParticipante() {
    setState(() {
      _participantes.add({
        'nombre': '',
        'rol': 'Otro',
        'foto': '',
      });
    });
  }

  void _removeParticipante(int index) {
    setState(() {
      _participantes.removeAt(index);
    });
  }

  void _updateParticipante(int index, String key, String value) {
    setState(() {
      _participantes[index][key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                widget.project == null ? 'Crear Proyecto' : 'Editar Proyecto',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Stepper
              _buildStepper(),
              const SizedBox(height: 16),

              // Contenido del paso actual
              Expanded(
                child: _buildStepContent(),
              ),

              const SizedBox(height: 24),

              // Botones de navegación
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryAccent
                        : isCompleted
                            ? AppColors.success
                            : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 3) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Campo título
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título del proyecto *',
                hintText: 'Ej: Innovación en Energía Solar',
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
                  return 'El título es requerido';
                }
                if (value.trim().length < 3) {
                  return 'El título debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo descripción
            TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Descripción breve *',
                hintText: 'Describe el proyecto en máximo 200 caracteres...',
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
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo imagen
            TextFormField(
              controller: _imagenController,
              decoration: const InputDecoration(
                labelText: 'URL de imagen (opcional)',
                hintText: 'https://ejemplo.com/imagen.jpg',
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

            // Dropdown de temas
            const Text(
              'Tema del proyecto *',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ref.watch(themesManagementProvider).maybeWhen(
              data: (themes) => DropdownButtonFormField<String>(
                initialValue: _selectedTemaId.isEmpty ? null : _selectedTemaId,
                decoration: InputDecoration(
                  hintText: 'Selecciona un tema',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.tertiaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppColors.tertiaryBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                items: themes
                    .where((t) => t.activo)
                    .map((theme) {
                  return DropdownMenuItem(
                    value: theme.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _hexToColor(theme.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(theme.nombre),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTemaId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona un tema';
                  }
                  return null;
                },
              ),
              orElse: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Proyecto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildMultilineField(
              controller: _pitchController,
              label: 'Pitch',
              hint: 'Elevator pitch del proyecto...',
            ),
            const SizedBox(height: 16),

            _buildMultilineField(
              controller: _problemaController,
              label: 'Problema',
              hint: '¿Qué problema resuelve el proyecto?...',
            ),
            const SizedBox(height: 16),

            _buildMultilineField(
              controller: _solucionController,
              label: 'Solución',
              hint: '¿Cómo resuelve el problema?...',
            ),
            const SizedBox(height: 16),

            _buildMultilineField(
              controller: _estrategiaIngresosController,
              label: 'Estrategia de Ingresos',
              hint: '¿Cómo generará ingresos?...',
            ),
            const SizedBox(height: 16),

            _buildMultilineField(
              controller: _proyeccionFinancieraController,
              label: 'Proyección Financiera',
              hint: 'Proyecciones financieras del proyecto...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participantes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addParticipante,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_participantes.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No hay participantes agregados',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participantes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final participante = _participantes[index];
                  return _buildParticipanteCard(index, participante);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipanteCard(int index, Map<String, String> participante) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participante ${index + 1}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _removeParticipante(index),
                icon: const Icon(Icons.close, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            initialValue: participante['nombre'],
            decoration: const InputDecoration(
              labelText: 'Nombre',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (value) => _updateParticipante(index, 'nombre', value),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: participante['rol'] == '' ? 'Otro' : participante['rol'],
            decoration: const InputDecoration(
              labelText: 'Rol',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: AppColors.secondaryBackground,
            style: const TextStyle(color: AppColors.textPrimary),
            items: const [
              DropdownMenuItem(value: 'CEO', child: Text('CEO')),
              DropdownMenuItem(value: 'CTO', child: Text('CTO')),
              DropdownMenuItem(value: 'COO', child: Text('COO')),
              DropdownMenuItem(value: 'CFO', child: Text('CFO')),
              DropdownMenuItem(value: 'CMO', child: Text('CMO')),
              DropdownMenuItem(value: 'Líder de Producto', child: Text('Líder de Producto')),
              DropdownMenuItem(value: 'Desarrollador', child: Text('Desarrollador')),
              DropdownMenuItem(value: 'Diseñador', child: Text('Diseñador')),
              DropdownMenuItem(value: 'Asesor', child: Text('Asesor')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateParticipante(index, 'rol', value);
              }
            },
          ),
          const SizedBox(height: 8),

          TextFormField(
            initialValue: participante['foto'],
            decoration: const InputDecoration(
              labelText: 'URL de foto (opcional)',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (value) => _updateParticipante(index, 'foto', value),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Form(
      key: _formKeys[3],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Switch activo
            Row(
              children: [
                const Text(
                  'Proyecto activo',
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
                  activeThumbColor: AppColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo orden
            TextFormField(
              controller: _ordenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Orden de visualización',
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
            const SizedBox(height: 24),

            // Preview completo
            const Text(
              'Vista Previa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProjectPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectPreview() {
    final tema = ref.read(themesManagementProvider).maybeWhen(
          data: (themes) => themes.firstWhere(
            (t) => t.id == _selectedTemaId,
            orElse: () => themes.isNotEmpty ? themes.first : InvestmentTheme.empty(),
          ),
          orElse: () => InvestmentTheme.empty(),
        );
    final temaColor = _hexToColor(tema.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: temaColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: temaColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.business_center,
                    color: temaColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tituloController.text.isEmpty ? 'Título del proyecto' : _tituloController.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: temaColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tema.nombre,
                          style: TextStyle(
                            color: temaColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_descripcionController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
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
          if (_participantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _participantes.take(5).map((participante) {
                final nombre = participante['nombre'] ?? '';
                final iniciales = nombre.isNotEmpty
                    ? nombre.split(' ').map((n) => n[0]).take(2).join()
                    : '?';
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: temaColor.withValues(alpha: 0.3),
                  child: Text(
                    iniciales,
                    style: TextStyle(
                      color: temaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.tertiaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Anterior',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
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
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentStep == 3 ? _saveProject : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _currentStep == 3 ? 'Guardar' : 'Siguiente',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
