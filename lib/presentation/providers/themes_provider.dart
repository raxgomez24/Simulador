import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../data/repositories/theme_repository_local.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../data/datasources/remote/websocket_datasource.dart';
import 'project_provider.dart';
import 'admin_provider.dart';
import '../../app/config.dart';

/// WebSocket DataSource Provider
final webSocketDataSourceProvider = Provider<WebSocketDataSource>((ref) {
  return WebSocketDataSource();
});

/// Estado para el filtro de búsqueda de temas
final searchQueryThemesProvider = StateProvider<String>((ref) => '');

/// Estado para el filtro de temas activos/inactivos
final activeFilterProvider = StateProvider<bool?>((ref) => null);

/// Provider para el repositorio de temas
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  // En web, no usar repositorio local (no SQLite disponible)
  if (AppConfig.isWeb || !AppConfig.useLocalData) {
    final dataSource = ref.read(webSocketDataSourceProvider);
    return ThemeRepositoryImpl(dataSource);
  } else {
    return ThemeRepositoryLocal();
  }
});

/// Provider para la gestión de temas
final themesManagementProvider =
    AsyncNotifierProvider<ThemesManagementNotifier, List<InvestmentTheme>>(
  ThemesManagementNotifier.new,
);

class ThemesManagementNotifier extends AsyncNotifier<List<InvestmentTheme>> {
  late ThemeRepository _themeRepository;
  late AdminActions _adminActions;

