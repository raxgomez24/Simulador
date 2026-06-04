import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amerike_investment_sim/core/constants/app_colors.dart';
import 'package:amerike_investment_sim/domain/entities/investment.dart';
import 'package:amerike_investment_sim/domain/entities/user.dart';

// Diálogo para crear inversión manual
class CreateInvestmentDialog extends StatefulWidget {
  final List<User> users;
  final List<ProjectInfo> projects;

  const CreateInvestmentDialog({
    super.key,
    required this.users,
    required this.projects,
  });

  @override
  State<CreateInvestmentDialog> createState() => _CreateInvestmentDialogState();
}

class _CreateInvestmentDialogState extends State<CreateInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _observationsController = TextEditingController();

  User? _selectedUser;
  ProjectInfo? _selectedProject;

  @override
  void dispose() {
    _amountController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedUser != null && _selectedProject != null) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El monto debe ser mayor a 0')),
        );
        return;
      }

      Navigator.of(context).pop({
        'usuarioId': _selectedUser!.id,
        'usuarioNombre': _selectedUser!.nombre,
        'perfil': User.perfilToString(_selectedUser!.perfil),
        'proyectoId': _selectedProject!.id,
        'proyectoNombre': _selectedProject!.nombre,
        'temaId': _selectedProject!.temaId,
        'temaNombre': _selectedProject!.temaNombre,
        'temaColor': _selectedProject!.temaColor,
        'monto': amount,
        'observaciones': _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: const Text(
        'Crear Inversión Manual',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<User>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                dropdownColor: AppColors.secondaryBackground,
                items: widget.users.map((user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Text(
                      '${user.nombre} (${User.perfilToString(user.perfil)})',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (user) => setState(() => _selectedUser = user),
                validator: (value) => value == null ? 'Selecciona un usuario' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectInfo>(
                value: _selectedProject,
                decoration: const InputDecoration(
                  labelText: 'Proyecto',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                dropdownColor: AppColors.secondaryBackground,
                items: widget.projects.map((project) {
                  return DropdownMenuItem<ProjectInfo>(
                    value: project,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(project.temaColor.replaceFirst('#', '0xFF')),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.nombre,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (project) => setState(() => _selectedProject = project),
                validator: (value) => value == null ? 'Selecciona un proyecto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'El monto debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}

// Diálogo de confirmación para cancelar inversión
class CancelInvestmentDialog extends StatefulWidget {
  final Investment investment;

  const CancelInvestmentDialog({super.key, required this.investment});

  @override
  State<CancelInvestmentDialog> createState() => _CancelInvestmentDialogState();
}

class _CancelInvestmentDialogState extends State<CancelInvestmentDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_reasonController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: Row(
        children: [
          Icon(Icons.warning, color: AppColors.warning),
          const SizedBox(width: 8),
          const Text(
            'Cancelar Inversión',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuario: ${widget.investment.usuarioNombre}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Proyecto: ${widget.investment.proyectoNombre}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monto: ${_formatCurrency(widget.investment.monto)}',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El monto será reembolsado al saldo del usuario',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de cancelación',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El motivo es requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
          ),
          child: const Text('Confirmar Cancelación'),
        ),
      ],
    );
  }
}

// Diálogo de detalles de inversión
class InvestmentDetailsDialog extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailsDialog({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles de Inversión',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildSection(
                'Información del Usuario',
                [
                  _buildDetailRow('Nombre', investment.usuarioNombre),
                  _buildDetailRow('Perfil', User.perfilToString(investment.perfil)),
                  _buildDetailRow('ID', investment.usuarioId, isSmall: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Información del Proyecto',
                [
                  _buildDetailRow('Nombre', investment.proyectoNombre),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(investment.temaColor.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tema: ${investment.temaNombre}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  _buildDetailRow('ID', investment.proyectoId, isSmall: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Detalles de la Inversión',
                [
                  _buildDetailRow(
                    'Monto',
                    _formatCurrency(investment.monto),
                    isHighlighted: true,
                  ),
                  _buildDetailRow('Fecha', _formatDateTime(investment.fechaHora)),
                  _buildDetailRow('Hora', _formatTime(investment.fechaHora)),
                  Row(
                    children: [
                      const Text('Estado: ', style: TextStyle(color: AppColors.textSecondary)),
                      _buildStatusBadge(investment.estado),
                    ],
                  ),
                ],
              ),
              if (investment.observaciones != null && investment.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  'Observaciones',
                  [
                    Text(
                      investment.observaciones!,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
              if (investment.estado == InvestmentStatus.activa) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // The parent will handle showing the cancel dialog
                        },
                        icon: const Icon(Icons.cancel, color: AppColors.warning),
                        label: const Text('Cancelar Inversión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlighted ? AppColors.primaryAccent : AppColors.textPrimary,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmall ? 11 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvestmentStatus status) {
    Color color;
    switch (status) {
      case InvestmentStatus.activa:
        color = AppColors.success;
        break;
      case InvestmentStatus.cancelada:
        color = AppColors.error;
        break;
      case InvestmentStatus.pendiente:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

// Diálogo para editar inversión
class EditInvestmentDialog extends StatefulWidget {
  final Investment investment;
  final List<User> users;
  final List<ProjectInfo> projects;

  const EditInvestmentDialog({
    super.key,
    required this.investment,
    required this.users,
    required this.projects,
  });

  @override
  State<EditInvestmentDialog> createState() => _EditInvestmentDialogState();
}

class _EditInvestmentDialogState extends State<EditInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _observationsController = TextEditingController();

  User? _selectedUser;
  ProjectInfo? _selectedProject;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.investment.monto.toStringAsFixed(2);
    _observationsController.text = widget.investment.observaciones ?? '';

    // Find and set current user
    _selectedUser = widget.users.firstWhere(
      (u) => u.id == widget.investment.usuarioId,
      orElse: () => widget.users.isNotEmpty ? widget.users.first : throw Exception('No users'),
    );

    // Find and set current project
    _selectedProject = widget.projects.firstWhere(
      (p) => p.id == widget.investment.proyectoId,
      orElse: () => widget.projects.isNotEmpty ? widget.projects.first : throw Exception('No projects'),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedUser != null && _selectedProject != null) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El monto debe ser mayor a 0')),
        );
        return;
      }

      Navigator.of(context).pop({
        'id': widget.investment.id,
        'usuarioId': _selectedUser!.id,
        'usuarioNombre': _selectedUser!.nombre,
        'perfil': User.perfilToString(_selectedUser!.perfil),
        'proyectoId': _selectedProject!.id,
        'proyectoNombre': _selectedProject!.nombre,
        'temaId': _selectedProject!.temaId,
        'temaNombre': _selectedProject!.temaNombre,
        'temaColor': _selectedProject!.temaColor,
        'monto': amount,
        'observaciones': _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: const Text(
        'Editar Inversión',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current investment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Monto original: ${_formatCurrency(widget.investment.monto)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                dropdownColor: AppColors.secondaryBackground,
                items: widget.users.map((user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Text(
                      '${user.nombre} (${User.perfilToString(user.perfil)})',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (user) => setState(() => _selectedUser = user),
                validator: (value) => value == null ? 'Selecciona un usuario' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectInfo>(
                value: _selectedProject,
                decoration: const InputDecoration(
                  labelText: 'Proyecto',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                dropdownColor: AppColors.secondaryBackground,
                items: widget.projects.map((project) {
                  return DropdownMenuItem<ProjectInfo>(
                    value: project,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(project.temaColor.replaceFirst('#', '0xFF')),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.nombre,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (project) => setState(() => _selectedProject = project),
                validator: (value) => value == null ? 'Selecciona un proyecto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'El monto debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}

// Clase auxiliar para información de proyectos en el diálogo
class ProjectInfo {
  final String id;
  final String nombre;
  final String temaId;
  final String temaNombre;
  final String temaColor;

  ProjectInfo({
    required this.id,
    required this.nombre,
    required this.temaId,
    required this.temaNombre,
    required this.temaColor,
  });
}
