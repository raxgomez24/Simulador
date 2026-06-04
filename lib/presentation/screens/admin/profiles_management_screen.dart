import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/profile.dart';
import '../../providers/profiles_provider.dart';
import '../../widgets/profile/profile_edit_dialog.dart';
import '../../widgets/profile/profile_info_dialog.dart';

class ProfilesManagementScreen extends ConsumerWidget {
  const ProfilesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground,
        elevation: 0,
        title: const Text(
          'Gestión de Perfiles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(profilesProvider.notifier).resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perfiles restablecidos a valores por defecto'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            tooltip: 'Restablecer perfiles',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, profiles.length),
            const SizedBox(height: 24),
            Expanded(
              child: _buildProfilesGrid(context, ref, profiles),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int profileCount) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfiles del Sistema',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Administra los perfiles de usuario, sus saldos iniciales y permisos',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Los 6 perfiles base del sistema no pueden ser eliminados, pero sus configuraciones pueden ser modificadas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilesGrid(BuildContext context, WidgetRef ref, List<Profile> profiles) {
    final theme = Theme.of(context);
    final activeProfiles = profiles.where((p) => p.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: ${profiles.length} perfiles',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$activeProfiles activos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return _buildProfileCard(context, ref, profiles[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, Profile profile) {
    final theme = Theme.of(context);
    final color = _parseColor(profile.color);
    final isInactive = !profile.isActive;

    return GestureDetector(
      onTap: () => _showProfileInfoDialog(context, profile),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInactive ? AppColors.borderDark : color.withValues(alpha: 0.3),
            width: isInactive ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color indicator and actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isInactive ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (profile.isSystemProfile)
                    Icon(
                      Icons.lock,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  if (!profile.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Inactivo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance
                    _buildInfoRow(
                      Icons.account_balance_wallet,
                      'Saldo inicial',
                      '\$${_formatBalance(profile.initialBalance)}',
                      color: isInactive ? AppColors.textSecondary : color,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    // Permissions count
                    _buildInfoRow(
                      Icons.security,
                      'Permisos',
                      '${profile.activePermissionsCount}/4',
                      color: isInactive ? AppColors.textSecondary : AppColors.textSecondary,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (profile.description != null && profile.description!.isNotEmpty)
                      Expanded(
                        child: Text(
                          profile.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isInactive
                                ? AppColors.textSecondary.withValues(alpha: 0.6)
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProfileInfoDialog(context, profile),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Ver'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(context, ref, profile),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {required Color color, required ThemeData theme}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProfileInfoDialog(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => ProfileInfoDialog(profile: profile),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(profile: profile),
    ).then((updatedProfile) {
      if (updatedProfile != null) {
        ref.read(profilesProvider.notifier).updateProfile(updatedProfile);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil "${updatedProfile.displayName}" actualizado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
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
}
