import '../../domain/entities/project.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/theme_model.dart';
import '../mock/mock_data.dart';

/// Repositorio de proyectos para Web (sin SQLite ni WebSocket)
/// Usa los datos mock de mock_data.dart
class ProjectRepositoryWeb implements ProjectRepository {
  final List<Project> _cachedProjects = [];
  final List<InvestmentTheme> _cachedThemes = [];

  ProjectRepositoryWeb() {
    // Inicializar cache con datos mock
    _cachedProjects.addAll(getProcessedProjects().map((m) => m.toEntity()).toList());
    _cachedThemes.addAll(getProcessedThemes().map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<Project>> getProjects() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cachedProjects;
  }

  @override
  Future<Project?> getProject(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _cachedProjects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<InvestmentTheme>> getThemes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cachedThemes;
  }

  @override
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
    final newProject = Project(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      nombre: titulo,
      descripcion: descripcion,
      imagen: imagen,
      temaId: temaId,
      temaNombre: temaNombre,
      temaColor: temaColor,
      totalInvertido: 0,
      numeroInversores: 0,
      activo: activo,
      pitch: pitch,
      problema: problema,
      solucion: solucion,
      estrategiaIngresos: estrategiaIngresos,
      proyeccionFinanciera: proyeccionFinanciera,
      participantes: participantes,
      createdAt: DateTime.now(),
    );
    _cachedProjects.add(newProject);
  }

  @override
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
    final index = _cachedProjects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _cachedProjects[index] = _cachedProjects[index].copyWith(
        nombre: titulo,
        descripcion: descripcion,
        imagen: imagen,
        activo: activo,
        pitch: pitch,
        problema: problema,
        solucion: solucion,
        estrategiaIngresos: estrategiaIngresos,
        proyeccionFinanciera: proyeccionFinanciera,
        participantes: participantes,
      );
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    _cachedProjects.removeWhere((p) => p.id == id);
  }

  @override
  Future<bool> projectNameExists(String nombre, {String? excludeId}) async {
    final projects = _cachedProjects.where((p) => p.id != excludeId).toList();
    return projects.any((p) => p.nombre.toLowerCase() == nombre.toLowerCase());
  }

  @override
  Future<void> updateInvestment(String projectId, double amount) async {
    final index = _cachedProjects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final project = _cachedProjects[index];
      _cachedProjects[index] = project.copyWith(
        totalInvertido: project.totalInvertido + amount,
        numeroInversores: project.numeroInversores + 1,
      );
    }
  }
}
