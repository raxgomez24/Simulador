import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'user_dao.dart';

/// Factory para crear la base de datos apropiada según la plataforma
/// En web usa sqflite_common_ffi, en móvil usa sqflite nativo
class DatabaseFactory {
  static bool get _isWeb => identical(0, 0.0);

  static Future<DatabaseFactory> getInstance() async {
    final factory = DatabaseFactory._internal();
    if (_isWeb) {
      await factory._initWeb();
    } else {
      await factory._initMobile();
    }
    return factory;
  }

  DatabaseFactory._internal();

  Future<void> _initWeb() async {
    // Inicializar sqflite_ffi para web
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<void> _initMobile() async {
    // En móvil, sqflite se inicializa automáticamente
    // No se necesita configuración adicional
  }

  /// Obtiene una instancia de UserDao
  Future<UserDao> getUserDao() async {
    return UserDao();
  }
}
