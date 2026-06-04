import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/themes_provider.dart';
import '../../providers/admin_provider.dart';

class ThemeDeleteDialog extends ConsumerWidget {
  final InvestmentTheme theme;

  const ThemeDeleteDialog({
    super.key,
    required this.theme,
  });

  Future<void> _deactivateTheme(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminActionsProvider).updateTheme(
            id: theme.id,
            nombre: theme.nombre,
            descripcion: theme.descripcion,
            color: theme.color,
            icono: theme.icon,
            orden: theme.orden,
          );

      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tema desactivado exitosamente'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desactivar tema: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTheme(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminActionsProvider).deleteTheme(theme.id);

      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tema eliminado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar tema: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectCount = ref.watch(themeProjectCountProvider(theme.id));
    final totalInvested = ref.watch(themeTotalInvestedProvider(theme.id));

    return AlertDialog(
      backgroundColor: AppColors.secondaryBackground,
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Eliminar Tema',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del tema
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _hexToColor(theme.color), width: 2),
              ),
              child: Row(
                children: [
                  Text(
                    theme.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (theme.descripcion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            theme.descripcion,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Estadísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Proyectos',
                    projectCount.toString(),
                    Icons.folder_open,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Invertido',
                    '\$${totalInvested.toStringAsFixed(0)}',
                    Icons.attach_money,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      projectCount > 0
                          ? 'Este tema tiene $projectCount proyecto(s) asociado(s) por un total de \$${totalInvested.toStringAsFixed(0)}. Se recomienda desactivar el tema en lugar de eliminarlo.'
                          : '¿Estás seguro de que deseas eliminar este tema? Esta acción no se puede deshacer.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        if (projectCount > 0)
          OutlinedButton(
            onPressed: () => _deactivateTheme(context, ref),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.warning),
            ),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ElevatedButton(
          onPressed: () => _deleteTheme(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
