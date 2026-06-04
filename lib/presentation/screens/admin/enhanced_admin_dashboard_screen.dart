import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../app/routes.dart';
import '../../../app/config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/investment.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/project.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/users_provider.dart';
import '../../providers/investments_management_provider.dart';
import '../../widgets/dialogs/export_options_dialog.dart';
import 'users_management_screen.dart';
import 'themes_management_screen.dart';
import 'projects_management_screen.dart';
import 'investments_management_screen.dart';

/// Enhanced Admin Dashboard Screen with advanced features
/// Includes real-time activity, interactive charts, filters, keyboard shortcuts,
/// and full-screen projection mode
class EnhancedAdminDashboardScreen extends ConsumerStatefulWidget {
  const EnhancedAdminDashboardScreen({super.key});

  @override
  ConsumerState<EnhancedAdminDashboardScreen> createState() =>
      _EnhancedAdminDashboardScreenState();
}

class _EnhancedAdminDashboardScreenState
    extends ConsumerState<EnhancedAdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _roundDurationMinutes = 30;
  bool _isSendingCommand = false;
  bool _isFullScreen = false;

  // Filter states
  String _selectedTimeFilter = 'all'; // today, week, round, all
  String? _selectedThemeFilter;
  UserRole? _selectedProfileFilter;
  bool _showRealTimeData = true;

  // Sort options for projects ranking
  ProjectSortOption _sortOption = ProjectSortOption.totalAmount;

  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;

  // Scroll controller for activity feed
  final ScrollController _activityScrollController = ScrollController();
  final List<Investment> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeAnimations();
    _loadRecentActivities();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _loadRecentActivities() async {
    // Load recent investments for activity feed
    final investmentsState = ref.read(investmentsManagementProvider);
    final investments = _filterInvestmentsByProfile(investmentsState.investments);

    setState(() {
      _recentActivities.clear();
      _recentActivities.addAll(
        investments.take(10).toList(),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    _activityScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Acceso no autorizado'),
        ),
      );
    }

    final projectsState = ref.watch(projectsProvider);
    final projects = projectsState.value ?? [];

    final sessionState = ref.watch(sessionProvider);
    final session = sessionState.value;
    final isRoundActive = session?.estado == SessionState.active;
    final isRoundPaused = session?.estado == SessionState.paused;

    // Listen for session changes to update round duration
    ref.listen<AsyncValue<Session>>(sessionProvider, (previous, next) {
      final newSession = next.value;
      if (newSession != null && !_isSendingCommand) {
        setState(() {
          _roundDurationMinutes = newSession.tiempoTotal.inMinutes;
        });
      }
    });

    // Wrap with full-screen mode
    final content = Scaffold(
      appBar: _isFullScreen ? null : _buildAppBar(),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) => _handleKeyPress(event, isRoundActive, isRoundPaused),
        child: TabBarView(
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
      floatingActionButton: _isFullScreen ? _buildFullScreenControls() : null,
    );

    if (_isFullScreen) {
      return FullScreenMode(
        child: content,
        onExit: () => setState(() => _isFullScreen = false),
      );
    }

    return content;
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('Panel de Administración'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity( 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Mejorado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar Datos (E)',
          onPressed: _showExportDialog,
        ),
        IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Ver Dashboard Clásico',
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.admin);
          },
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen),
          tooltip: 'Pantalla completa (F)',
          onPressed: () => setState(() => _isFullScreen = true),
        ),
        _buildKeyboardShortcutsHelp(),
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
    );
  }

  Widget _buildKeyboardShortcutsHelp() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.keyboard),
      tooltip: 'Atajos de teclado',
      onSelected: (value) {
        // Handle shortcuts menu if needed
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'shortcuts',
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Atajos de Teclado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const _ShortcutItem('Espacio', 'Pausar/Reanudar'),
              const _ShortcutItem('S', 'Iniciar ronda'),
              const _ShortcutItem('E', 'Terminar ronda'),
              const _ShortcutItem('R', 'Reiniciar ronda'),
              const _ShortcutItem('F', 'Pantalla completa'),
              const _ShortcutItem('Esc', 'Salir pantalla completa'),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    final investmentsState = ref.watch(investmentsManagementProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final usersAsync = ref.watch(userProvider);

    final investments = investmentsState.investments;
    final projects = projectsAsync.maybeWhen(
      data: (proj) => proj,
      orElse: () => <Project>[],
    );
    final users = usersAsync.maybeWhen(
      data: (u) => u,
      orElse: () => <User>[],
    );

    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        investments: investments,
        projects: projects,
        users: users,
      ),
    );
  }

  void _handleKeyPress(KeyEvent event, bool isRoundActive, bool isRoundPaused) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        if (isRoundActive) {
          isRoundPaused ? _resumeRound() : _pauseRound();
        }
        break;
      case LogicalKeyboardKey.keyS:
        if (!isRoundActive) _startRound();
        break;
      case LogicalKeyboardKey.keyE:
        if (isRoundActive || isRoundPaused) _endRound();
        break;
      case LogicalKeyboardKey.keyR:
        _resetRound();
        break;
      case LogicalKeyboardKey.keyF:
        setState(() => _isFullScreen = !_isFullScreen);
        break;
      case LogicalKeyboardKey.escape:
        if (_isFullScreen) {
          setState(() => _isFullScreen = false);
        }
        break;
    }
  }

  Widget _buildDashboardTab(
    List<dynamic> projects,
    Session? session,
    bool isRoundActive,
    bool isRoundPaused,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters Section
          _buildFiltersSection(projects),

          const SizedBox(height: 24),

          // Enhanced Round Controls with Circular Timer
          _buildEnhancedRoundControls(session, isRoundActive, isRoundPaused),

          const SizedBox(height: 24),

          // Enhanced Stats Cards with Trends
          _buildEnhancedAdminStats(projects, session),

          const SizedBox(height: 24),

          // Real-time Activity Feed
          _buildRealTimeActivityFeed(),

          const SizedBox(height: 24),

          // Interactive Projects Chart
          _buildInteractiveProjectsChart(projects),

          const SizedBox(height: 24),

          // Enhanced Projects Ranking
          _buildEnhancedProjectsRanking(projects),

          const SizedBox(height: 24),

          // General Statistics with Charts
          _buildGeneralStatisticsCharts(projects),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(session),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(List<dynamic> projects) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.tertiaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtros del Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Real-time toggle
              Switch(
                value: _showRealTimeData,
                onChanged: (value) {
                  setState(() => _showRealTimeData = value);
                },
                activeTrackColor: AppColors.primaryAccent.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tiempo Real',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Hoy', 'today', _selectedTimeFilter),
              _buildFilterChip('Esta Semana', 'week', _selectedTimeFilter),
              _buildFilterChip('Esta Ronda', 'round', _selectedTimeFilter),
              _buildFilterChip('Todo', 'all', _selectedTimeFilter),
            ],
          ),

          const SizedBox(height: 16),

          // Theme and Profile Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Tema',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryBackground,
                  ),
                  initialValue: _selectedThemeFilter,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los temas'),
                    ),
                    ..._getUniqueThemes(projects).map((theme) {
                      return DropdownMenuItem(
                        value: theme,
                        child: Text(theme),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedThemeFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<UserRole>(
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Perfil',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryBackground,
                  ),
                  initialValue: _selectedProfileFilter,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los perfiles'),
                    ),
                    ...UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(User.perfilToString(role)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProfileFilter = value;
                    });
                    // Reload recent activities when profile filter changes
                    _loadRecentActivities();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeFilter = value);
      },
      backgroundColor: AppColors.tertiaryBackground,
      selectedColor: AppColors.primaryAccent.withOpacity( 0.3),
      checkmarkColor: AppColors.primaryAccent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<String> _getUniqueThemes(List<dynamic> projects) {
    final themes = <String>{};
    for (final project in projects) {
      if (project.temaNombre != null) {
        themes.add(project.temaNombre as String);
      }
    }
    return themes.toList()..sort();
  }

  Widget _buildEnhancedRoundControls(
    Session? session,
    bool isRoundActive,
    bool isRoundPaused,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withOpacity( 0.15),
            AppColors.secondaryAccent.withOpacity( 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity( 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withOpacity( 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: AppColors.primaryAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Control de Ronda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getSessionStatusColor(session?.estado).withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getSessionStatusColor(session?.estado).withOpacity( 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSessionStatusIcon(session?.estado),
                      size: 16,
                      color: _getSessionStatusColor(session?.estado),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getSessionStatusText(session?.estado),
                      style: TextStyle(
                        color: _getSessionStatusColor(session?.estado),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              // Circular Timer
              Expanded(
                child: _buildCircularTimer(session, isRoundActive, isRoundPaused),
              ),

              const SizedBox(width: 24),

              // Duration Controls
              Expanded(
                child: _buildDurationControls(isRoundActive),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildRoundControlButton(
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
                              _resumeRound();
                            } else {
                              _pauseRound();
                            }
                          } else {
                            _startRound();
                          }
                        },
                  isActive: isRoundActive && !isRoundPaused,
                  isLoading: _isSendingCommand,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoundControlButton(
                  icon: Icons.stop,
                  label: 'Terminar',
                  onPressed: (isRoundActive || session?.estado == SessionState.paused) && !_isSendingCommand
                      ? () => _endRound()
                      : null,
                  isActive: false,
                  isDanger: true,
                  isLoading: _isSendingCommand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(
    Session? session,
    bool isRoundActive,
    bool isRoundPaused,
  ) {
    final remainingTime = session?.tiempoRestante ?? Duration.zero;
    final totalTime = Duration(minutes: _roundDurationMinutes);
    final progress = totalTime.inSeconds > 0
        ? remainingTime.inSeconds / totalTime.inSeconds
        : 0.0;

    final timerColor = _getTimerColor(progress);

    return Column(
      children: [
        const Text(
          'Tiempo Restante',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 8,
                  ),
                ),
              ),
              // Progress circle
              if (isRoundActive || isRoundPaused)
                AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseAnimationController.value * 0.02),
                      child: CustomPaint(
                        size: const Size(150, 150),
                        painter: _CircularTimerPainter(
                          progress: progress,
                          color: timerColor,
                          strokeWidth: 8,
                        ),
                      ),
                    );
                  },
                ),
              // Time display
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(remainingTime),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                    if (isRoundPaused)
                      const Text(
                        'PAUSADO',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
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
    );
  }

  Color _getTimerColor(double progress) {
    if (progress > 0.5) return AppColors.success;
    if (progress > 0.2) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildDurationControls(bool isRoundActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duración (minutos)',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 40,
              color: _roundDurationMinutes > 5 && !_isSendingCommand
                  ? AppColors.primaryAccent
                  : AppColors.textSecondary.withOpacity( 0.3),
            ),
            const SizedBox(width: 24),
            Text(
              '$_roundDurationMinutes',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: _roundDurationMinutes < 120 && !_isSendingCommand
                  ? () {
                      setState(() {
                        _roundDurationMinutes += 5;
                      });
                      _updateRoundDuration();
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 40,
              color: _roundDurationMinutes < 120 && !_isSendingCommand
                  ? AppColors.primaryAccent
                  : AppColors.textSecondary.withOpacity( 0.3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Rango: 5 - 120 minutos',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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

  IconData _getSessionStatusIcon(SessionState? estado) {
    switch (estado) {
      case SessionState.waiting:
        return Icons.schedule;
      case SessionState.active:
        return Icons.play_circle;
      case SessionState.paused:
        return Icons.pause_circle;
      case SessionState.ended:
        return Icons.check_circle;
      default:
        return Icons.schedule;
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
    bool isPrimary = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppColors.primaryAccent,
                  AppColors.primaryAccent.withOpacity( 0.8),
                ],
              )
            : (isDanger
                ? LinearGradient(
                    colors: [
                      AppColors.error,
                      AppColors.error.withOpacity( 0.8),
                    ],
                  )
                : null),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive || isDanger
              ? Colors.transparent
              : AppColors.borderLight,
          width: 2,
        ),
        color: !isActive && !isDanger ? AppColors.tertiaryBackground : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity( 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isActive || isDanger
              ? Colors.white
              : AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEnhancedAdminStats(List<dynamic> projects, Session? session) {
    // Get investments and filter by profile if selected
    final investmentsState = ref.watch(investmentsManagementProvider);
    final investments = _filterInvestmentsByProfile(investmentsState.investments);

    // Calculate enhanced statistics based on filtered investments
    final totalInvested = investments.fold<double>(
      0,
      (sum, inv) => sum + inv.monto,
    );
    final totalInvestors = <String>{}; // Use set to count unique investors
    for (final inv in investments) {
      totalInvestors.add(inv.usuarioId);
    }

    // Get projects for project-related stats
    final activeProjects = projects.where((p) => p.activo as bool).length;
    final avgInvestmentPerInvestor = totalInvestors.isNotEmpty
        ? totalInvested / totalInvestors.length
        : 0.0;

    // Calculate project stats from investments
    final projectInvestments = <String, double>{};
    final projectInvestorCount = <String, Set<String>>{};
    for (final inv in investments) {
      projectInvestments[inv.proyectoId] =
          (projectInvestments[inv.proyectoId] ?? 0) + inv.monto;
      if (!projectInvestorCount.containsKey(inv.proyectoId)) {
        projectInvestorCount[inv.proyectoId] = {};
      }
      projectInvestorCount[inv.proyectoId]!.add(inv.usuarioId);
    }

    final avgInvestmentPerProject = projectInvestments.isNotEmpty
        ? totalInvested / projectInvestments.length
        : 0.0;

    // Find leading theme and project from investments
    final themeInvestments = <String, double>{};
    for (final inv in investments) {
      themeInvestments[inv.temaNombre] =
          (themeInvestments[inv.temaNombre] ?? 0) + inv.monto;
    }

    final leadingTheme = themeInvestments.entries.isNotEmpty
        ? themeInvestments.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'N/A';

    final leadingProjectId = projectInvestments.entries.isNotEmpty
        ? projectInvestments.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;

    final leadingProject = leadingProjectId != null
        ? projects.where((p) => p.id == leadingProjectId).firstOrNull
        : null;

    // Get users for additional stats
    final usersState = ref.watch(userProvider);
    final activeUsers = usersState.maybeWhen(
      data: (users) => users.where((u) => u.activo).length,
      orElse: () => 0,
    );

    final totalAvailableBalance = usersState.maybeWhen(
      data: (users) => users.fold<double>(
        0,
        (sum, user) => sum + user.saldo,
      ),
      orElse: () => 0.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildEnhancedStatCard(
              icon: Icons.business_center,
              label: 'Proyectos Activos',
              value: activeProjects.toString(),
              color: AppColors.primaryAccent,
              trend: '+5%',
              trendUp: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.account_balance_wallet,
              label: 'Total Invertido',
              value: '\$${(totalInvested / 1000000).toStringAsFixed(1)}M',
              color: AppColors.success,
              trend: '+12%',
              trendUp: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.people,
              label: 'Inversores',
              value: totalInvestors.length.toString(),
              color: AppColors.secondaryAccent,
              trend: '+8%',
              trendUp: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.person_search,
              label: 'Usuarios Activos',
              value: activeUsers.toString(),
              color: AppColors.info,
              trend: '+3%',
              trendUp: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.trending_up,
              label: 'Promedio/Usuario',
              value: '\$${(avgInvestmentPerInvestor / 1000).toStringAsFixed(0)}K',
              color: AppColors.warning,
              trend: '-2%',
              trendUp: false,
            ),
            _buildEnhancedStatCard(
              icon: Icons.analytics,
              label: 'Promedio/Proyecto',
              value: '\$${(avgInvestmentPerProject / 1000000).toStringAsFixed(1)}M',
              color: AppColors.secondaryAccent,
              trend: '+15%',
              trendUp: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.star,
              label: 'Tema Líder',
              value: leadingTheme,
              color: AppColors.primaryAccent,
              isTextValue: true,
            ),
            _buildEnhancedStatCard(
              icon: EmojiPicker().getEmojiForTheme(leadingTheme),
              label: 'Proyecto Líder',
              value: leadingProject?.nombre as String? ?? 'N/A',
              color: AppColors.success,
              isTextValue: true,
            ),
            _buildEnhancedStatCard(
              icon: Icons.savings,
              label: 'Saldo Disponible',
              value: '\$${(totalAvailableBalance / 1000000).toStringAsFixed(1)}M',
              color: AppColors.info,
              trend: '-5%',
              trendUp: false,
            ),
          ],
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? trend,
    bool trendUp = true,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withOpacity( 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity( 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity( 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ? AppColors.success : AppColors.error)
                        .withOpacity( 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trendUp ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isTextValue ? 16 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: isTextValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.tertiaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fiber_manual_record,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Actividad en Tiempo Real',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(
                            0.5 * _pulseAnimationController.value,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'En vivo',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_recentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay actividad reciente',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                controller: _activityScrollController,
                itemCount: _recentActivities.length,
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return _buildActivityItem(activity, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Investment activity, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground.withOpacity( 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderLight.withOpacity( 0.5),
                ),
              ),
              child: Row(
                children: [
                  // User avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryAccent,
                          AppColors.secondaryAccent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(activity.usuarioNombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Activity details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.usuarioNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'invirtió en ${activity.proyectoNombre}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${(activity.monto / 1000).toStringAsFixed(0)}K',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Time
                  Text(
                    _formatTimeAgo(activity.fechaHora),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0].toUpperCase()}${parts[parts.length - 1][0].toUpperCase()}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildInteractiveProjectsChart(List<dynamic> projects) {
    final filteredProjects = _filterAndSortProjects(projects);

    // Get filtered investments for calculating investment amounts
    final investmentsState = ref.watch(investmentsManagementProvider);
    final filteredInvestments = _filterInvestmentsByProfile(investmentsState.investments);

    // Calculate investment stats per project from filtered investments
    final projectInvestments = <String, double>{};
    for (final inv in filteredInvestments) {
      projectInvestments[inv.proyectoId] =
          (projectInvestments[inv.proyectoId] ?? 0) + inv.monto;
    }

    // Create a map of projects with their filtered investment amounts
    final projectsWithInvestments = filteredProjects.map((project) {
      final investedAmount = projectInvestments[project.id as String] ?? 0.0;
      return {
        'project': project,
        'investedAmount': investedAmount,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.tertiaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Distribución de Inversiones por Proyecto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Sort options
              PopupMenuButton<ProjectSortOption>(
                icon: const Icon(Icons.sort),
                onSelected: (option) {
                  setState(() => _sortOption = option);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ProjectSortOption.totalAmount,
                    child: Text('Monto Total'),
                  ),
                  const PopupMenuItem(
                    value: ProjectSortOption.investorCount,
                    child: Text('Número de Inversores'),
                  ),
                  const PopupMenuItem(
                    value: ProjectSortOption.averageAmount,
                    child: Text('Inversión Promedio'),
                  ),
                  const PopupMenuItem(
                    value: ProjectSortOption.lastInvestment,
                    child: Text('Última Inversión'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 250,
            child: _ProjectsBarChart(
              projectsWithInvestments: projectsWithInvestments,
              onBarTap: (project) {
                _showProjectDetails(project);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterAndSortProjects(List<dynamic> projects) {
    var filtered = List<dynamic>.from(projects);

    // Apply theme filter
    if (_selectedThemeFilter != null) {
      filtered = filtered.where((p) =>
        p.temaNombre == _selectedThemeFilter
      ).toList();
    }

    // Sort based on selected option
    switch (_sortOption) {
      case ProjectSortOption.totalAmount:
        filtered.sort((a, b) =>
          (b.totalInvertido as double).compareTo(a.totalInvertido as double));
        break;
      case ProjectSortOption.investorCount:
        filtered.sort((a, b) =>
          (b.numeroInversores as int).compareTo(a.numeroInversores as int));
        break;
      case ProjectSortOption.averageAmount:
        filtered.sort((a, b) {
          final avgA = (a.totalInvertido as double) / (a.numeroInversores as int);
          final avgB = (b.totalInvertido as double) / (b.numeroInversores as int);
          return avgB.compareTo(avgA);
        });
        break;
      case ProjectSortOption.lastInvestment:
        // Sort by creation date (simplified)
        filtered.sort((a, b) {
          final dateA = a.createdAt ?? DateTime.now();
          final dateB = b.createdAt ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
    }

    return filtered.take(10).toList();
  }

  /// Filter investments by selected profile
  List<Investment> _filterInvestmentsByProfile(List<Investment> investments) {
    if (_selectedProfileFilter == null) {
      return investments;
    }
    return investments.where((inv) => inv.perfil == _selectedProfileFilter).toList();
  }

  void _showProjectDetails(dynamic project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text(project.nombre as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Descripción', project.descripcion as String),
            const SizedBox(height: 8),
            _buildDetailRow('Tema', project.temaNombre as String),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Invertido',
              '\$${((project.totalInvertido as double) / 1000000).toStringAsFixed(2)}M',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Inversores',
              '${project.numeroInversores as int}',
            ),
            if (project.pitch != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Pitch', project.pitch as String),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminProjects);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
            child: const Text('Ver Detalles Completos'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProjectsRanking(List<dynamic> projects) {
    final sortedProjects = _filterAndSortProjects(projects);

    // Get filtered investments for calculating investment amounts
    final investmentsState = ref.watch(investmentsManagementProvider);
    final filteredInvestments = _filterInvestmentsByProfile(investmentsState.investments);

    // Calculate investment stats per project from filtered investments
    final projectInvestments = <String, double>{};
    for (final inv in filteredInvestments) {
      projectInvestments[inv.proyectoId] =
          (projectInvestments[inv.proyectoId] ?? 0) + inv.monto;
    }

    // Recalculate total invested from filtered investments
    final totalInvested = projectInvestments.values.fold<double>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.tertiaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ranking de Proyectos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Sort indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getSortOptionLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...sortedProjects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            // Use filtered investment amount for this project
            final projectInvestedAmount = projectInvestments[project.id as String] ?? 0.0;
            final percentage = totalInvested > 0
                ? (projectInvestedAmount / totalInvested * 100)
                : 0.0;

            return _buildEnhancedProjectRankItem(
              rank: index + 1,
              project: project,
              projectInvestedAmount: projectInvestedAmount,
              percentage: percentage,
            );
          }),
        ],
      ),
    );
  }

  String _getSortOptionLabel() {
    switch (_sortOption) {
      case ProjectSortOption.totalAmount:
        return 'Por Monto Total';
      case ProjectSortOption.investorCount:
        return 'Por Inversores';
      case ProjectSortOption.averageAmount:
        return 'Por Promedio';
      case ProjectSortOption.lastInvestment:
        return 'Por Última Inversión';
    }
  }

  Widget _buildEnhancedProjectRankItem({
    required int rank,
    required dynamic project,
    required double projectInvestedAmount,
    required double percentage,
  }) {
    // Calculate investor count from filtered investments
    final investmentsState = ref.watch(investmentsManagementProvider);
    final filteredInvestments = _filterInvestmentsByProfile(investmentsState.investments);
    final investorCount = filteredInvestments
        .where((inv) => inv.proyectoId == project.id as String)
        .map((inv) => inv.usuarioId)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground.withOpacity( 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight.withOpacity( 0.3),
            ),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRankColor(rank),
                      _getRankColor(rank).withOpacity( 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getRankColor(rank).withOpacity( 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Project info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.nombre as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$investorCount inversores',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.category,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.temaNombre as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mini trend chart
              _buildMiniTrendChart(rank),

              const SizedBox(width: 16),

              // Amount and percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(projectInvestedAmount / 1000000).toStringAsFixed(1)}M',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTrendChart(int rank) {
    // Simulated trend data (would come from real historical data)
    final data = List.generate(5, (index) {
      final baseValue = 10 - rank;
      final variation = (index * 0.5) - 1.0;
      return (baseValue + variation).clamp(0.0, 10.0);
    });

    return SizedBox(
      width: 60,
      height: 40,
      child: CustomPaint(
        painter: _MiniTrendChartPainter(
          data: data,
          color: rank <= 3 ? _getRankColor(rank) : AppColors.textSecondary,
        ),
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

  Widget _buildGeneralStatisticsCharts(List<dynamic> projects) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.tertiaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Distribución y Tendencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              // Theme distribution pie chart
              Expanded(
                child: _buildThemeDistributionChart(projects),
              ),

              const SizedBox(width: 16),

              // Investment timeline
              Expanded(
                child: _buildInvestmentTimelineChart(projects),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeDistributionChart(List<dynamic> projects) {
    // Get filtered investments
    final investmentsState = ref.watch(investmentsManagementProvider);
    final filteredInvestments = _filterInvestmentsByProfile(investmentsState.investments);

    final themeData = <String, double>{};
    for (final inv in filteredInvestments) {
      themeData[inv.temaNombre] =
          (themeData[inv.temaNombre] ?? 0) + inv.monto;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución por Tema',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _PieChart(
            data: themeData,
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themeData.entries.map((entry) {
            final color = _getThemeColor(entry.key);
            final total = themeData.values.reduce((a, b) => a + b);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key} (${total > 0 ? ((entry.value / total) * 100).toStringAsFixed(0) : 0}%)',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getThemeColor(String theme) {
    // Generate consistent color from theme name
    final hash = theme.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  Widget _buildInvestmentTimelineChart(List<dynamic> projects) {
    // Get filtered investments
    final investmentsState = ref.watch(investmentsManagementProvider);
    final filteredInvestments = _filterInvestmentsByProfile(investmentsState.investments);

    // Group investments by date
    final investmentsByDate = <DateTime, double>{};
    for (final inv in filteredInvestments) {
      final date = DateTime(inv.fechaHora.year, inv.fechaHora.month, inv.fechaHora.day);
      investmentsByDate[date] = (investmentsByDate[date] ?? 0) + inv.monto;
    }

    // Create timeline data for the last 7 days
    final now = DateTime.now();
    final timelineData = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day - (6 - index));
      final amount = investmentsByDate[date] ?? 0.0;
      return {'date': date, 'amount': amount};
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evolución de Inversiones',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _LineChart(
            data: timelineData.cast<Map<String, dynamic>>(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Session? session) {
    final canReset = session?.estado == SessionState.ended ||
                    session?.estado == SessionState.paused;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackground,
              AppColors.cardBackground.withOpacity( 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? color.withOpacity( 0.3) : AppColors.borderLight.withOpacity( 0.3),
            width: 2,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity( 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled ? color.withOpacity( 0.2) : AppColors.textSecondary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color : AppColors.textSecondary.withOpacity( 0.3),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isEnabled ? null : AppColors.textSecondary.withOpacity( 0.5),
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
          ],
        ),
      ),
    );
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

  Widget _buildFullScreenControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity( 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.fullscreen_exit),
          tooltip: 'Salir de pantalla completa (Esc)',
          onPressed: () => setState(() => _isFullScreen = false),
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ==================== ROUND CONTROL METHODS ====================

  Future<void> _startRound() async {
    setState(() => _isSendingCommand = true);

    try {
      // Use local session methods when useLocalData is true
      if (AppConfig.useLocalData) {
        ref.read(sessionProvider.notifier).startSession();
      } else {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.startRound();
      }

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
      // Use local session methods when useLocalData is true
      if (AppConfig.useLocalData) {
        ref.read(sessionProvider.notifier).pauseSession();
      } else {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.pauseRound();
      }

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

  Future<void> _resumeRound() async {
    setState(() => _isSendingCommand = true);

    try {
      // Use local session methods when useLocalData is true
      if (AppConfig.useLocalData) {
        ref.read(sessionProvider.notifier).resumeSession();
      } else {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.startRound(); // WebSocket doesn't have separate resume
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ronda reanudada correctamente'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reanudar ronda: $e'),
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
        // Use local session methods when useLocalData is true
        if (AppConfig.useLocalData) {
          ref.read(sessionProvider.notifier).endSession();
        } else {
          final adminActions = ref.read(adminActionsProvider);
          await adminActions.endRound();
        }

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
        // Use local session methods when useLocalData is true
        if (AppConfig.useLocalData) {
          ref.read(sessionProvider.notifier).resetSession();
        } else {
          final adminActions = ref.read(adminActionsProvider);
          await adminActions.resetRound();
        }

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
      // Use local session methods when useLocalData is true
      if (AppConfig.useLocalData) {
        ref.read(sessionProvider.notifier).setSessionDuration(_roundDurationMinutes);
      } else {
        final adminActions = ref.read(adminActionsProvider);
        await adminActions.setRoundDuration(_roundDurationMinutes);
      }

      if (mounted) {
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
      print('Error al actualizar duración: $e');
    }
  }
}

// ==================== CUSTOM WIDGETS ====================

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularTimerPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final progressAngle = 2 * 3.14159 * progress;
    final startAngle = -3.14159 / 2; // Start from top

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _ProjectsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> projectsWithInvestments;
  final Function(dynamic) onBarTap;

  const _ProjectsBarChart({
    required this.projectsWithInvestments,
    required this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (projectsWithInvestments.isEmpty) {
      return const Center(
        child: Text(
          'No hay proyectos disponibles',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final maxValue = projectsWithInvestments.fold<double>(
      0,
      (sum, item) => sum + (item['investedAmount'] as double),
    );

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: projectsWithInvestments.length,
      itemBuilder: (context, index) {
        final item = projectsWithInvestments[index];
        final project = item['project'] as dynamic;
        final value = item['investedAmount'] as double;
        final height = maxValue > 0 ? (value / maxValue) * 200.0 : 0.0;
        final color = _getThemeColor(project.temaNombre as String);

        return GestureDetector(
          onTap: () => onBarTap(project),
          child: Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        color,
                        color.withOpacity( 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${(value / 1000000).toStringAsFixed(1)}M',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.nombre as String,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getThemeColor(String theme) {
    final hash = theme.hashCode;
    final hue = hash % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.5).toColor();
  }
}

class _MiniTrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniTrendChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / (range > 0 ? range : 1);
      final y = size.height - (normalizedValue * size.height * 0.8) - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / (range > 0 ? range : 1);
      final y = size.height - (normalizedValue * size.height * 0.8) - size.height * 0.1;

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniTrendChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, double> data;

  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final total = data.values.fold<double>(0.0, (sum, value) => sum + value);
    final entries = data.entries.toList();

    return CustomPaint(
      size: const Size(200, 200),
      painter: _PieChartPainter(
        data: entries,
        total: total,
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;

  _PieChartPainter({
    required this.data,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    double startAngle = 0;

    for (final entry in data) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      final color = _getThemeColor(entry.key);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  Color _getThemeColor(String theme) {
    final hash = theme.hashCode;
    final hue = hash % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.5).toColor();
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _LineChartPainter(data: data),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryAccent.withOpacity( 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i]['amount'] as double) / maxValue;
      final y = size.height - (normalizedValue * size.height * 0.8) - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i]['amount'] as double) / maxValue;
      final y = size.height - (normalizedValue * size.height * 0.8) - size.height * 0.1;

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = AppColors.primaryAccent,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class FullScreenMode extends StatelessWidget {
  final Widget child;
  final VoidCallback onExit;

  const FullScreenMode({
    required this.child,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: child,
    );
  }
}

class EmojiPicker {
  IconData getEmojiForTheme(String theme) {
    // Return appropriate icon based on theme
    return Icons.emoji_events_outlined;
  }
}

// ==================== ENUMS AND HELPERS ====================

enum ProjectSortOption {
  totalAmount,
  investorCount,
  averageAmount,
  lastInvestment,
}

class _ShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutItem(this.shortcut, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tertiaryBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
