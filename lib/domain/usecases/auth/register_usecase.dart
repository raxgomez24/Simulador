import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<User> callAsGuest(String username, String fullName) async {
    if (username.isEmpty) {
      throw const ValidationException(
        message: 'El usuario es requerido',
        code: 'REQUIRED_USERNAME',
      );
    }
    if (username.length < 3) {
      throw const ValidationException(
        message: 'El usuario debe tener al menos 3 caracteres',
        code: 'INVALID_USERNAME_LENGTH',
      );
    }
    if (fullName.isEmpty) {
      throw const ValidationException(
        message: 'El nombre completo es requerido',
        code: 'REQUIRED_FULLNAME',
      );
    }
    return await _authRepository.registerAsGuest(username, fullName);
  }
}