  @override
  Future<List<InvestmentTheme>> build() async {
    _themeRepository = ref.read(themeRepositoryProvider);
    _adminActions = ref.read(adminActionsProvider);
    return await _themeRepository.getThemes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final themes = await _themeRepository.getThemes();
      state = AsyncValue.data(themes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createTheme({
    required String nombre,
    String descripcion = '',
    required String color,
    required String icon,
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _themeRepository.createTheme(
          nombre: nombre,
          descripcion: descripcion,
          color: color,
          icono: icon,
          orden: orden,
          activo: activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.createTheme(
          nombre: nombre,
          descripcion: descripcion,
          color: color,
          icono: icon,
          orden: orden,
        );
      }
      // Refrescar la lista de temas
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateTheme({
    required String id,
    required String nombre,
    String descripcion = '',
    required String color,
    required String icon,
    int orden = 0,
    bool activo = true,
  }) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _themeRepository.updateTheme(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          color: color,
          icono: icon,
          orden: orden,
          activo: activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.updateTheme(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          color: color,
          icono: icon,
          orden: orden,
        );
      }
      // Refrescar la lista de temas
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteTheme(String themeId) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _themeRepository.deleteTheme(themeId);
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.deleteTheme(themeId);
      }
      // Refrescar la lista de temas
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleThemeActive(InvestmentTheme theme) async {
    try {
      if (AppConfig.useLocalData) {
        // Usar el repositorio local directamente
        await _themeRepository.updateTheme(
          id: theme.id,
          nombre: theme.nombre,
          descripcion: theme.descripcion,
          color: theme.color,
          icono: theme.icon,
          orden: theme.orden,
          activo: !theme.activo,
        );
      } else {
        // Usar las acciones de admin (WebSocket)
        await _adminActions.updateTheme(
          id: theme.id,
          nombre: theme.nombre,
          descripcion: theme.descripcion,
          color: theme.color,
          icono: theme.icon,
          orden: theme.orden,
        );
      }
      // Refrescar la lista de temas
      await refresh();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<bool> themeNameExists(String nombre, {String? excludeId}) async {
    try {
      return await _themeRepository.themeNameExists(nombre, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }
}

/// Provider para temas filtrados
final filteredThemesProvider = Provider<List<InvestmentTheme>>((ref) {
  final themesAsync = ref.watch(themesManagementProvider);
  final searchQuery = ref.watch(searchQueryThemesProvider);
  final activeFilter = ref.watch(activeFilterProvider);

  return themesAsync.maybeWhen(
    data: (themes) {
      var filtered = themes;

      // Filtrar por búsqueda
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((theme) {
          return theme.nombre.toLowerCase().contains(searchQuery.toLowerCase()) ||
              theme.descripcion.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      // Filtrar por estado activo/inactivo
      if (activeFilter != null) {
        filtered = filtered.where((theme) => theme.activo == activeFilter).toList();
      }

      // Ordenar por orden
      filtered.sort((a, b) => a.orden.compareTo(b.orden));

      return filtered;
    },
    orElse: () => [],
  );
});

/// Provider para temas activos ordenados
final activeThemesProvider = Provider<List<InvestmentTheme>>((ref) {
  final themesAsync = ref.watch(themesManagementProvider);

  return themesAsync.maybeWhen(
    data: (themes) {
      final activeThemes = themes.where((theme) => theme.activo).toList();
      activeThemes.sort((a, b) => a.orden.compareTo(b.orden));
      return activeThemes;
    },
    orElse: () => [],
  );
});

/// Provider para contar proyectos por tema
final themeProjectCountProvider =
    Provider.family<int, String>((ref, themeId) {
  final projectsAsync = ref.watch(projectsProvider);

  return projectsAsync.maybeWhen(
    data: (projects) {
      return projects.where((project) => project.temaId == themeId).length;
    },
    orElse: () => 0,
  );
});

/// Provider para calcular total invertido por tema
final themeTotalInvestedProvider =
    Provider.family<double, String>((ref, themeId) {
  final projectsAsync = ref.watch(projectsProvider);

  return projectsAsync.maybeWhen(
    data: (projects) {
      return projects
          .where((project) => project.temaId == themeId)
          .fold<double>(0, (sum, project) => sum + project.totalInvertido);
    },
    orElse: () => 0,
  );
});

/// Colores predefinidos para los temas
const predefinedColors = [
  // Azul
  '#00D4AA',
  '#007AFF',
  '#5B5FEF',
  // Verde
  '#10B981',
  '#34D399',
  '#059669',
  // Rojo/Naranja
  '#EF4444',
  '#F97316',
  '#FF6B35',
  // Amarillo
  '#FBBF24',
  '#F59E0B',
  '#FFB800',
  // Púrpura
  '#A78BFA',
  '#8B5CF6',
  '#7C3AED',
  // Rosa
  '#F472B6',
  '#EC4899',
  '#DB2777',
  // Cian
  '#06B6D4',
  '#0891B2',
  '#0E7490',
];

/// Iconos predefinidos por categoría
const predefinedIcons = {
  'Tecnología': ['💻', '🖥️', '📱', '🔌', '💾', '🎮', '🤖', '📡'],
  'Salud': ['🏥', '💊', '🩺', '🧬', '🔬', '⚕️', '🦠', '💉'],
  'Educación': ['📚', '🎓', '📝', '✏️', '📐', '🎨', '🎵', '🏫'],
  'Energía': ['⚡', '🔋', '🌞', '💡', '🌊', '🌬️', '🔥', '☢️'],
  'Finanzas': ['💰', '💵', '💳', '📊', '📈', '💹', '🏦', '💎'],
  'Comercio': ['🛒', '🛍️', '🏪', '🏬', '🛎️', '📦', '🏷️', '💼'],
  'Bienes Raíces': ['🏠', '🏢', '🏗️', '🏘️', '🏡', '🏭', '🌆', '🏰'],
  'Transporte': ['🚗', '🚀', '✈️', '🚂', '🚢', '🚁', '🚲', '🛵'],
  'Alimentos': ['🍕', '🍔', '🍎', '🥗', '🍷', '☕', '🍰', '🍜'],
  'Medio Ambiente': ['🌱', '🌿', '🌲', '🌍', '🌊', '🦋', '🌺', '🌻'],
};
