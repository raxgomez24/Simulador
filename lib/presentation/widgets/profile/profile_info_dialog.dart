import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile.dart';

class ProfileInfoDialog extends StatelessWidget {
  final Profile profile;

  const ProfileInfoDialog({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(profile.color);

    return Dialog(
      backgroundColor: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProfileIcon(profile.id),
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.displayName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (profile.isSystemProfile)
                              Icon(
                                Icons.lock,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: profile.isActive
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.isActive ? 'Activo' : 'Inactivo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: profile.isActive ? AppColors.success : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              if (profile.description != null && profile.description!.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    profile.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Balance Info
              _buildInfoCard(
                context,
                Icons.account_balance_wallet,
                'Saldo Inicial',
                '\$${_formatBalance(profile.initialBalance)}',
                color,
                theme,
              ),
              const SizedBox(height: 16),

              // Permissions Section
              Text(
                'Permisos del Perfil',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionsGrid(color, theme),
              const SizedBox(height: 24),

              // Statistics (simulated)
              _buildStatisticsCard(context, theme),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsGrid(Color color, ThemeData theme) {
    final permissions = [
      {'icon': Icons.add_circle, 'label': 'Crear', 'value': profile.canCreate},
      {'icon': Icons.edit, 'label': 'Editar', 'value': profile.canEdit},
      {'icon': Icons.delete, 'label': 'Eliminar', 'value': profile.canDelete},
      {'icon': Icons.trending_up, 'label': 'Invertir', 'value': profile.canInvest},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        final isEnabled = permission['value'] as bool;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? color.withValues(alpha: 0.15)
                : AppColors.tertiaryBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? color.withValues(alpha: 0.3) : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              Icon(
                permission['icon'] as IconData,
                color: isEnabled ? color : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                permission['label'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(
                isEnabled ? Icons.check_circle : Icons.cancel,
                color: isEnabled ? AppColors.success : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(BuildContext context, ThemeData theme) {
    // Simulated statistics - in a real app, these would come from actual data
    final activeUsers = _getSimulatedUserCount(profile.id);
    final totalInvestments = _getSimulatedInvestmentCount(profile.id);
    final avgInvestment = _getSimulatedAvgInvestment(profile.id);

    return Container(
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
              Icon(Icons.analytics, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estadísticas (Simuladas)',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.people,
                  'Usuarios Activos',
                  activeUsers.toString(),
                  AppColors.primaryAccent,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.account_balance,
                  'Inversiones',
                  totalInvestments.toString(),
                  AppColors.secondaryAccent,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            context,
            Icons.show_chart,
            'Promedio Inversión',
            '\$${_formatBalance(avgInvestment)}',
            AppColors.success,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  int _getSimulatedUserCount(String profileId) {
    // Simulated user counts per profile
    switch (profileId) {
      case 'admin':
        return 3;
      case 'student':
        return 45;
      case 'teacher':
        return 8;
      case 'employee':
        return 12;
      case 'guest':
        return 5;
      case 'investor':
        return 7;
      default:
        return 0;
    }
  }

  int _getSimulatedInvestmentCount(String profileId) {
    // Simulated investment counts per profile
    switch (profileId) {
      case 'admin':
        return 0;
      case 'student':
        return 23;
      case 'teacher':
        return 15;
      case 'employee':
        return 28;
      case 'guest':
        return 8;
      case 'investor':
        return 42;
      default:
        return 0;
    }
  }

  double _getSimulatedAvgInvestment(String profileId) {
    // Simulated average investments per profile
    switch (profileId) {
      case 'admin':
        return 0;
      case 'student':
        return 150000;
      case 'teacher':
        return 450000;
      case 'employee':
        return 520000;
      case 'guest':
        return 180000;
      case 'investor':
        return 850000;
      default:
        return 0;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final colorCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$colorCode', radix: 16));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(0)}K';
    }
    return balance.toStringAsFixed(0);
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
