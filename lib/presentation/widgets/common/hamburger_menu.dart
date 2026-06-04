import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class HamburgerMenu extends StatelessWidget {
  final bool isEnabled;
  final Function(bool)? onToggle;

  const HamburgerMenu({
    super.key,
    required this.isEnabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.secondaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const Divider(color: AppColors.borderLight),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home,
                    title: AppStrings.home,
                    route: AppRoutes.home,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category,
                    title: AppStrings.categories,
                    route: AppRoutes.projects,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: AppStrings.investments,
                    route: AppRoutes.investments,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.leaderboard,
                    title: AppStrings.ranking,
                    route: AppRoutes.ranking,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person,
                    title: AppStrings.profile,
                    route: AppRoutes.profile,
                  ),
                  const Divider(color: AppColors.borderLight),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Historial de Inversiones',
                    route: AppRoutes.investments,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: AppStrings.help,
                    onTap: () {
                      Navigator.pop(context);
                      // Show help dialog
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'Instrucciones',
                    onTap: () {
                      Navigator.pop(context);
                      // Show instructions dialog
                    },
                  ),
                  const Divider(color: AppColors.borderLight),

                  // Admin Settings (only show if admin)
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(authProvider).value;
                      if (user?.isAdmin ?? false) {
                        return Column(
                          children: [
                            _buildMenuItem(
                              context,
                              icon: Icons.admin_panel_settings,
                              title: 'Administración',
                              route: AppRoutes.admin,
                              isAdmin: true,
                            ),
                            const Divider(color: AppColors.borderLight),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Menu Toggle (for admin)
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(authProvider).value;
                      if (user?.isAdmin ?? false) {
                        return ListTile(
                          leading: const Icon(
                            Icons.menu,
                            color: AppColors.textSecondary,
                          ),
                          title: const Text(
                            'Mostrar Menú Hamburguesa',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (value) {
                              onToggle?.call(value);
                            },
                            activeColor: AppColors.primaryAccent,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  Consumer(
                    builder: (context, ref, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            AppStrings.logout,
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.secondaryBackground,
                                title: const Text(AppStrings.logout),
                                content: const Text(
                                  '¿Estás seguro de que quieres cerrar sesión?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text(AppStrings.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      AppStrings.confirm,
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && context.mounted) {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (route) => false,
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final user = ref.watch(authProvider).value;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryAccent,
                AppColors.secondaryAccent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.initials ?? '??',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.username ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isAdmin = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isAdmin ? AppColors.primaryAccent : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isAdmin ? AppColors.primaryAccent : AppColors.textPrimary,
          fontWeight: isAdmin ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (route) => false,
          );
        }
        onTap?.call();
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 8),
          Text(
            'Amerike MBA 2026',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Versión 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
