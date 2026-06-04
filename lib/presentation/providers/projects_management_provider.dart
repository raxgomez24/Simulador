import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/repositories/project_repository_local.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import 'admin_provider.dart';
import 'project_provider.dart';
import '../../app/config.dart';

enum ProjectFilterStatus {
  all,
  active,
  inactive,
}

class ProjectsManagementState {
  final List<Project> projects;
  final bool isLoading;
  final String? error;

  const ProjectsManagementState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  ProjectsManagementState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? error,
  }) {
    return ProjectsManagementState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProjectsManagementNotifier extends StateNotifier<ProjectsManagementState> {
  late ProjectRepository _repository;
  final AdminActions _adminActions;

  ProjectsManagementNotifier(this._adminActions) : super(const ProjectsManagementState()) {
    _initializeRepository();
    loadProjects();
  }

  void _initializeRepository() {
    // En web, no usar repositorio local (no SQLite disponible)
    if (AppConfig.isWeb || !AppConfig.useLocalData) {
      final dataSource = WebSocketDataSource();
      _repository = ProjectRepositoryImpl(dataSource);
    } else {
      _repository = ProjectRepositoryLocal();
    }
  }

  Future<void> loadProjects() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final projects = await _repository.getProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<Project> getFilteredProjects({
    String? searchQuery,
    String? temaId,
    ProjectFilterStatus statusFilter = ProjectFilterStatus.all,
  }) {
    var filtered = state.projects;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) => p.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (temaId != null && temaId.isNotEmpty) {
      filtered = filtered.where((p) => p.temaId == temaId).toList();
    }

    switch (statusFilter) {
      case ProjectFilterStatus.active:
        filtered = filtered.where((p) => p.activo).toList();
        break;
      case ProjectFilterStatus.inactive:
        filtered = filtered.where((p) => !p.activo).toList();
        break;
      case ProjectFilterStatus.all:
        break;
    }

    return filtered;
  }

  Future<void> createProject({
    required String titulo,
    required String descripcion,
    required String temaId,
    required String temaNombre,
    required String temaColor,
    String imagen = '',
    String pitch = '',
    String problema = '',
    String solucion = '',
    String estrategiaIngresos = '',
    String proyeccionFinanciera = '',
    List<Map<String, String>> participantes = const [],
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _repository.createProject(
          titulo: titulo,
          descripcion: descripcion,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          imagen: imagen,
          pitch: pitch,
          problema: problema,
          solucion: solucion,
          estrategiaIngresos: estrategiaIngresos,
          proyeccionFinanciera: proyeccionFinanciera,
          participantes: participantes,
          orden: orden,
          activo: activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.createProject(
          titulo: titulo,
          descripcion: descripcion,
          temaId: temaId,
          temaNombre: temaNombre,
          temaColor: temaColor,
          imagen: imagen,
          pitch: pitch,
          problema: problema,
          solucion: solucion,
          estrategiaIngresos: estrategiaIngresos,
          proyeccionFinanciera: proyeccionFinanciera,
          participantes: participantes,
        );
      }
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      throw Exception(e.toString());
    }
  }

  Future<void> updateProject({
    required String id,
    required String titulo,
    required String descripcion,
    String imagen = '',
    bool activo = true,
    String pitch = '',
    String problema = '',
    String solucion = '',
    String estrategiaIngresos = '',
    String proyeccionFinanciera = '',
    List<Map<String, String>> participantes = const [],
    int orden = 0,
  }) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _repository.updateProject(
          id: id,
          titulo: titulo,
          descripcion: descripcion,
          imagen: imagen,
          activo: activo,
          pitch: pitch,
          problema: problema,
          solucion: solucion,
          estrategiaIngresos: estrategiaIngresos,
          proyeccionFinanciera: proyeccionFinanciera,
          participantes: participantes,
          orden: orden,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.updateProject(
          id: id,
          titulo: titulo,
          descripcion: descripcion,
          imagen: imagen,
          activo: activo,
        );
      }
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      throw Exception(e.toString());
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _repository.deleteProject(projectId);
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.deleteProject(projectId);
      }
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      throw Exception(e.toString());
    }
  }

  List<Project> getActiveProjectsSortedByInvestment() {
    return state.projects
        .where((p) => p.activo)
        .toList()
      ..sort((a, b) => b.totalInvertido.compareTo(a.totalInvertido));
  }

  Future<bool> projectNameExists(String nombre, {String? excludeId}) async {
    try {
      return await _repository.projectNameExists(nombre, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }
}

final projectsManagementProvider =
    StateNotifierProvider<ProjectsManagementNotifier, ProjectsManagementState>(
  (ref) {
    final adminActions = ref.read(adminActionsProvider);
    return ProjectsManagementNotifier(adminActions);
  },
);

final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final searchQuery = ref.watch(projectSearchQueryProvider);
  final temaFilter = ref.watch(projectTemaFilterProvider);
  final statusFilter = ref.watch(projectStatusFilterProvider);

  return ref
      .read(projectsManagementProvider.notifier)
      .getFilteredProjects(
        searchQuery: searchQuery,
        temaId: temaFilter,
        statusFilter: statusFilter,
      );
});

final activeProjectsSortedProvider = Provider<List<Project>>((ref) {
  return ref.read(projectsManagementProvider.notifier).getActiveProjectsSortedByInvestment();
});

final projectSearchQueryProvider = StateProvider<String>((ref) => '');
final projectTemaFilterProvider = StateProvider<String>((ref) => '');
final projectStatusFilterProvider = StateProvider<ProjectFilterStatus>((ref) => ProjectFilterStatus.all);
