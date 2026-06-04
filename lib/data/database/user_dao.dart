import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

/// Data Access Object for User entity
///
/// Handles all database operations related to users including CRUD operations,
/// authentication, and user management.
class UserDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _logger = Logger('UserDao');

  /// Insert a new user into the database
  Future<bool> insertUser(UserModel user) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableUsers,
        user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.fine('User inserted with ID: $id');
      return id > 0;
    } catch (e) {
      _logger.severe('Error inserting user: $e');
      rethrow;
    }
  }

  /// Insert multiple users at once
  Future<bool> insertUsers(List<UserModel> users) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final user in users) {
        batch.insert(
          DatabaseHelper.tableUsers,
          user.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final results = await batch.commit();
      _logger.fine('Inserted ${results.length} users');
      return results.isNotEmpty;
    } catch (e) {
      _logger.severe('Error inserting users: $e');
      rethrow;
    }
  }

  /// Get all users from the database
  Future<List<UserModel>> getAllUsers() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        orderBy: '${DatabaseHelper.colUserName} ASC',
      );
      return maps.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting all users: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return UserModel.fromJson(maps.first);
    } catch (e) {
      _logger.severe('Error getting user by ID: $e');
      rethrow;
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserUsername} = ?',
        whereArgs: [username],
      );

      if (maps.isEmpty) return null;
      return UserModel.fromJson(maps.first);
    } catch (e) {
      _logger.severe('Error getting user by username: $e');
      rethrow;
    }
  }

  /// Authenticate user by username and password
  Future<UserModel?> authenticate(String username, String password) async {
    try {
      _logger.info('Attempting authentication for user: $username');
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserUsername} = ? AND ${DatabaseHelper.colUserPassword} = ?',
        whereArgs: [username, password],
      );

      _logger.fine('Authentication query returned ${maps.length} results');

      if (maps.isEmpty) {
        _logger.warning('Authentication failed: no matching user found');
        return null;
      }

      // Update last login time
      final userId = maps.first[DatabaseHelper.colUserId] as String;
      await updateLastLogin(userId);

      final user = UserModel.fromJson(maps.first);
      _logger.info('Authentication successful for user: ${user.nombre} (activo: ${user.activo})');

      return user;
    } catch (e) {
      _logger.severe('Error authenticating user: $e');
      rethrow;
    }
  }

  /// Update user information
  Future<bool> updateUser(UserModel user) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableUsers,
        user.toJson(),
        where: '${DatabaseHelper.colUserId} = ?',
        whereArgs: [user.id],
      );
      _logger.fine('Updated user: ${user.id}, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating user: $e');
      rethrow;
    }
  }

  /// Update user balance
  Future<bool> updateBalance(String userId, double newBalance) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableUsers,
        {DatabaseHelper.colUserSaldo: newBalance},
        where: '${DatabaseHelper.colUserId} = ?',
        whereArgs: [userId],
      );
      _logger.fine('Updated balance for user $userId: $newBalance');
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating user balance: $e');
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<bool> updateLastLogin(String userId) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableUsers,
        {DatabaseHelper.colUserLastLogin: DateTime.now().toIso8601String()},
        where: '${DatabaseHelper.colUserId} = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      _logger.severe('Error updating last login: $e');
      rethrow;
    }
  }

  /// Delete user by ID
  Future<bool> deleteUser(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserId} = ?',
        whereArgs: [id],
      );
      _logger.fine('Deleted user: $id, rows affected: $count');
      return count > 0;
    } catch (e) {
      _logger.severe('Error deleting user: $e');
      rethrow;
    }
  }

  /// Get active users only
  Future<List<UserModel>> getActiveUsers() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserActivo} = ?',
        whereArgs: [1],
        orderBy: '${DatabaseHelper.colUserName} ASC',
      );
      return maps.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting active users: $e');
      rethrow;
    }
  }

  /// Get users by profile/role
  Future<List<UserModel>> getUsersByProfile(String profile) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableUsers,
        where: '${DatabaseHelper.colUserProfile} = ?',
        whereArgs: [profile],
        orderBy: '${DatabaseHelper.colUserName} ASC',
      );
      return maps.map((map) => UserModel.fromJson(map)).toList();
    } catch (e) {
      _logger.severe('Error getting users by profile: $e');
      rethrow;
    }
  }

  /// Get user count
  Future<int> getUserCount() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableUsers}')
      ) ?? 0;
      return count;
    } catch (e) {
      _logger.severe('Error getting user count: $e');
      rethrow;
    }
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      final user = await getUserByUsername(username);
      return user != null;
    } catch (e) {
      _logger.severe('Error checking username existence: $e');
      rethrow;
    }
  }
}