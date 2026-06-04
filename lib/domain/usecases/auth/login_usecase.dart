import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<User> call(String username, String password) async {
    if (username.isEmpty) {
      throw const ValidationException(
        message: 'El usuario es requerido',
        code: 'REQUIRED_USERNAME',
      );
    }
    if (password.isEmpty) {
      throw const ValidationException(
        message: 'La contraseña es requerida',
        code: 'REQUIRED_PASSWORD',
      );
    }
    return await _authRepository.login(username, password);
  }
}
