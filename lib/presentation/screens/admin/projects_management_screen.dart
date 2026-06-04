import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/project.dart';
import '../../providers/projects_management_provider.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/admin/project_form_dialog.dart';
import '../../widgets/admin/project_delete_dialog.dart';
import '../../widgets/admin/project_info_dialog.dart';

class ProjectsManagementScreen extends ConsumerStatefulWidget {
  const ProjectsManagementScreen({super.key});

  @override
  ConsumerState<ProjectsManagementScreen> createState() => _ProjectsManagementScreenState();
}

class _ProjectsManagementScreenState extends ConsumerState<ProjectsManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final filteredProjects = ref.read(filteredProjectsProvider);
      final totalPages = (filteredProjects.length / _pageSize).ceil();
      if (_currentPage < totalPages - 1) {
        setState(() {
          _currentPage++;
        });
      }
    }
  }

  Future<void> _showCreateProjectDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ProjectFormDialog(),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showEditProjectDialog(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProjectFormDialog(project: project),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteProjectDialog(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProjectDeleteDialog(project: project),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto eliminado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showProjectInfoDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectInfoDialog(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsManagementProvider);
    final temaFilter = ref.watch(projectTemaFilterProvider);
    final statusFilter = ref.watch(projectStatusFilterProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final themes = ref.watch(themesManagementProvider);

    final paginatedProjects = filteredProjects
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
          tooltip: 'Volver',
        ),
        title: const Text(
          'Gestión de Proyectos',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Filtros y búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.secondaryBackground,
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar proyecto por nombre...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (value) {
                    ref.read(projectSearchQueryProvider.notifier).state = value;
                    setState(() {
                      _currentPage = 0;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filtros
                Row(
                  children: [
                    // Dropdown de temas
                    Expanded(
                      child: themes.maybeWhen(
                        data: (themesList) => DropdownButtonFormField<String>(
                          initialValue: temaFilter.isEmpty ? null : temaFilter,
                          decoration: InputDecoration(
                            labelText: 'Filtrar por tema',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.tertiaryBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: AppColors.tertiaryBackground,
                          style: const TextStyle(color: AppColors.textPrimary),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Todos los temas'),
                            ),
                            ...themesList.map((theme) {
                              return DropdownMenuItem(
                                value: theme.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(theme.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(theme.nombre),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            ref.read(projectTemaFilterProvider.notifier).state = value ?? '';
                            setState(() {
                              _currentPage = 0;
                            });
                          },
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Toggle de estado
                    Expanded(
                      child: DropdownButtonFormField<ProjectFilterStatus>(
                        initialValue: statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.tertiaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: AppColors.tertiaryBackground,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(
                            value: ProjectFilterStatus.all,
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: ProjectFilterStatus.active,
                            child: Text('Activos'),
                          ),
                          DropdownMenuItem(
                            value: ProjectFilterStatus.inactive,
                            child: Text('Inactivos'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(projectStatusFilterProvider.notifier).state = value;
                            setState(() {
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de proyectos
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  )
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.error!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  ref.read(projectsManagementProvider.notifier).loadProjects(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                              ),
                              child: const Text(
                                'Reintentar',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : paginatedProjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  color: AppColors.textSecondary,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay proyectos que coincidan con los filtros',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: paginatedProjects.length + (filteredProjects.length > (_currentPage + 1) * _pageSize ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= paginatedProjects.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                                  ),
                                );
                              }

                              final project = paginatedProjects[index];
                              return _buildProjectCard(project);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectDialog,
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final temaColor = _hexToColor(project.temaColor ?? '#00D4AA');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProjectInfoDialog(project),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del proyecto
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: temaColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        image: project.imagen != null && project.imagen!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(project.imagen!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: project.imagen == null || project.imagen!.isEmpty
                          ? Icon(
                              Icons.business_center,
                              color: temaColor,
                              size: 40,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Información del proyecto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.nombre,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: project.activo
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      project.activo ? Icons.check_circle : Icons.cancel,
                                      color: project.activo ? AppColors.success : AppColors.error,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      project.activo ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        color: project.activo ? AppColors.success : AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Tema con color
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: temaColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                project.temaNombre,
                                style: TextStyle(
                                  color: temaColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Estadísticas
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${(project.totalInvertido).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.people,
                                color: AppColors.primaryAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${project.numeroInversores} inversor${project.numeroInversores == 1 ? '' : 'es'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Participantes
                if (project.participantes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...project.participantes.take(5).map((participante) {
                        final nombre = participante['nombre'] ?? '';
                        final iniciales = nombre.isNotEmpty
                            ? nombre.split(' ').map((n) => n[0]).take(2).join()
                            : '?';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: temaColor.withOpacity(0.3),
                            child: Text(
                              iniciales,
                              style: TextStyle(
                                color: temaColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      if (project.participantes.length > 5)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.tertiaryBackground,
                          child: Text(
                            '+${project.participantes.length - 5}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Botones de acción
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showProjectInfoDialog(project),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Ver'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditProjectDialog(project),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryAccent),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteProjectDialog(project),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
