import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/timer_badge.dart';
import '../../widgets/cards/category_card.dart';
import '../../widgets/cards/project_card.dart';
import '../../widgets/menu/menu_widgets.dart';
import '../projects/projects_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers
    ref.read(projectsProvider.notifier);
    ref.read(themesProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final projectsState = ref.watch(projectsProvider);
    final themesState = ref.watch(themesProvider);
    final sessionState = ref.watch(sessionProvider);

    final user = authState.value;
    final projects = projectsState.value ?? [];
    final themes = themesState.value ?? [];
    final session = sessionState.value;

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryAccent,
                      AppColors.secondaryAccent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfo(user),
                        const Spacer(),
                        _buildBalance(user),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session Timer
                  _buildSessionTimer(session),

                  const SizedBox(height: 24),

                  // Categories Section
                  _buildSectionHeader(
                    title: AppStrings.categories,
                    action: AppStrings.viewAll,
                    onActionPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProjectsListScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Categories Grid
                  _buildCategoriesGrid(themes),

                  const SizedBox(height: 24),

                  // Featured Projects Section
                  _buildSectionHeader(
                    title: 'Proyectos Destacados',
                    action: AppStrings.viewAll,
                    onActionPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProjectsListScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Projects List
                  _buildProjectsList(projects.take(3).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    ));
  }

  Widget _buildUserInfo(User? user) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity( 0.2),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Text(
              user?.initials ?? '??',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.nombre ?? 'Usuario'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                user?.username ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity( 0.8),
                ),
              ),
            ],
          ),
        ),
        // Logout Button
        IconButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          icon: const Icon(Icons.logout, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBalance(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.balance,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity( 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(user?.saldo ?? 0),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionTimer(Session? session) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: TimerBadge(session: session),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String action,
    required VoidCallback onActionPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onActionPressed,
          child: Text(
            action,
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(List<dynamic> themes) {
    if (themes.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.noData,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 140,
              child: CategoryCard(
                theme: theme,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProjectsListScreen(
                        themeId: theme.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectsList(List<dynamic> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            AppStrings.noData,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProjectCard(
            project: project,
            onTap: () {
              // Navigate to project detail
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProjectsListScreen(),
                ),
              );
            },
            onReadMore: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProjectsListScreen(
                    themeId: project.temaId,
                  ),
                ),
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
}
