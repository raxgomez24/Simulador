import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amerike_investment_sim/core/constants/app_colors.dart';
import 'package:amerike_investment_sim/core/services/export_service.dart';
import 'package:amerike_investment_sim/domain/entities/investment.dart';
import 'package:amerike_investment_sim/domain/entities/project.dart';
import 'package:amerike_investment_sim/domain/entities/user.dart';

class ExportOptionsDialog extends StatefulWidget {
  final List<Investment>? investments;
  final List<Project>? projects;
  final List<User>? users;

  const ExportOptionsDialog({
    super.key,
    this.investments,
    this.projects,
    this.users,
  });

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showDateFilter = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(
            Icons.file_download,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Exportar Reporte',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date filter section
            _buildDateFilterSection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Data export options
            const Text(
              'Seleccionar tipo de reporte',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (widget.investments != null && widget.investments!.isNotEmpty)
              _buildExportOption(
                context,
                icon: Icons.receipt_long,
                title: 'Inversiones',
                description: '${_filteredInvestments.length} registros de inversiones',
                color: AppColors.primaryAccent,
                onTap: () => _exportInvestments(context),
              ),

            if (widget.projects != null && widget.projects!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.business_center,
                title: 'Proyectos',
                description: 'Información detallada de ${widget.projects!.length} proyectos',
                color: AppColors.secondaryAccent,
                onTap: () => _exportProjects(context),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.emoji_events,
                title: 'Ranking de Proyectos',
                description: 'Ranking ordenado por monto invertido',
                color: AppColors.success,
                onTap: () => _exportRanking(context),
              ),
            ],

            if (widget.users != null && widget.users!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.people,
                title: 'Usuarios',
                description: 'Lista de ${widget.users!.length} usuarios',
                color: AppColors.info,
                onTap: () => _exportUsers(context),
              ),
            ],

