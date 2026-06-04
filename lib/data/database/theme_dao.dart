import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/theme_model.dart';
import 'database_helper.dart';

/// Data Access Object for Theme entity
///
/// Handles all database operations related to investment themes including
/// CRUD operations and theme statistics management.
class ThemeDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _logger = Logger('ThemeDao');

  /// Insert a new theme into the database
  Future<bool> insertTheme(ThemeModel theme) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableThemes,
        theme.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.fine('Theme inserted with ID: $id');
      return id > 0;
    } catch (e) {
      _logger.severe('Error inserting theme: $e');
      rethrow;
    }
  }

  /// Insert multiple themes at once
  Future<bool> insertThemes(List<ThemeModel> themes) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final theme in themes) {
        batch.insert(
          DatabaseHelper.tableThemes,
          theme.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await batch.commit();
      _logger.fine('Inserted ${results.length} themes');
      return results.isNotEmpty;
    } catch (e) {
      _logger.severe('Error inserting themes: $e');
      rethrow;
    }
  }

  /// Get all themes from the database
  Future<List<ThemeModel>> getAllThemes() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableThemes,
        where: '${DatabaseHelper.colThemeActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colThemeOrden} ASC, ${DatabaseHelper.colThemeNombre} ASC',
      );
      return maps.map((map) => ThemeModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting all themes: $e');
      rethrow;
    }
  }

  /// Get theme by ID
  Future<ThemeModel?> getThemeById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableThemes,
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return ThemeModel.fromJson(maps.first);
    } catch (e) {
      _logger.severe('Error getting theme by ID: $e');
      rethrow;
    }
  }

  /// Update theme information
  Future<bool> updateTheme(ThemeModel theme) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableThemes,
        theme.toJson(),
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [theme.id],
      );
      _logger.fine('Updated theme: ${theme.id}, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating theme: $e');
      rethrow;
    }
  }

  /// Update theme statistics (project count and total invested)
  Future<bool> updateThemeStats(String themeId, int projectCount, double totalInvested) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableThemes,
        {
          DatabaseHelper.colThemeNumeroProyectos: projectCount,
          DatabaseHelper.colThemeTotalInvertido: totalInvested,
        },
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [themeId],
      );
      _logger.fine('Updated stats for theme $themeId: $projectCount projects, $totalInvested invested');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating theme stats: $e');
      rethrow;
    }
  }

  /// Delete theme by ID
  Future<bool> deleteTheme(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableThemes,
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [id],
      );
      _logger.fine('Deleted theme: $id, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error deleting theme: $e');
      rethrow;
    }
  }

  /// Get theme count
  Future<int> getThemeCount() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableThemes} WHERE ${DatabaseHelper.colThemeActivo} = ?',
          [1],
        )
      ) ?? 0;
      return count;
    } catch (e) {
      _logger.severe('Error getting theme count: $e');
      rethrow;
    }
  }

  /// Get themes sorted by total invested (descending)
  Future<List<ThemeModel>> getThemesByTotalInvested() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableThemes,
        where: '${DatabaseHelper.colThemeActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colThemeTotalInvertido} DESC',
      );
      return maps.map((map) => ThemeModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting themes by total invested: $e');
      rethrow;
    }
  }

  /// Get themes sorted by project count (descending)
  Future<List<ThemeModel>> getThemesByProjectCount() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableThemes,
        where: '${DatabaseHelper.colThemeActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colThemeNumeroProyectos} DESC',
      );
      return maps.map((map) => ThemeModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting themes by project count: $e');
      rethrow;
    }
  }
}