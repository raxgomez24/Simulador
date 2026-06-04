import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/project.dart';
import '../../providers/projects_management_provider.dart';

class ProjectDeleteDialog extends ConsumerWidget {
  final Project project;

  const ProjectDeleteDialog({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInvestments = project.numeroInversores > 0 || project.totalInvertido > 0;

    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: Row(
        children: [
          Icon(
            hasInvestments ? Icons.warning_amber : Icons.delete_outline,
            color: hasInvestments ? AppColors.warning : AppColors.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Eliminar Proyecto',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje de advertencia
            Text(
              hasInvestments
                  ? 'Este proyecto tiene inversiones registradas. Eliminarlo podría afectar la integridad de los datos.'
                  : '¿Estás seguro de que deseas eliminar este proyecto? Esta acción no se puede deshacer.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Información del proyecto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _hexToColor(project.temaColor ?? '#00D4AA')
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: AppColors.primaryAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.nombre,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              project.temaNombre,
                              style: TextStyle(
                                color: _hexToColor(project.temaColor ?? '#00D4AA'),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),

                  // Estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.attach_money,
                        '\$${(project.totalInvertido).toStringAsFixed(0)}',
                        'Total Invertido',
                        AppColors.success,
                      ),
                      _buildStatItem(
                        Icons.people,
                        '${project.numeroInversores}',
                        'Inversores',
                        AppColors.primaryAccent,
                      ),
                      _buildStatItem(
                        Icons.event,
                        project.createdAt != null
                            ? _formatDate(project.createdAt!)
                            : 'N/A',
                        'Creado',
                        AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (hasInvestments) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recomendamos desactivar el proyecto en lugar de eliminarlo para mantener el historial de inversiones.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (hasInvestments)
          OutlinedButton(
            onPressed: () async {
              try {
                await ref.read(projectsManagementProvider.notifier).updateProject(
                      id: project.id,
                      titulo: project.nombre,
                      descripcion: project.descripcion,
                      imagen: project.imagen ?? '',
                      activo: false,
                      pitch: project.pitch ?? '',
                      problema: project.problema ?? '',
                      solucion: project.solucion ?? '',
                      estrategiaIngresos: project.estrategiaIngresos ?? '',
                      proyeccionFinanciera: project.proyeccionFinanciera ?? '',
                      participantes: project.participantes,
                      orden: project.orden ?? 0,
                    );

                if (context.mounted) {
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proyecto desactivado exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.warning),
            ),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(projectsManagementProvider.notifier).deleteProject(project.id);

              if (context.mounted) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proyecto eliminado exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text(
            'Eliminar',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
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
