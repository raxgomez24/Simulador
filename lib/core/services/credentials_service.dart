import 'dart:io';
import 'dart:convert';
import '../errors/exceptions.dart';
import '../../data/models/user_model.dart';

/// Servicio para cargar credenciales de usuarios desde un archivo externo
///
/// El archivo debe estar en la raíz del proyecto con el nombre `users_credentials.json`
/// Formato esperado:
/// ```json
/// {
///   "users": [
///     {
///       "id": "1",
///       "nombre": "Admin User",
///       "correo": "admin@amerike.com",
///       "username": "admin",
///       "password": "123456",
///       "perfil": "Admin",
///       "saldo": 0,
///       "activo": true
///     }
///   ]
/// }
/// ```
class CredentialsService {
  static const String _credentialsFileName = 'users_credentials.json';
  static List<Map<String, dynamic>>? _cachedCredentials;

  /// Obtiene la ruta del archivo de credenciales
  String get _credentialsFilePath {
    // Busca en diferentes ubicaciones donde podría estar el archivo
    final possiblePaths = [
      // Directorio raíz del proyecto (cuando se ejecuta desde Flutter)
      './$_credentialsFileName',
      // Directorio de assets
      'assets/$_credentialsFileName',
      // Directorio de documents (para móviles)
      '${Directory.current.path}/$_credentialsFileName',
      // Directorio padre del proyecto (para desarrollo)
      '../$_credentialsFileName',
      // Directorio de datos de la aplicación
      '${Directory.current.path}/data/$_credentialsFileName',
    ];

    // Verificar si el archivo existe en alguna de las ubicaciones
    for (final path in possiblePaths) {
      final file = File(path);
      if (file.existsSync()) {
        return path;
      }
    }

    // Si no existe, retornar la ruta por defecto
    return possiblePaths.first;
  }

  /// Carga las credenciales desde el archivo
  Future<List<Map<String, dynamic>>> loadCredentials() async {
    // Si ya están cargadas en caché, retornarlas
    if (_cachedCredentials != null) {
      return _cachedCredentials!;
    }

    try {
      final filePath = _credentialsFilePath;
      final file = File(filePath);

      // Verificar si el archivo existe
      if (!await file.exists()) {
        throw NotFoundException(
          message: 'Archivo de credenciales no encontrado: $filePath\n'
              'Crea el archivo "users_credentials.json" en la raíz del proyecto.',
          code: 'CREDENTIALS_FILE_NOT_FOUND',
        );
      }

      // Leer el archivo
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Extraer la lista de usuarios
      final usersList = jsonData['users'] as List<dynamic>?;
      if (usersList == null) {
        throw ValidationException(
          message: 'El archivo de credenciales no tiene la estructura correcta. '
              'Se espera un objeto con propiedad "users".',
          code: 'INVALID_CREDENTIALS_STRUCTURE',
        );
      }

      // Convertir a lista de Map<String, dynamic>
      _cachedCredentials = usersList
          .cast<Map<String, dynamic>>()
          .toList();

      return _cachedCredentials!;
    } on FormatException catch (e) {
      throw ValidationException(
        message: 'Error al parsear el archivo JSON: $e',
        code: 'JSON_PARSE_ERROR',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException(
        message: 'Error al cargar credenciales: $e',
        code: 'CREDENTIALS_LOAD_ERROR',
      );
    }
  }

  /// Busca un usuario por username y contraseña
  Future<Map<String, dynamic>?> findUser(String username, String password) async {
    final credentials = await loadCredentials();

    for (final userMap in credentials) {
      if (userMap['username'] == username && userMap['password'] == password) {
        return userMap;
      }
    }

    return null;
  }

  /// Obtiene todos los usuarios desde el archivo de credenciales
  Future<List<UserModel>> getAllUsers() async {
    final credentials = await loadCredentials();
    return credentials.map((map) => UserModel.fromJson(map)).toList();
  }

  /// Limpia la caché de credenciales
  void clearCache() {
    _cachedCredentials = null;
  }

  /// Verifica si el archivo de credenciales existe
  Future<bool> credentialsFileExists() async {
    final file = File(_credentialsFilePath);
    return await file.exists();
  }

  /// Obtiene la ruta del archivo de credenciales
  String get credentialsFilePath => _credentialsFilePath;
}
