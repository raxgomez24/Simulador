import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/menu/menu_widgets.dart';

String _getRoleName(UserRole perfil) {
  switch (perfil) {
    case UserRole.admin:
      return 'Administrador';
    case UserRole.student:
      return 'Estudiante';
    case UserRole.guest:
      return 'Invitado';
    case UserRole.teacher:
      return 'Docente';
    case UserRole.employee:
      return 'Administrativo';
    case UserRole.investor:
      return 'Inversionista';
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      ref.invalidate(investmentsProvider(user.id));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text(AppStrings.logout),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
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

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authProvider);
    final user = userState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.profile),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    final investmentsAsync = ref.watch(investmentsProvider(user.id));
    final investments = investmentsAsync.value ?? [];

    final totalInvested = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.monto,
    );
    final projectsInvested = investments.map((inv) => inv.proyectoId).toSet().length;

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          title: const Text(AppStrings.profile),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: AppStrings.logout,
            ),
          ],
        ),
        body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(user),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: _buildStatsSection(
              totalInvested: totalInvested,
              investmentCount: investments.length,
              projectCount: projectsInvested,
            ),
          ),

          // Settings Section
          SliverToBoxAdapter(
            child: _buildSettingsSection(user),
          ),

          // Info Section
          SliverToBoxAdapter(
            child: _buildInfoSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 4),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
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
        children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@${user.username}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(user.perfil),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  _getRoleName(user.perfil),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Balance
          Text(
            AppStrings.balance,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(user.saldo),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection({
    required double totalInvested,
    required int investmentCount,
    required int projectCount,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.myStatistics,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Invertido',
                  value: Formatters.formatCurrency(totalInvested),
                  color: AppColors.primaryAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long,
                  label: 'Inversiones',
                  value: investmentCount.toString(),
                  color: AppColors.secondaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.business_center,
            label: 'Proyectos Invertidos',
            value: projectCount.toString(),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Información Personal',
            subtitle: user.nombre,
            onTap: () {
              // Navigate to personal info
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildSettingItem(
            icon: Icons.email_outlined,
            title: 'Correo Electrónico',
            subtitle: user.correo ?? 'No especificado',
            onTap: () {
              // Navigate to email settings
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Cambiar Contraseña',
            subtitle: 'Actualizar tu contraseña',
            onTap: () {
              // Navigate to password change
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Configurar alertas',
            onTap: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.info,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.help_outline,
            title: AppStrings.help,
            onTap: () {
              // Navigate to help
            },
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.info_outline,
            title: 'Sobre la App',
            onTap: () {
              // Navigate to about
            },
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.description_outlined,
            title: 'Términos y Condiciones',
            onTap: () {
              // Navigate to terms
            },
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de Privacidad',
            onTap: () {
              // Navigate to privacy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.tertiaryBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  IconData _getRoleIcon(UserRole perfil) {
    switch (perfil) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.student:
        return Icons.school;
      case UserRole.guest:
        return Icons.person;
      case UserRole.teacher:
        return Icons.school;
      case UserRole.employee:
        return Icons.business_center;
      case UserRole.investor:
        return Icons.trending_up;
    }
  }
}
