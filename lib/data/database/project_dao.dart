import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/project_model.dart';
import 'database_helper.dart';

/// Data Access Object for Project entity
///
/// Handles all database operations related to projects including CRUD operations,
/// filtering by theme, and project statistics management.
class ProjectDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _logger = Logger('ProjectDao');

  /// Insert a new project into the database
  Future<bool> insertProject(ProjectModel project) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableProjects,
        project.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.fine('Project inserted with ID: $id');
      return id > 0;
    } catch (e) {
      _logger.severe('Error inserting project: $e');
      rethrow;
    }
  }

  /// Insert multiple projects at once
  Future<bool> insertProjects(List<ProjectModel> projects) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final project in projects) {
        batch.insert(
          DatabaseHelper.tableProjects,
          project.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await batch.commit();
      _logger.fine('Inserted ${results.length} projects');
      return results.isNotEmpty;
    } catch (e) {
      _logger.severe('Error inserting projects: $e');
      rethrow;
    }
  }

  /// Get all projects from the database
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colProjectOrden} ASC, ${DatabaseHelper.colProjectNombre} ASC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting all projects: $e');
      rethrow;
    }
  }

  /// Get project by ID
  Future<ProjectModel?> getProjectById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return ProjectModel.fromJson(maps.first);
    } catch (e) {
      _logger.severe('Error getting project by ID: $e');
      rethrow;
    }
  }

  /// Get projects by theme ID
  Future<List<ProjectModel>> getProjectsByTheme(String themeId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectTemaId} = ? AND ${DatabaseHelper.colProjectActivo} = ?',
        whereArgs: [themeId, 1],
        orderBy: '${DatabaseHelper.colProjectOrden} ASC, ${DatabaseHelper.colProjectNombre} ASC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting projects by theme: $e');
      rethrow;
    }
  }

  /// Update project information
  Future<bool> updateProject(ProjectModel project) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableProjects,
        project.toJson(),
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [project.id],
      );
      _logger.fine('Updated project: ${project.id}, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating project: $e');
      rethrow;
    }
  }

  /// Update project investment statistics
  Future<bool> updateProjectInvestmentStats(String projectId, double totalInvested, int investorCount) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableProjects,
        {
          DatabaseHelper.colProjectTotalInvertido: totalInvested,
          DatabaseHelper.colProjectNumeroInversores: investorCount,
        },
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [projectId],
      );
      _logger.fine('Updated investment stats for project $projectId: $totalInvested, $investorCount investors');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating project investment stats: $e');
      rethrow;
    }
  }

  /// Increment project total invested amount
  Future<bool> addInvestmentToProject(String projectId, double amount) async {
    try {
      final project = await getProjectById(projectId);
      if (project == null) return false;

      final newTotal = project.totalInvertido + amount;
      final newInvestorCount = project.numeroInversores + 1;

      return await updateProjectInvestmentStats(projectId, newTotal, newInvestorCount);
    } catch (e) {
      _logger.severe('Error adding investment to project: $e');
      rethrow;
    }
  }

  /// Delete project by ID
  Future<bool> deleteProject(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectId} = ?',
        whereArgs: [id],
      );
      _logger.fine('Deleted project: $id, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error deleting project: $e');
      rethrow;
    }
  }

  /// Get project count
  Future<int> getProjectCount() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableProjects} WHERE ${DatabaseHelper.colProjectActivo} = ?',
          [1],
        )
      ) ?? 0;
      return count;
    } catch (e) {
      _logger.severe('Error getting project count: $e');
      rethrow;
    }
  }

  /// Get projects sorted by total invested (descending)
  Future<List<ProjectModel>> getProjectsByTotalInvested() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colProjectTotalInvertido} DESC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting projects by total invested: $e');
      rethrow;
    }
  }

  /// Get projects sorted by investor count (descending)
  Future<List<ProjectModel>> getProjectsByInvestorCount() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colProjectNumeroInversores} DESC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting projects by investor count: $e');
      rethrow;
    }
  }

  /// Search projects by name
  Future<List<ProjectModel>> searchProjectsByName(String searchTerm) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableProjects,
        where: '${DatabaseHelper.colProjectNombre} LIKE ? AND ${DatabaseHelper.colProjectActivo} = ?',
        whereArgs: ['%$searchTerm%', 1],
        orderBy: '${DatabaseHelper.colProjectNombre} ASC',
      );
      return maps.map((map) => ProjectModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error searching projects by name: $e');
      rethrow;
    }
  }

  /// Get project count by theme
  Future<int> getProjectCountByTheme(String themeId) async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableProjects} WHERE ${DatabaseHelper.colProjectTemaId} = ? AND ${DatabaseHelper.colProjectActivo} = ?',
          [themeId, 1],
        )
      ) ?? 0;
      return count;
    } catch (e) {
      _logger.severe('Error getting project count by theme: $e');
      rethrow;
    }
  }
}