import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/theme.dart';
import '../../providers/project_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/search_bar.dart' as custom;
import '../../widgets/cards/category_card.dart';
import '../../widgets/cards/project_card.dart';
import '../../widgets/menu/menu_widgets.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  final String? themeId;

  const ProjectsListScreen({
    super.key,
    this.themeId,
  });

  @override
  ConsumerState<ProjectsListScreen> createState() =>
      _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  String? _selectedThemeId;
  bool _isGridView = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.themeId;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onClearSearch() {
    setState(() {
      _searchQuery = '';
    });
  }

  bool _matchesAnyParticipant(List<Map<String, String>> participantes, String query) {
    if (query.isEmpty) return true;

    return participantes.any((participante) {
      final name = participante['name'] ?? '';
      return name.toLowerCase().contains(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final themesState = ref.watch(themesProvider);

    final projects = projectsState.value ?? [];
    final themes = themesState.value ?? [];

    // Filter by theme and search query
    var filteredProjects = projects.where((p) {
      bool matchesTheme = _selectedThemeId == null || p.temaId == _selectedThemeId;
      bool matchesSearch = _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery) ||
          p.descripcion.toLowerCase().contains(_searchQuery) ||
          p.temaNombre.toLowerCase().contains(_searchQuery) ||
          _matchesAnyParticipant(p.participantes, _searchQuery);
      return matchesTheme && matchesSearch;
    }).toList();

    // Sort by total invested descending
    filteredProjects.sort((a, b) => b.totalInvertido.compareTo(a.totalInvertido));

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          title: const Text(AppStrings.projects),
          actions: [
          // View Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          ),
        ],
      ),
        body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: custom.AppSearchBar(
              hintText: 'Buscar por nombre, tema o participante...',
              onSearch: _onSearchChanged,
              onClear: _onClearSearch,
            ),
          ),

          // Categories Filter
          _buildCategoriesFilter(themes),

          const Divider(height: 1),

          // Projects
          Expanded(
            child: _buildProjectsContent(filteredProjects, projectsState),
          ),
        ],
      ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      ),
    );
  }

  Widget _buildCategoriesFilter(List<dynamic> themes) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: themes.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 140,
                child: CategoryCard(
                  theme: const InvestmentTheme(
                    id: '',
                    nombre: 'Todos',
                    color: '#FFFFFF',
                    icon: 'grid_view',
                    numeroProyectos: 0,
                    totalInvertido: 0,
                  ),
                  isSelected: _selectedThemeId == null,
                  onTap: () {
                    setState(() {
                      _selectedThemeId = null;
                    });
                  },
                ),
              ),
            );
          }

          final theme = themes[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 140,
              child: CategoryCard(
                theme: theme,
                isSelected: _selectedThemeId == theme.id,
                onTap: () {
                  setState(() {
                    _selectedThemeId = _selectedThemeId == theme.id ? null : theme.id;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectsContent(List<dynamic> projects, AsyncValue state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.error,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(projectsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      );
    }

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noData,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return _buildProjectsGrid(projects);
    } else {
      return _buildProjectsList(projects);
    }
  }

  Widget _buildProjectsList(List<dynamic> projects) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProjectCard(
            project: project,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.projectDetail,
                arguments: project.id,
              );
            },
            onReadMore: () {
              Navigator.of(context).pushNamed(
                AppRoutes.projectDetail,
                arguments: project.id,
              );
            },
            onInvest: () {
              Navigator.of(context).pushNamed(
                AppRoutes.projectDetail,
                arguments: project.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectsGrid(List<dynamic> projects) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          project: project,
          showInvestButton: false,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.projectDetail,
              arguments: project.id,
            );
          },
        );
      },
    );
  }
}
