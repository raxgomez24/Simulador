import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/user.dart';
import '../../providers/project_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/charts/investment_bar_chart.dart';

/// Dashboard de proyección para pantallas grandes
/// Optimizado para eventos MBA con visualización en tiempo real
class ProjectionDashboardScreen extends ConsumerStatefulWidget {
  const ProjectionDashboardScreen({super.key});

  @override
  ConsumerState<ProjectionDashboardScreen> createState() =>
      _ProjectionDashboardScreenState();
}

class _ProjectionDashboardScreenState
    extends ConsumerState<ProjectionDashboardScreen> {
  int _selectedTimeRange = 0; // 0: All, 1: Last 5 min, 2: Last 10 min
  String? _selectedThemeId;
  UserRole? _selectedPerfil;

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final projects = projectsState.value ?? [];

    final sessionState = ref.watch(sessionProvider);
    final session = sessionState.value;

    final authState = ref.watch(authProvider);
    final user = authState.value;

    final investmentsState = user != null
        ? ref.watch(investmentsProvider(user.id))
        : const AsyncValue.data([]);
    final investments = investmentsState.value ?? [];

    final isRoundActive = session?.estado == SessionState.active;
    final isRoundPaused = session?.estado == SessionState.paused;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBackground,
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Sidebar
              _buildSidebar(user),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Header with back button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios),
                            tooltip: 'Volver',
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Dashboard de Proyección',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Header
                    _buildHeader(session, isRoundActive, isRoundPaused),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Stats Row
                            _buildStatsRow(projects, session, investments),
                            const SizedBox(height: 24),
                            // Charts Row
                            Expanded(
                              child: Row(
                                children: [
                                  // Investment by Theme Chart
                                  Expanded(
                                    flex: 2,
                                    child: _buildInvestmentByThemeChart(
                                      projects,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Investment Bar Chart (Vertical Bars)
                                  Expanded(
                                    child: InvestmentBarChart(
                                      projects: projects,
                                      maxBars: 10,
                                      title: 'Top Proyectos',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Recent Activity
                            Expanded(
                              child: _buildRecentActivity(investments),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(user) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          right: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryAccent,
                        AppColors.secondaryAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Amerike MBA 2026',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Dashboard de Proyección',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // User Info
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryAccent,
                    child: Text(
                      user.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
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
                          user.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.perfil,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          const Spacer(),
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildThemeFilter(),
                const SizedBox(height: 12),
                _buildPerfilFilter(),
                const SizedBox(height: 12),
                _buildClearFiltersButton(),
              ],
            ),
          ),
          const Divider(),
          // Time Range Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rango de tiempo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimeRangeSelector(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Column(
      children: [
        _buildTimeRangeButton('Todo el tiempo', 0),
        const SizedBox(height: 8),
        _buildTimeRangeButton('Últimos 5 min', 1),
        const SizedBox(height: 8),
        _buildTimeRangeButton('Últimos 10 min', 2),
      ],
    );
  }

  Widget _buildTimeRangeButton(String label, int index) {
    final isSelected = _selectedTimeRange == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeRange = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? AppColors.primaryAccent
                : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeFilter() {
    final projectsState = ref.watch(projectsProvider);
    final projects = projectsState.value ?? [];

    // Get unique themes from projects
    final uniqueThemes = <String, String>{};
    for (var project in projects) {
      uniqueThemes[project.temaId] = project.temaNombre;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por Tema',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedThemeId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.tertiaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: AppColors.secondaryBackground,
          hint: const Text(
            'Todos los temas',
            style: TextStyle(fontSize: 12),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Todos los temas',
                style: TextStyle(fontSize: 12),
              ),
            ),
            ...uniqueThemes.entries.map((entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedThemeId = value;
            });
          },
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPerfilFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por Perfil',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<UserRole?>(
          value: _selectedPerfil,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.tertiaryBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: AppColors.secondaryBackground,
          hint: const Text(
            'Todos los perfiles',
            style: TextStyle(fontSize: 12),
          ),
          items: [
            const DropdownMenuItem<UserRole?>(
              value: null,
              child: Text(
                'Todos los perfiles',
                style: TextStyle(fontSize: 12),
              ),
            ),
            ...UserRole.values.map((perfil) => DropdownMenuItem<UserRole?>(
                  value: perfil,
                  child: Text(
                    User.perfilToString(perfil),
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPerfil = value;
            });
          },
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClearFiltersButton() {
    final hasFilters = _selectedThemeId != null || _selectedPerfil != null;
    if (!hasFilters) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () {
        setState(() {
          _selectedThemeId = null;
          _selectedPerfil = null;
        });
      },
      icon: const Icon(Icons.clear, size: 14),
      label: const Text(
        'Limpiar filtros',
        style: TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildHeader(Session? session, bool isRoundActive, bool isRoundPaused) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          // Timer
          if (session != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withOpacity(0.1),
                    AppColors.secondaryAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryAccent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRoundActive && !isRoundPaused ? Icons.timer : Icons.timer_off,
                    color: isRoundActive && !isRoundPaused
                        ? AppColors.primaryAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiempo restante',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        Formatters.formatDuration(session.tiempoRestante),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Status
          if (session != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getSessionStatusColor(session.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSessionStatusColor(session.estado).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getSessionStatusColor(session.estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSessionStatusText(session.estado),
                    style: TextStyle(
                      color: _getSessionStatusColor(session.estado),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    List<dynamic> projects,
    Session? session,
    List<dynamic> investments,
  ) {
    final totalInvested = projects.fold<double>(
      0,
      (sum, p) => sum + (p.totalInvertido as double),
    );
    final totalInvestors = projects.fold<int>(
      0,
      (sum, p) => sum + (p.numeroInversores as int),
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.business_center,
            label: 'Proyectos',
            value: projects.length.toString(),
            color: AppColors.primaryAccent,
            trend: '+${session?.numeroProyectos ?? 0}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Inversores',
            value: totalInvestors.toString(),
            color: AppColors.secondaryAccent,
            trend: '+${session?.numeroParticipantes ?? 0}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.account_balance_wallet,
            label: 'Total Invertido',
            value: '\$${(totalInvested / 1000000).toStringAsFixed(1)}M',
            color: AppColors.success,
            trend: (session?.totalInvertido ?? 0) > 0 ? 'Inversión activa' : '0',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.show_chart,
            label: 'Promedio por inversor',
            value: totalInvestors > 0
                ? '\$${(totalInvested / totalInvestors / 1000000).toStringAsFixed(2)}M'
                : '\$0',
            color: AppColors.warning,
            trend: totalInvestors > 0 ? 'Promedio calculado' : 'Sin datos',
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
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentByThemeChart(List<dynamic> projects) {
    // Group investments by theme
    final themeData = <String, double>{};
    for (var project in projects) {
      final themeName = project.temaNombre as String;
      final invested = project.totalInvertido as double;
      if (themeData.containsKey(themeName)) {
        themeData[themeName] = themeData[themeName]! + invested;
      } else {
        themeData[themeName] = invested;
      }
    }

    final sortedThemes = themeData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalInvested = themeData.values.fold<double>(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Inversión por Tema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Total: \$${(totalInvested / 1000000).toStringAsFixed(1)}M',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sortedThemes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final themeEntry = entry.value;
                  final percentage = themeEntry.value / totalInvested;
                  return PieChartSectionData(
                    value: themeEntry.value,
                    title: '${(percentage * 100).toStringAsFixed(1)}%',
                    color: _getThemeColor(index),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sortedThemes.take(6).map((themeEntry) {
              final percentage = themeEntry.value / totalInvested;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getThemeColor(sortedThemes.indexOf(themeEntry)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${themeEntry.key}: ${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getThemeColor(int index) {
    final colors = [
      AppColors.primaryAccent,
      AppColors.secondaryAccent,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
      const Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  Widget _buildTopProjectsList(List<dynamic> projects) {
    final sortedProjects = List<dynamic>.from(projects);
    sortedProjects.sort(
      (a, b) => (b.totalInvertido as double).compareTo(a.totalInvertido as double),
    );
    final topProjects = sortedProjects.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Text(
                'Top 10 Proyectos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: topProjects.length,
              itemBuilder: (context, index) {
                final project = topProjects[index];
                return _buildProjectListItem(index + 1, project);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectListItem(int rank, dynamic project) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.nombre as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  project.temaNombre as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${((project.totalInvertido as double) / 1000000).toStringAsFixed(2)}M',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryAccent,
                ),
              ),
              Text(
                '${project.numeroInversores} inversores',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.tertiaryBackground;
    }
  }

  Widget _buildRecentActivity(List<dynamic> investments) {
    final sortedInvestments = List<dynamic>.from(investments);
    sortedInvestments.sort(
      (a, b) => b.fechaHora.compareTo(a.fechaHora),
    );
    final recentInvestments = sortedInvestments.take(20).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: AppColors.secondaryAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${recentInvestments.length} inversiones',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recentInvestments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sin actividad reciente',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemCount: recentInvestments.length,
                    itemBuilder: (context, index) {
                      final investment = recentInvestments[index];
                      return _buildInvestmentItem(investment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentItem(dynamic investment) {
    final timeAgo = DateTime.now().difference(investment.fechaHora);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryAccent,
                  AppColors.secondaryAccent,
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(
              child: Text(
                (investment.usuarioNombre as String).substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      investment.usuarioNombre as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        investment.perfilUsuario as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'invirtió en ${investment.proyectoNombre}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${((investment.monto as double) / 1000000).toStringAsFixed(2)}M',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.success,
                ),
              ),
              Text(
                _formatTimeAgo(timeAgo),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inSeconds < 60) {
      return 'hace ${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return 'hace ${duration.inMinutes}m';
    } else {
      return 'hace ${duration.inHours}h';
    }
  }

  String _getSessionStatusText(SessionState estado) {
    switch (estado) {
      case SessionState.waiting:
        return 'Esperando';
      case SessionState.active:
        return 'En curso';
      case SessionState.paused:
        return 'Pausada';
      case SessionState.ended:
        return 'Finalizada';
    }
  }

  Color _getSessionStatusColor(SessionState estado) {
    switch (estado) {
      case SessionState.waiting:
        return AppColors.textSecondary;
      case SessionState.active:
        return AppColors.success;
      case SessionState.paused:
        return AppColors.warning;
      case SessionState.ended:
        return AppColors.error;
    }
  }
}
