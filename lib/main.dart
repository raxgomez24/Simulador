import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'data/database/database_seeder.dart';
import 'data/database/database_helper.dart';

// Detectar si estamos en web
bool get _isWeb => identical(0, 0.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En web, NO inicializar base de datos local (usará servidor)
  // Solo inicializar en plataformas móviles/deSKTOP
  if (!_isWeb) {
    try {
      final db = DatabaseHelper.instance;
      await db.database;

      final seeder = DatabaseSeeder();
      await seeder.seedAll();

      // Asegurar que los usuarios de prueba siempre existan
      await seeder.ensureTestUsers();
    } catch (e) {
      debugPrint('Error inicializando base de datos: $e');
    }
  } else {
    debugPrint('Modo Web detectado - Base de datos local deshabilitada');
    debugPrint('Para modo multi-dispositivo, implementa el servidor central (Tarea 4 del #3.md)');
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
