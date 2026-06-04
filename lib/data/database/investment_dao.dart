import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/investment_model.dart';
import 'database_helper.dart';

/// Data Access Object for Investment entity
///
/// Handles all database operations related to investments including CRUD operations,
/// filtering by user/project/theme, and investment statistics.
class InvestmentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _logger = Logger('InvestmentDao');

  /// Insert a new investment into the database
  Future<bool> insertInvestment(InvestmentModel investment) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableInvestments,
        investment.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.fine('Investment inserted with ID: $id');

      // Update project and theme statistics
      await _updateRelatedStatistics(investment);

      return id > 0;
    } catch (e) {
      _logger.severe('Error inserting investment: $e');
      rethrow;
    }
  }

  /// Insert multiple investments at once
  Future<bool> insertInvestments(List<InvestmentModel> investments) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final investment in investments) {
        batch.insert(
          DatabaseHelper.tableInvestments,
          investment.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await batch.commit();
      _logger.fine('Inserted ${results.length} investments');

      // Update statistics for all related projects and themes
      for (final investment in investments) {
        await _updateRelatedStatistics(investment);
      }

      return results.isNotEmpty;
    } catch (e) {
      _logger.severe('Error inserting investments: $e');
      rethrow;
    }
  }

  /// Get all investments from the database
  Future<List<InvestmentModel>> getAllInvestments() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting all investments: $e');
      rethrow;
    }
  }

  /// Get investment by ID
  Future<InvestmentModel?> getInvestmentById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return InvestmentModel.fromJson(maps.first);
    } catch (e) {
      _logger.severe('Error getting investment by ID: $e');
      rethrow;
    }
  }

  /// Get investments by user ID
  Future<List<InvestmentModel>> getInvestmentsByUser(String userId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentUsuarioId} = ?',
        whereArgs: [userId],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments by user: $e');
      rethrow;
    }
  }

  /// Get investments by project ID
  Future<List<InvestmentModel>> getInvestmentsByProject(String projectId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentProyectoId} = ?',
        whereArgs: [projectId],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments by project: $e');
      rethrow;
    }
  }

  /// Get investments by theme ID
  Future<List<InvestmentModel>> getInvestmentsByTheme(String themeId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentTemaId} = ?',
        whereArgs: [themeId],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments by theme: $e');
      rethrow;
    }
  }

  /// Get investments by user and project
  Future<List<InvestmentModel>> getInvestmentsByUserAndProject(
    String userId,
    String projectId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentUsuarioId} = ? AND ${DatabaseHelper.colInvestmentProyectoId} = ?',
        whereArgs: [userId, projectId],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments by user and project: $e');
      rethrow;
    }
  }

  /// Update investment information
  Future<bool> updateInvestment(InvestmentModel investment) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableInvestments,
        investment.toJson(),
        where: '${DatabaseHelper.colInvestmentId} = ?',
        whereArgs: [investment.id],
      );
      _logger.fine('Updated investment: ${investment.id}, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating investment: $e');
      rethrow;
    }
  }

  /// Update investment status
  Future<bool> updateInvestmentStatus(String investmentId, String newStatus) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableInvestments,
        {DatabaseHelper.colInvestmentEstado: newStatus},
        where: '${DatabaseHelper.colInvestmentId} = ?',
        whereArgs: [investmentId],
      );
      _logger.fine('Updated investment status: $investmentId -> $newStatus');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating investment status: $e');
      rethrow;
    }
  }

  /// Delete investment by ID
  Future<bool> deleteInvestment(String id) async {
    try {
      final investment = await getInvestmentById(id);
      if (investment == null) return false;

      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentId} = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        // Recalculate statistics after deletion
        await _recalculateProjectStatistics(investment.proyectoId);
        await _recalculateThemeStatistics(investment.temaId);
      }

      _logger.fine('Deleted investment: $id, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error deleting investment: $e');
      rethrow;
    }
  }

  /// Get total invested by user
  Future<double> getTotalInvestedByUser(String userId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colInvestmentMonto}) as total FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentUsuarioId} = ? AND ${DatabaseHelper.colInvestmentEstado} = ?',
        [userId, 'activa'],
      );

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      _logger.severe('Error getting total invested by user: $e');
      rethrow;
    }
  }

  /// Get total invested in project
  Future<double> getTotalInvestedInProject(String projectId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colInvestmentMonto}) as total FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentProyectoId} = ? AND ${DatabaseHelper.colInvestmentEstado} = ?',
        [projectId, 'activa'],
      );

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      _logger.severe('Error getting total invested in project: $e');
      rethrow;
    }
  }

  /// Get total invested in theme
  Future<double> getTotalInvestedInTheme(String themeId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colInvestmentMonto}) as total FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentTemaId} = ? AND ${DatabaseHelper.colInvestmentEstado} = ?',
        [themeId, 'activa'],
      );

      if (result.isEmpty || result.first['total'] == null) return 0.0;
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      _logger.severe('Error getting total invested in theme: $e');
      rethrow;
    }
  }

  /// Get investor count for project
  Future<int> getInvestorCountForProject(String projectId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT ${DatabaseHelper.colInvestmentUsuarioId}) as count FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentProyectoId} = ? AND ${DatabaseHelper.colInvestmentEstado} = ?',
        [projectId, 'activa'],
      );

      if (result.isEmpty || result.first['count'] == null) return 0;
      return result.first['count'] as int;
    } catch (e) {
      _logger.severe('Error getting investor count for project: $e');
      rethrow;
    }
  }

  /// Get investment count
  Future<int> getInvestmentCount() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableInvestments}')
      ) ?? 0;
      return count;
    } catch (e) {
      _logger.severe('Error getting investment count: $e');
      rethrow;
    }
  }

  /// Get investments by status
  Future<List<InvestmentModel>> getInvestmentsByStatus(String status) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentEstado} = ?',
        whereArgs: [status],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments by status: $e');
      rethrow;
    }
  }

  /// Get investments in date range
  Future<List<InvestmentModel>> getInvestmentsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvestments,
        where: '${DatabaseHelper.colInvestmentFechaHora} >= ? AND ${DatabaseHelper.colInvestmentFechaHora} <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: '${DatabaseHelper.colInvestmentFechaHora} DESC',
      );
      return maps.map((map) => InvestmentModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting investments in date range: $e');
      rethrow;
    }
  }

  /// Helper method to update related statistics when investment is added
  Future<void> _updateRelatedStatistics(InvestmentModel investment) async {
    try {
      final db = await _dbHelper.database;

      // Update project statistics
      final projectTotal = await getTotalInvestedInProject(investment.proyectoId);
      final projectInvestors = await getInvestorCountForProject(investment.proyectoId);

      await db.update(
        DatabaseHelper.tableProjects,
        {
          DatabaseHelper.colProjectTotalInvertido: projectTotal,
          DatabaseHelper.colProjectNumeroInversores: projectInvestors,
        },
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [investment.proyectoId],
      );

      // Update theme statistics
      final themeTotal = await getTotalInvestedInTheme(investment.temaId);
      final themeProjects = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(DISTINCT ${DatabaseHelper.colInvestmentProyectoId}) FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentTemaId} = ?',
          [investment.temaId],
        ),
      ) ?? 0;

      await db.update(
        DatabaseHelper.tableThemes,
        {
          DatabaseHelper.colThemeTotalInvertido: themeTotal,
          DatabaseHelper.colThemeNumeroProyectos: themeProjects,
        },
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [investment.temaId],
      );
    } catch (e) {
      _logger.warning('Error updating related statistics: $e');
      // Don't rethrow as this is not critical
    }
  }

  /// Helper method to recalculate project statistics
  Future<void> _recalculateProjectStatistics(String projectId) async {
    try {
      final db = await _dbHelper.database;

      final total = await getTotalInvestedInProject(projectId);
      final investors = await getInvestorCountForProject(projectId);

      await db.update(
        DatabaseHelper.tableProjects,
        {
          DatabaseHelper.colProjectTotalInvertido: total,
          DatabaseHelper.colProjectNumeroInversores: investors,
        },
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [projectId],
      );
    } catch (e) {
      _logger.warning('Error recalculating project statistics: $e');
    }
  }

  /// Helper method to recalculate theme statistics
  Future<void> _recalculateThemeStatistics(String themeId) async {
    try {
      final db = await _dbHelper.database;

      final total = await getTotalInvestedInTheme(themeId);
      final projects = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(DISTINCT ${DatabaseHelper.colInvestmentProyectoId}) FROM ${DatabaseHelper.tableInvestments} WHERE ${DatabaseHelper.colInvestmentTemaId} = ?',
          [themeId],
        ),
      ) ?? 0;

      await db.update(
        DatabaseHelper.tableThemes,
        {
          DatabaseHelper.colThemeTotalInvertido: total,
          DatabaseHelper.colThemeNumeroProyectos: projects,
        },
        where: '${DatabaseHelper.colThemeId} = ?',
        whereArgs: [themeId],
      );
    } catch (e) {
      _logger.warning('Error recalculating theme statistics: $e');
    }
  }
}