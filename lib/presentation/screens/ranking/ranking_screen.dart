import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/project_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/connection_indicator.dart';
import '../../widgets/menu/menu_widgets.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  String? _selectedThemeId;
  String? _selectedProfile;

  // Track previous positions of projects for movement indicators
  Map<String, int> _previousRanks = {};

  final List<String> _profiles = [
    'Todos',
    'Alumno',
    'Docente',
    'Administrativo',
    'Invitado',
    'Inversionista',
  ];

  @override
  void initState() {
    super.initState();
    _previousRanks = {};
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final themesState = ref.watch(themesProvider);

    final projects = projectsState.value ?? [];
    final themes = themesState.value ?? [];

    final filteredProjects = _filterProjects(projects);

    // Update previous ranks for movement indicators
    _updatePreviousRanks(filteredProjects);

    // Calculate metrics
    final totalInvested = projects.fold<double>(
      0,
      (sum, p) => sum + p.totalInvertido,
    );
    final totalInvestors = projects.fold<int>(
      0,
      (sum, p) => sum + p.numeroInversores,
    );
    final topProject = projects.isNotEmpty
        ? projects.reduce((a, b) => a.totalInvertido > b.totalInvertido ? a : b)
        : null;

    // Detect screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 768; // Tablet/Desktop breakpoint

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          title: const Text(AppStrings.ranking),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: ConnectionIndicator(),
            ),
          ],
        ),
        body: Column(
        children: [
          // Metrics Cards
          _buildMetricsCards(
            totalInvested: totalInvested,
            totalProjects: projects.length,
            totalInvestors: totalInvestors,
            topProject: topProject,
          ),

          const SizedBox(height: 16),

          // Filters
          _buildFilters(themes),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: projectsState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  )
                : projectsState.hasError
                    ? _buildErrorState(projectsState.error.toString())
                    : filteredProjects.isEmpty
                        ? _buildEmptyState()
                        : isLargeScreen
                            ? _buildLargeScreenLayout(filteredProjects)
                            : _buildMobileLayout(filteredProjects),
          ),
        ],
      ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      ),
    );
  }

  List<Project> _filterProjects(List<Project> projects) {
    var filtered = projects;

    if (_selectedThemeId != null) {
      filtered = filtered.where((p) => p.temaId == _selectedThemeId).toList();
    }

    // Sort by total invested descending
    filtered.sort((a, b) => b.totalInvertido.compareTo(a.totalInvertido));

    return filtered;
  }

  // Update previous ranks for movement tracking
  void _updatePreviousRanks(List<Project> projects) {
    // Create a new map to avoid modifying while iterating
    final newPreviousRanks = Map<String, int>.from(_previousRanks);

    // Update current positions
    for (int i = 0; i < projects.length; i++) {
      final project = projects[i];
      final currentRank = i + 1;
      newPreviousRanks[project.id] = currentRank;
    }

    // Remove projects that are no longer in the list
    final currentProjectIds = projects.map((p) => p.id).toSet();
    newPreviousRanks.removeWhere((key, value) => !currentProjectIds.contains(key));

    setState(() {
      _previousRanks = newPreviousRanks;
    });
  }

  // Calculate movement for a project
  // Returns positive value if moved up (better position), negative if moved down
  int _calculateMovement(String projectId, int currentRank) {
    final previousRank = _previousRanks[projectId];
    if (previousRank == null) {
      return 0; // New project, no movement to show
    }
    return previousRank - currentRank;
  }

  // Build movement indicator widget
  Widget _buildMovementIndicator(int movement) {
    if (movement == 0) {
      // No change
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey,
        ),
      );
    } else if (movement > 0) {
      // Moved UP (positive movement means better rank)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_upward,
                  color: Color(0xFF10B981),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '$movement',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Moved DOWN (negative movement means worse rank)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_downward,
                  color: Color(0xFFEF4444),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${movement.abs()}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Build compact movement indicator for grid view
  Widget _buildCompactMovementIndicator(int movement) {
    if (movement == 0) {
      return const SizedBox.shrink();
    } else if (movement > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Color(0xFF10B981),
          size: 8,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.arrow_downward,
          color: Color(0xFFEF4444),
          size: 8,
        ),
      );
    }
  }

  Widget _buildMetricsCards({
    required double totalInvested,
    required int totalProjects,
    required int totalInvestors,
    required Project? topProject,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.account_balance_wallet,
              label: 'Total Invertido',
              value: Formatters.formatCurrency(totalInvested),
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.business_center,
              label: 'Proyectos',
              value: totalProjects.toString(),
              color: AppColors.secondaryAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people,
              label: 'Inversores',
              value: totalInvestors.toString(),
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<InvestmentTheme> themes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Filter
          const Text(
            'Filtrar por Categoría',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: themes.length + 1,
              itemBuilder: (context, index) {
                final isSelected = index == 0
                    ? _selectedThemeId == null
                    : _selectedThemeId == themes[index - 1].id;

                return Padding(
                  padding: EdgeInsets.only(
                    right: 8,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: FilterChip(
                    label: Text(
                      index == 0 ? 'Todas' : themes[index - 1].nombre,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (index == 0) {
                          _selectedThemeId = null;
                        } else {
                          _selectedThemeId = selected
                              ? themes[index - 1].id
                              : null;
                        }
                      });
                    },
                    selectedColor: AppColors.primaryAccent,
                    backgroundColor: AppColors.tertiaryBackground,
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Profile Filter
          const Text(
            'Filtrar por Perfil',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                final isSelected = _selectedProfile == (index == 0 ? null : profile);

                return Padding(
                  padding: EdgeInsets.only(
                    right: 8,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: FilterChip(
                    label: Text(
                      profile,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedProfile = selected
                            ? (index == 0 ? null : profile)
                            : null;
                      });
                    },
                    selectedColor: AppColors.secondaryAccent,
                    backgroundColor: AppColors.tertiaryBackground,
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<Project> projects) {
    return _buildRankingList(projects);
  }

  Widget _buildLargeScreenLayout(List<Project> projects) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Horizontal bar chart (40%)
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gráfica de Ranking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildHorizontalBarChart(projects),
                ),
              ],
            ),
          ),
        ),
        // Right side: Project cards (60%)
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proyectos Destacados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildProjectsGrid(projects),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBarChart(List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Text(
          'No hay proyectos para mostrar',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final maxAmount = projects.first.totalInvertido;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: projects.asMap().entries.map((entry) {
          final index = entry.key;
          final project = entry.value;
          final isTopThree = index < 3;
          final rank = index + 1;
          final percentage = maxAmount > 0 ? (project.totalInvertido / maxAmount) * 100 : 0;
          final themeColor = _parseColor(project.temaColor ?? '#00D4AA');

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isTopThree ? themeColor : AppColors.tertiaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTopThree ? themeColor : AppColors.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: isTopThree ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Movement indicator
                    _buildMovementIndicator(_calculateMovement(project.id, rank)),
                    const SizedBox(width: 12),
                    // Project name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    ),
                    // Amount
                    Text(
                      Formatters.formatCompactNumber(project.totalInvertido),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor,
                                themeColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectsGrid(List<Project> projects) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columnas para hacer las tarjetas mucho más pequeñas
        childAspectRatio: 0.6, // Más bajas (menor valor = menos alto)
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final isTopThree = index < 3;
        final rank = index + 1;
        final themeColor = _parseColor(project.temaColor ?? '#00D4AA');

        return Container(
          decoration: BoxDecoration(
            color: isTopThree
                ? AppColors.cardBackground
                : AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isTopThree ? themeColor : AppColors.borderLight,
              width: isTopThree ? 1 : 0.3,
            ),
            boxShadow: isTopThree
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rank badge y tema en una fila
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeColor,
                            themeColor.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    // Subtle movement indicator for grid
                    _buildCompactMovementIndicator(_calculateMovement(project.id, rank)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        project.temaNombre,
                        style: TextStyle(
                          fontSize: 8,
                          color: themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Project name
                Text(
                  project.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Stats en una fila compacta
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: 10,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${project.numeroInversores}',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        Formatters.formatCompactNumber(project.totalInvertido),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingList(List<Project> projects) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final isTopThree = index < 3;
        final rank = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isTopThree
                ? AppColors.cardBackground
                : AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTopThree
                  ? _parseColor(project.temaColor ?? '#00D4AA')
                  : AppColors.borderLight,
              width: isTopThree ? 2 : 1,
            ),
            boxShadow: isTopThree
                ? [
                    BoxShadow(
                      color: _parseColor(project.temaColor ?? '#00D4AA')
                          .withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Movement indicator
                _buildMovementIndicator(_calculateMovement(project.id, rank)),
                const SizedBox(width: 8),
                // Rank badge
                _buildRankBadge(rank, isTopThree, project.temaColor),
              ],
            ),
            title: Text(
              project.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  project.temaNombre,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${project.numeroInversores} inversores',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(project.totalInvertido),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _parseColor(project.temaColor ?? '#00D4AA'),
                  ),
                ),
                const Text(
                  'invertido',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank, bool isTopThree, String? color) {
    final badgeColor = _parseColor(color ?? '#00D4AA');

    if (isTopThree) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              badgeColor,
              badgeColor.withValues(alpha: 0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(projectsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay proyectos en el ranking',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }
}
