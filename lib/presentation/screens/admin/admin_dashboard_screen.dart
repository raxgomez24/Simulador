import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/timer_badge.dart';
import '../../widgets/menu/menu_widgets.dart';
import 'users_management_screen.dart';
import 'themes_management_screen.dart';
import 'projects_management_screen.dart';
import 'investments_management_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _roundDurationMinutes = 30;
  bool _isSendingCommand = false;
  static final Logger _logger = Logger('AdminDashboardScreen');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeSessionListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSessionListener() {
    // Escuchar actualizaciones de la sesión desde el servidor
    ref.listen<AsyncValue<Session>>(sessionProvider, (previous, next) {
      final session = next.value;
      if (session != null && !_isSendingCommand) {
        // Solo actualizar desde el servidor si no estamos enviando un comando
        setState(() {
          _roundDurationMinutes = session.tiempoTotal.inMinutes;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    if (user == null || !user.isAdmin) {
      return const HamburgerMenuDrawer(
        child: Scaffold(
          body: Center(
            child: Text('Acceso no autorizado'),
          ),
        ),
      );
    }

    final projectsState = ref.watch(projectsProvider);
    final projects = projectsState.value ?? [];

    final sessionState = ref.watch(sessionProvider);
    final session = sessionState.value;
    final isRoundActive = session?.estado == SessionState.active;
    final isRoundPaused = session?.estado == SessionState.paused;

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          title: const Text('Panel de Administración'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Ver Dashboard Mejorado',
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.adminEnhanced);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Usuarios', icon: Icon(Icons.people)),
              Tab(text: 'Perfiles', icon: Icon(Icons.badge)),
              Tab(text: 'Temas', icon: Icon(Icons.category)),
              Tab(text: 'Proyectos', icon: Icon(Icons.business_center)),
              Tab(text: 'Inversiones', icon: Icon(Icons.receipt_long)),
            ],
            labelColor: AppColors.textSecondary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryAccent,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(projects, session, isRoundActive, isRoundPaused),
            _buildUsersTab(),
            _buildProfilesTab(),
            _buildThemesTab(),
            _buildProjectsTab(),
            _buildInvestmentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
    List<dynamic> projects,
    Session? session,
    bool isRoundActive,
    bool isRoundPaused,
  ) {
    final totalInvested = projects.fold<double>(
      0,
      (sum, p) => sum + (p.totalInvertido as double),
    );
    final totalInvestors = projects.fold<int>(
      0,
      (sum, p) => sum + (p.numeroInversores as int),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer Badge - Visible at the top of the dashboard
          if (session != null)
            Center(
              child: TimerBadge(session: session),
            ),

          const SizedBox(height: 24),

          // Round Controls
          _buildRoundControls(session, isRoundActive, isRoundPaused),

          const SizedBox(height: 24),

          // Stats Cards
          _buildAdminStats(
            totalProjects: projects.length,
            totalInvested: totalInvested,
            totalInvestors: totalInvestors,
          ),

          const SizedBox(height: 24),

          // Top Projects
          _buildTopProjectsSection(projects),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(session),
        ],
      ),
    );
  }

  Widget _buildRoundControls(
    Session? session,
    bool isRoundActive,
    bool isRoundPaused,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withOpacity(0.1),
            AppColors.secondaryAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Control de Ronda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Mostrar estado actual
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSessionStatusColor(session?.estado).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSessionStatusColor(session?.estado).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _getSessionStatusText(session?.estado),
                  style: TextStyle(
                    color: _getSessionStatusColor(session?.estado),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duración (minutos)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _roundDurationMinutes > 5 && !_isSendingCommand
                              ? () {
                                  setState(() {
                                    _roundDurationMinutes -= 5;
                                  });
                                  _updateRoundDuration();
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                          color: _roundDurationMinutes > 5 && !_isSendingCommand
                              ? AppColors.primaryAccent
                              : AppColors.textSecondary.withOpacity(0.3),
                        ),
                        Text(
                          '$_roundDurationMinutes',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _roundDurationMinutes < 120 && !_isSendingCommand
                              ? () {
                                  setState(() {
                                    _roundDurationMinutes += 5;
                                  });
                                  _updateRoundDuration();
                                }
                              : null,
                          icon: const Icon(Icons.add),
                          color: _roundDurationMinutes < 120 && !_isSendingCommand
                              ? AppColors.primaryAccent
                              : AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildRoundControlButton(
                      icon: isRoundActive
                          ? (isRoundPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_arrow,
                      label: isRoundActive
                          ? (isRoundPaused ? 'Reanudar' : 'Pausar')
                          : 'Iniciar',
                      onPressed: _isSendingCommand
                          ? null
                          : () {
                              if (isRoundActive) {
                                if (isRoundPaused) {
                                  _startRound(); // Reanudar
                                } else {
                                  _pauseRound(); // Pausar
                                }
                              } else {
                                _startRound(); // Iniciar
                              }
                            },
                      isActive: isRoundActive && !isRoundPaused,
                      isLoading: _isSendingCommand,
                    ),
                    const SizedBox(height: 12),
                    _buildRoundControlButton(
                      icon: Icons.stop,
                      label: 'Terminar',
                      onPressed: (isRoundActive || session?.estado == SessionState.paused) && !_isSendingCommand
                          ? () => _endRound()
                          : null,
                      isActive: false,
                      isDanger: true,
                      isLoading: _isSendingCommand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSessionStatusText(SessionState? estado) {
    switch (estado) {
      case SessionState.waiting:
        return 'Esperando';
      case SessionState.active:
        return 'En curso';
      case SessionState.paused:
        return 'Pausada';
      case SessionState.ended:
        return 'Finalizada';
      default:
        return 'Esperando';
    }
  }

  Color _getSessionStatusColor(SessionState? estado) {
    switch (estado) {
      case SessionState.waiting:
        return AppColors.textSecondary;
      case SessionState.active:
        return AppColors.success;
      case SessionState.paused:
        return AppColors.warning;
      case SessionState.ended:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildRoundControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isActive,
    bool isDanger = false,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? AppColors.primaryAccent
            : (isDanger ? AppColors.error : AppColors.tertiaryBackground),
        foregroundColor: isActive || isDanger
            ? Colors.white
            : AppColors.textPrimary,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAdminStats({
    required int totalProjects,
    required double totalInvested,
    required int totalInvestors,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.business_center,
            label: 'Proyectos',
            value: totalProjects.toString(),
            color: AppColors.primaryAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: 'Total Invertido',
            value: '\$${(totalInvested / 1000000).toStringAsFixed(1)}M',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Inversores',
            value: totalInvestors.toString(),
            color: AppColors.secondaryAccent,
          ),
        ),
      ],
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProjectsSection(List<dynamic> projects) {
    final topProjects = List<dynamic>.from(projects)
      ..sort(
        (a, b) => (b.totalInvertido as double).compareTo(a.totalInvertido as double),
      );
    topProjects.removeRange(5, topProjects.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Proyectos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...topProjects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            return _buildProjectRankItem(index + 1, project);
          }),
        ],
      ),
    );
  }

  Widget _buildProjectRankItem(int rank, dynamic project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              project.nombre as String,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '\$${((project.totalInvertido as double) / 1000000).toStringAsFixed(1)}M',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.tertiaryBackground;
    }
  }

  Widget _buildQuickActions(Session? session) {
    final canReset = session?.estado == SessionState.ended || session?.estado == SessionState.paused;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildQuickActionCard(
          icon: Icons.person_add,
          label: 'Nuevo Usuario',
          color: AppColors.primaryAccent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gestión de usuarios próximamente'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildQuickActionCard(
          icon: Icons.add_business,
          label: 'Nuevo Proyecto',
          color: AppColors.secondaryAccent,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.adminProjects);
          },
        ),
        _buildQuickActionCard(
          icon: Icons.category,
          label: 'Nueva Categoría',
          color: AppColors.success,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gestión de temas próximamente'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildQuickActionCard(
          icon: Icons.refresh,
          label: 'Reiniciar Ronda',
          color: AppColors.warning,
          onTap: canReset && !_isSendingCommand ? _resetRound : null,
          isEnabled: canReset,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? AppColors.borderLight : AppColors.borderLight.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : AppColors.textSecondary.withOpacity(0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEnabled ? null : AppColors.textSecondary.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return const UsersManagementScreen();
  }

  Widget _buildProfilesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 80,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gestión de Perfiles de Usuario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Administra los perfiles del sistema, sus saldos iniciales, permisos y configuraciones',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profiles);
              },
              icon: const Icon(Icons.settings, size: 20),
              label: const Text('Gestionar Perfiles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Perfiles del Sistema',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileItem('Admin', '\$0', 'Acceso completo', '#EF4444'),
          const SizedBox(height: 12),
          _buildProfileItem('Alumno', '\$1.0M', 'Puede invertir', '#00D4AA'),
          const SizedBox(height: 12),
          _buildProfileItem('Docente', '\$4.0M', 'Puede invertir', '#007AFF'),
          const SizedBox(height: 12),
          _buildProfileItem('Administrativo', '\$6.0M', 'Puede invertir', '#FFB800'),
          const SizedBox(height: 12),
          _buildProfileItem('Invitado', '\$2.0M', 'Puede invertir', '#A78BFA'),
          const SizedBox(height: 12),
          _buildProfileItem('Inversionista', '\$10.0M', 'Puede invertir', '#10B981'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String name, String balance, String description, String colorHex) {
    final color = _parseColor(colorHex);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          balance,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final colorCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$colorCode', radix: 16));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }

  Widget _buildThemesTab() {
    return const ThemesManagementScreen();
  }

  Widget _buildProjectsTab() {
    return const ProjectsManagementScreen();
  }

  Widget _buildInvestmentsTab() {
    return const InvestmentsManagementScreen();
  }

  // ==================== MÉTODOS DE CONTROL DE RONDA ====================

  Future<void> _startRound() async {
    setState(() => _isSendingCommand = true);

    try {
      final adminActions = ref.read(adminActionsProvider);
      await adminActions.startRound();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ronda iniciada correctamente'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar ronda: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCommand = false);
      }
    }
  }

  Future<void> _pauseRound() async {
    setState(() => _isSendingCommand = true);

    try {
      final adminActions = ref.read(adminActionsProvider);
      await adminActions.pauseRound();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ronda pausada correctamente'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al pausar ronda: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCommand = false);
      }
    }
  }

  Future<void> _endRound() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text('Terminar Ronda'),
        content: const Text(
          '¿Estás seguro de que quieres terminar la ronda de inversión? '
          'Esta acción bloqueará nuevas inversiones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSendingCommand = true);

      try {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.endRound();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ronda terminada correctamente'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al terminar ronda: $e'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingCommand = false);
        }
      }
    }
  }

  Future<void> _resetRound() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text('Reiniciar Ronda'),
        content: const Text(
          '¿Estás seguro de que quieres reiniciar la ronda? '
          'Esto restablecerá el temporizador y mantendrá las inversiones existentes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSendingCommand = true);

      try {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.resetRound();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ronda reiniciada correctamente'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al reiniciar ronda: $e'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingCommand = false);
        }
      }
    }
  }

  Future<void> _updateRoundDuration() async {
    try {
      final adminActions = ref.read(adminActionsProvider);
      await adminActions.setRoundDuration(_roundDurationMinutes);

      if (mounted) {
        // Mostrar indicador visual sutil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duración actualizada a $_roundDurationMinutes minutos'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.warning('Error al actualizar duración: $e');
      // No mostrar error al usuario para evitar interrupciones frecuentes
    }
  }
}
