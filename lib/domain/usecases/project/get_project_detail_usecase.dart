import '../../entities/project.dart';
import '../../repositories/project_repository.dart';
import '../../../core/errors/exceptions.dart';

class GetProjectDetailUseCase {
  final ProjectRepository _projectRepository;

  GetProjectDetailUseCase(this._projectRepository);

  Future<Project> call(String projectId) async {
    if (projectId.isEmpty) {
      throw const ValidationException(
        message: 'El ID del proyecto es requerido',
        code: 'REQUIRED_PROJECT_ID',
      );
    }
    return await _projectRepository.getProjectById(projectId);
  }
}
