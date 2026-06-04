import '../../entities/project.dart';
import '../../entities/theme.dart';
import '../../repositories/project_repository.dart';

class GetProjectsUseCase {
  final ProjectRepository _projectRepository;

  GetProjectsUseCase(this._projectRepository);

  Future<List<Project>> call() async {
    return await _projectRepository.getProjects();
  }

  Future<List<Project>> callByTheme(String themeId) async {
    return await _projectRepository.getProjectsByTheme(themeId);
  }

  Future<List<InvestmentTheme>> callThemes() async {
    return await _projectRepository.getThemes();
  }
}
