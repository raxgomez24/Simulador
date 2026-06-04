import '../entities/theme.dart';

abstract class ThemeRepository {
  /// Obtiene todos los temas
  Future<List<InvestmentTheme>> getThemes();

  /// Obtiene un tema por su ID
  Future<InvestmentTheme> getThemeById(String id);

  /// Crea un nuevo tema
  Future<InvestmentTheme> createTheme({
    required String nombre,
    String descripcion = '',
    required String color,
    required String icono,
    int orden = 0,
    bool activo = true,
  });

  /// Actualiza un tema existente
  Future<InvestmentTheme> updateTheme({
    required String id,
    required String nombre,
    String descripcion = '',
    required String color,
    required String icono,
    int orden = 0,
    bool activo = true,
  });

  /// Elimina un tema por su ID
  Future<bool> deleteTheme(String id);

  /// Verifica si un nombre de tema ya existe
  Future<bool> themeNameExists(String nombre, {String? excludeId});
}
