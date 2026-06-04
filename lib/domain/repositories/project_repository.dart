import '../entities/project.dart';
import '../entities/theme.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<List<Project>> getProjectsByTheme(String themeId);
  Future<Project> getProjectById(String id);
  Future<List<InvestmentTheme>> getThemes();
  Future<InvestmentTheme> getThemeById(String id);

  /// Crea un nuevo proyecto
  Future<Project> createProject({
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
  });

  /// Actualiza un proyecto existente
  Future<Project> updateProject({
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
  });

  /// Elimina un proyecto por su ID
  Future<bool> deleteProject(String id);

  /// Verifica si un nombre de proyecto ya existe
  Future<bool> projectNameExists(String nombre, {String? excludeId});
}