            const SizedBox(height: 12),
            _buildExportOption(
              context,
              icon: Icons.analytics,
              title: 'Resumen Global',
              description: 'Métricas y estadísticas generales',
              color: AppColors.warning,
              onTap: () => _exportSummary(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.filter_list,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Filtro de fechas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Switch(
              value: _showDateFilter,
              onChanged: (value) {
                setState(() {
                  _showDateFilter = value;
                  if (!value) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
              activeTrackColor: AppColors.primaryAccent.withValues(alpha: 0.5),
              activeThumbColor: AppColors.primaryAccent,
            ),
          ],
        ),
        if (_showDateFilter) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Desde',
                  date: _startDate,
                  onTap: () => _selectStartDate(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: 'Hasta',
                  date: _endDate,
                  onTap: () => _selectEndDate(),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null ? AppColors.primaryAccent : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(8),
          color: date != null
              ? AppColors.primaryAccent.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: date != null ? AppColors.primaryAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? AppColors.primaryAccent : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: _startDate ?? DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  List<Investment> get _filteredInvestments {
    if (widget.investments == null) return [];

    var filtered = List<Investment>.from(widget.investments!);

    if (_startDate != null) {
      filtered = filtered.where((inv) =>
        inv.fechaHora.isAfter(_startDate!) ||
        inv.fechaHora.isAtSameMomentAs(_startDate!)
      ).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((inv) =>
        inv.fechaHora.isBefore(endOfDay) ||
        inv.fechaHora.isAtSameMomentAs(endOfDay)
      ).toList();
    }

    return filtered;
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildExportButton(
                color: color,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_download, size: 16),
          SizedBox(width: 6),
          Text('CSV', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _exportInvestments(BuildContext context) async {
    Navigator.of(context).pop();
    final filtered = _filteredInvestments;

    if (filtered.isEmpty) {
      _showErrorSnackBar(context, 'No hay inversiones en el rango de fechas seleccionado');
      return;
    }

    final csv = ExportService.exportInvestmentsToCSV(filtered);
    await Clipboard.setData(ClipboardData(text: csv));

    if (context.mounted) {
      _showSuccessSnackBar(
        context,
        'CSV de inversiones copiado',
        '${filtered.length} registros',
        AppColors.primaryAccent,
      );
    }
  }

  void _exportProjects(BuildContext context) async {
    if (widget.projects == null || widget.projects!.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    final csv = ExportService.exportProjectsToCSV(widget.projects!);
    await Clipboard.setData(ClipboardData(text: csv));

    if (context.mounted) {
      _showSuccessSnackBar(
        context,
        'CSV de proyectos copiado',
        '${widget.projects!.length} registros',
        AppColors.secondaryAccent,
      );
    }
  }

  void _exportRanking(BuildContext context) async {
    if (widget.projects == null || widget.projects!.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();

    // Create ranking from projects
    final rankedProjects = List<MapEntry<String, double>>.from(
      widget.projects!
          .where((p) => p.totalInvertido > 0)
          .map((p) => MapEntry(p.nombre, p.totalInvertido))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    if (rankedProjects.isEmpty) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'No hay proyectos con inversiones');
      }
      return;
    }

    final csv = ExportService.exportRankingToCSV(rankedProjects);
    await Clipboard.setData(ClipboardData(text: csv));

    if (context.mounted) {
      _showSuccessSnackBar(
        context,
        'CSV de ranking copiado',
        '${rankedProjects.length} proyectos',
        AppColors.success,
      );
    }
  }

  void _exportUsers(BuildContext context) async {
    if (widget.users == null || widget.users!.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    final csv = ExportService.exportUsersToCSV(widget.users!);
    await Clipboard.setData(ClipboardData(text: csv));

    if (context.mounted) {
      _showSuccessSnackBar(
        context,
        'CSV de usuarios copiado',
        '${widget.users!.length} registros',
        AppColors.info,
      );
    }
  }

  void _exportSummary(BuildContext context) async {
    Navigator.of(context).pop();

    final summary = ExportService.generateSummaryData(
      investments: widget.investments,
      projects: widget.projects,
      users: widget.users,
    );

    // Convert summary to CSV format
    final buffer = StringBuffer();
    buffer.writeln('Métrica,Valor');

    if (summary.containsKey('inversiones')) {
      final inv = summary['inversiones'] as Map<String, dynamic>;
      buffer.writeln('Total Inversiones,${inv['total']}');
      buffer.writeln('Monto Total,\$${(inv['monto_total'] as num).toStringAsFixed(2)}');
      buffer.writeln('Usuarios Únicos,${inv['usuarios_unicos']}');
      buffer.writeln('Proyectos Únicos,${inv['proyectos_unicos']}');
      buffer.writeln('Promedio por Inversión,\$${(inv['promedio_por_inversion'] as num).toStringAsFixed(2)}');
      buffer.writeln();
      buffer.writeln('Inversiones por Tema,Count');
      (inv['por_tema'] as Map<String, int>).forEach((theme, count) {
        buffer.writeln('$theme,$count');
      });
    }

    if (summary.containsKey('proyectos')) {
      buffer.writeln();
      final proj = summary['proyectos'] as Map<String, dynamic>;
      buffer.writeln('Total Proyectos,${proj['total']}');
      buffer.writeln('Proyectos Activos,${proj['activos']}');
      buffer.writeln('Proyectos Inactivos,${proj['inactivos']}');
      buffer.writeln('Recaudado Total,\$${(proj['recaudado_total'] as num).toStringAsFixed(2)}');
      buffer.writeln('Inversores Totales,${proj['inversores_totales']}');
      buffer.writeln('Promedio por Proyecto,\$${(proj['promedio_invertido_por_proyecto'] as num).toStringAsFixed(2)}');
    }

    if (summary.containsKey('usuarios')) {
      buffer.writeln();
      final usr = summary['usuarios'] as Map<String, dynamic>;
      buffer.writeln('Total Usuarios,${usr['total']}');
      buffer.writeln('Usuarios Activos,${usr['activos']}');
      buffer.writeln('Usuarios Inactivos,${usr['inactivos']}');
      buffer.writeln('Saldo Total,\$${(usr['saldo_total'] as num).toStringAsFixed(2)}');
      buffer.writeln('Saldo Promedio,\$${(usr['saldo_promedio'] as num).toStringAsFixed(2)}');
      buffer.writeln();
      buffer.writeln('Usuarios por Perfil,Count');
      (usr['por_perfil'] as Map<String, int>).forEach((perfil, count) {
        buffer.writeln('$perfil,$count');
      });
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (context.mounted) {
      _showSuccessSnackBar(
        context,
        'CSV de resumen global copiado',
        'Métricas consolidadas',
        AppColors.warning,
      );
    }
  }

  void _showSuccessSnackBar(
    BuildContext context,
    String message,
    String detail,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
