import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/theme.dart';
import '../../../domain/entities/project.dart';
import '../../providers/themes_provider.dart';
import '../../providers/project_provider.dart';

class ThemeInfoDialog extends ConsumerWidget {
  final InvestmentTheme theme;

  const ThemeInfoDialog({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final projectCount = ref.watch(themeProjectCountProvider(theme.id));
    final totalInvested = ref.watch(themeTotalInvestedProvider(theme.id));

    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _hexToColor(theme.color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hexToColor(theme.color),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        theme.icon,
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
                          theme.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              theme.activo ? Icons.check_circle : Icons.cancel,
                              color: theme.activo ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              theme.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: theme.activo ? AppColors.success : AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Orden: ${theme.orden}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Descripción
              if (theme.descripcion.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme.descripcion,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Proyectos',
                      projectCount.toString(),
                      Icons.folder_open,
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Invertido',
                      '\$${totalInvested.toStringAsFixed(0)}',
                      Icons.attach_money,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (projectCount > 0)
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Promedio',
                        '\$${(totalInvested / projectCount).toStringAsFixed(0)}',
                        Icons.trending_up,
                        AppColors.primaryAccent,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Lista de proyectos
              const Text(
                'Proyectos del Tema',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: projectsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error al cargar proyectos: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (projects) {
                    final themeProjects = projects
                        .where((project) => project.temaId == theme.id)
                        .toList();

                    if (themeProjects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay proyectos en este tema',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: themeProjects.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final project = themeProjects[index];
                        return _buildProjectCard(project);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Botón cerrar
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          if (project.imagen != null && project.imagen!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                project.imagen!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: AppColors.tertiaryBackground,
                    child: const Icon(Icons.image, color: AppColors.textSecondary),
                  );
                },
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: project.temaColor != null
                    ? _hexToColor(project.temaColor!).withValues(alpha: 0.2)
                    : AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '📁',
                  style: const TextStyle(fontSize: 28),
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.descripcion,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '\$${project.totalInvertido.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
