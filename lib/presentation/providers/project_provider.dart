import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/theme.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/project/get_projects_usecase.dart';
import '../../domain/usecases/project/get_project_detail_usecase.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/repositories/project_repository_local.dart';
import '../../app/config.dart';
import 'websocket_provider.dart';

/// Provider que selecciona el repositorio apropiado según la configuración
/// Si useLocalData es true y NO es web, usa el repositorio local (mock data)
/// Si useLocalData es false o es web, usa el repositorio WebSocket
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  if (AppConfig.useLocalData && !AppConfig.isWeb) {
    // Usar datos locales/mock solo en móvil/desktop
    return ProjectRepositoryLocal();
  } else {
    // Usar servidor WebSocket (o en web)
    final dataSource = ref.read(webSocketDataSourceProvider);
    return ProjectRepositoryImpl(dataSource);
  }
});

final getProjectsUseCaseProvider = Provider<GetProjectsUseCase>((ref) {
  return GetProjectsUseCase(ref.read(projectRepositoryProvider));
});

final getProjectDetailUseCaseProvider = Provider<GetProjectDetailUseCase>((ref) {
  return GetProjectDetailUseCase(ref.read(projectRepositoryProvider));
});

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  ProjectsNotifier.new,
);

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final useCase = ref.read(getProjectsUseCaseProvider);
    return await useCase();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final useCase = ref.read(getProjectsUseCaseProvider);
    state = await AsyncValue.guard(() => useCase());
  }
}

final themesProvider = AsyncNotifierProvider<ThemesNotifier, List<InvestmentTheme>>(
  ThemesNotifier.new,
);

class ThemesNotifier extends AsyncNotifier<List<InvestmentTheme>> {
  @override
  Future<List<InvestmentTheme>> build() async {
    final useCase = ref.read(getProjectsUseCaseProvider);
    return await useCase.callThemes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final useCase = ref.read(getProjectsUseCaseProvider);
    state = await AsyncValue.guard(() => useCase.callThemes());
  }
}

class ProjectDetailNotifier extends FamilyAsyncNotifier<Project?, String> {
  String? _currentProjectId;

  String? get currentProjectId => _currentProjectId;

  @override
  Future<Project?> build(String arg) async {
    if (arg.isEmpty) return null;
    _currentProjectId = arg;
    final useCase = ref.read(getProjectDetailUseCaseProvider);
    return await useCase(arg);
  }

  Future<void> refresh() async {
    if (_currentProjectId == null) return;
    state = const AsyncValue.loading();
    final useCase = ref.read(getProjectDetailUseCaseProvider);
    state = await AsyncValue.guard(() => useCase(_currentProjectId!));
  }
}

final projectDetailProvider =
    AsyncNotifierProvider.family<ProjectDetailNotifier, Project?, String>(
  ProjectDetailNotifier.new,
);
