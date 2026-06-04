import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/project.dart';

class ProjectInfoDialog extends ConsumerStatefulWidget {
  final Project project;

  const ProjectInfoDialog({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<ProjectInfoDialog> createState() => _ProjectInfoDialogState();
}

class _ProjectInfoDialogState extends ConsumerState<ProjectInfoDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temaColor = _hexToColor(widget.project.temaColor ?? '#00D4AA');

    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con imagen
            _buildHeader(temaColor),

            // Tab bar
            Container(
              color: AppColors.secondaryBackground,
              child: TabBar(
                controller: _tabController,
                indicatorColor: temaColor,
                labelColor: temaColor,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Información'),
                  Tab(text: 'Detalles'),
                  Tab(text: 'Participantes'),
                  Tab(text: 'Estadísticas'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildDetailsTab(),
                  _buildParticipantsTab(),
                  _buildStatsTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color temaColor) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: temaColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          // Imagen de fondo
          if (widget.project.imagen != null && widget.project.imagen!.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  widget.project.imagen!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: temaColor.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(
                          Icons.business_center,
                          color: temaColor,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Gradient overlay
          if (widget.project.imagen != null && widget.project.imagen!.isNotEmpty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.secondaryBackground.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
          // Título y tema
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: temaColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.project.temaNombre,
                      style: TextStyle(
                        color: temaColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.project.nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado
          _buildInfoSection(
            'Estado del Proyecto',
            [
              _buildStatusItem(
                'Estado',
                widget.project.activo ? 'Activo' : 'Inactivo',
                widget.project.activo ? AppColors.success : AppColors.error,
              ),
              _buildStatusItem(
                'Fecha de creación',
                widget.project.createdAt != null
                    ? _formatDate(widget.project.createdAt!)
                    : 'No disponible',
                AppColors.info,
              ),
              _buildStatusItem(
                'Orden de visualización',
                (widget.project.orden ?? 0).toString(),
                AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Descripción
          _buildInfoSection(
            'Descripción',
            [
              Text(
                widget.project.descripcion,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.project.pitch != null && widget.project.pitch!.isNotEmpty) ...[
            _buildDetailSection('Pitch', widget.project.pitch!),
            const SizedBox(height: 24),
          ],
          if (widget.project.problema != null && widget.project.problema!.isNotEmpty) ...[
            _buildDetailSection('Problema', widget.project.problema!),
            const SizedBox(height: 24),
          ],
          if (widget.project.solucion != null && widget.project.solucion!.isNotEmpty) ...[
            _buildDetailSection('Solución', widget.project.solucion!),
            const SizedBox(height: 24),
          ],
          if (widget.project.estrategiaIngresos != null &&
              widget.project.estrategiaIngresos!.isNotEmpty) ...[
            _buildDetailSection(
              'Estrategia de Ingresos',
              widget.project.estrategiaIngresos!,
            ),
            const SizedBox(height: 24),
          ],
          if (widget.project.proyeccionFinanciera != null &&
              widget.project.proyeccionFinanciera!.isNotEmpty) ...[
            _buildDetailSection(
              'Proyección Financiera',
              widget.project.proyeccionFinanciera!,
            ),
          ],
          if (widget.project.pitch == null &&
              widget.project.problema == null &&
              widget.project.solucion == null &&
              widget.project.estrategiaIngresos == null &&
              widget.project.proyeccionFinanciera == null)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay detalles adicionales',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: widget.project.participantes.isEmpty
          ? const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay participantes registrados',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.project.participantes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final participante = widget.project.participantes[index];
                return _buildParticipantCard(participante);
              },
            ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas principales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.attach_money,
                  '\$${(widget.project.totalInvertido).toStringAsFixed(0)}',
                  'Total Invertido',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  Icons.people,
                  widget.project.numeroInversores.toString(),
                  'Inversores',
                  AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Promedio por inversor
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tertiaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.info,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Promedio por Inversor',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.project.numeroInversores > 0
                      ? '\$${(widget.project.totalInvertido / widget.project.numeroInversores).toStringAsFixed(0)}'
                      : '\$0',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Estado del proyecto
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.project.activo
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.project.activo ? AppColors.success : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.project.activo ? Icons.check_circle : Icons.cancel,
                  color: widget.project.activo ? AppColors.success : AppColors.error,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del Proyecto',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.project.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: widget.project.activo ? AppColors.success : AppColors.error,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(Map<String, String> participante) {
    final nombre = participante['nombre'] ?? 'Sin nombre';
    final rol = participante['rol'] ?? 'Otro';
    final foto = participante['foto'];
    final temaColor = _hexToColor(widget.project.temaColor ?? '#00D4AA');
    final iniciales = nombre.isNotEmpty
        ? nombre.split(' ').map((n) => n[0]).take(2).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: temaColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: foto != null && foto.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      foto,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            iniciales,
                            style: TextStyle(
                              color: temaColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      iniciales,
                      style: TextStyle(
                        color: temaColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: temaColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rol,
                    style: TextStyle(
                      color: temaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
