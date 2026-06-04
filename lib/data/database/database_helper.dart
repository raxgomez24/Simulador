import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

/// Database helper class for managing SQLite database operations
///
/// This class provides singleton access to the SQLite database and handles
/// table creation, version management, and basic database operations.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static final _logger = Logger('DatabaseHelper');

  // Database version and name
  static const int _databaseVersion = 1;
  static const String _databaseName = 'amerike_investment.db';

  // Table names
  static const String tableUsers = 'users';
  static const String tableThemes = 'themes';
  static const String tableProjects = 'projects';
  static const String tableInvestments = 'investments';

  // Column names for Users table
  static const String colUserId = 'id';
  static const String colUserName = 'nombre';
  static const String colUserCorreo = 'correo';
  static const String colUserUsername = 'username';
  static const String colUserPassword = 'password';
  static const String colUserProfile = 'perfil';
  static const String colUserSaldo = 'saldo';
  static const String colUserActivo = 'activo';
  static const String colUserFechaRegistro = 'fecha_registro';
  static const String colUserCreatedAt = 'created_at';
  static const String colUserLastLogin = 'last_login';

  // Column names for Themes table
  static const String colThemeId = 'id';
  static const String colThemeNombre = 'nombre';
  static const String colThemeColor = 'color';
  static const String colThemeIcon = 'icon';
  static const String colThemeNumeroProyectos = 'numero_proyectos';
  static const String colThemeTotalInvertido = 'total_invertido';
  static const String colThemeDescripcion = 'descripcion';
  static const String colThemeOrden = 'orden';
  static const String colThemeActivo = 'activo';

  // Column names for Projects table
  static const String colProjectId = 'id';
  static const String colProjectNombre = 'nombre';
  static const String colProjectDescripcion = 'descripcion';
  static const String colProjectImagen = 'imagen';
  static const String colProjectTemaId = 'tema_id';
  static const String colProjectTemaNombre = 'tema_nombre';
  static const String colProjectTemaColor = 'tema_color';
  static const String colProjectTotalInvertido = 'total_invertido';
  static const String colProjectNumeroInversores = 'numero_inversores';
  static const String colProjectCreatedAt = 'created_at';
  static const String colProjectActivo = 'activo';
  static const String colProjectPitch = 'pitch';
  static const String colProjectProblema = 'problema';
  static const String colProjectSolucion = 'solucion';
  static const String colProjectEstrategiaIngresos = 'estrategia_ingresos';
  static const String colProjectProyeccionFinanciera = 'proyeccion_financiera';
  static const String colProjectParticipantes = 'participantes';
  static const String colProjectOrden = 'orden';

  // Column names for Investments table
  static const String colInvestmentId = 'id';
  static const String colInvestmentUsuarioId = 'usuario_id';
  static const String colInvestmentUsuarioNombre = 'usuario_nombre';
  static const String colInvestmentPerfil = 'perfil';
  static const String colInvestmentProyectoId = 'proyecto_id';
  static const String colInvestmentProyectoNombre = 'proyecto_nombre';
  static const String colInvestmentTemaId = 'tema_id';
  static const String colInvestmentTemaNombre = 'tema_nombre';
  static const String colInvestmentTemaColor = 'tema_color';
  static const String colInvestmentMonto = 'monto';
  static const String colInvestmentFechaHora = 'fecha_hora';
  static const String colInvestmentObservaciones = 'observaciones';
  static const String colInvestmentEstado = 'estado';

  DatabaseHelper._internal();

  /// Get singleton instance of DatabaseHelper
  static DatabaseHelper get instance => _instance;

  /// Get the database instance, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database and create tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _logger.info('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Creating database tables');

    // Create Users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        $colUserId TEXT PRIMARY KEY,
        $colUserName TEXT NOT NULL,
        $colUserCorreo TEXT,
        $colUserUsername TEXT UNIQUE NOT NULL,
        $colUserPassword TEXT NOT NULL,
        $colUserProfile TEXT NOT NULL,
        $colUserSaldo REAL DEFAULT 0.0,
        $colUserActivo INTEGER DEFAULT 1,
        $colUserFechaRegistro TEXT,
        $colUserCreatedAt TEXT,
        $colUserLastLogin TEXT
      )
    ''');

    // Create Themes table
    await db.execute('''
      CREATE TABLE $tableThemes (
        $colThemeId TEXT PRIMARY KEY,
        $colThemeNombre TEXT NOT NULL,
        $colThemeColor TEXT NOT NULL,
        $colThemeIcon TEXT NOT NULL,
        $colThemeNumeroProyectos INTEGER DEFAULT 0,
        $colThemeTotalInvertido REAL DEFAULT 0.0,
        $colThemeDescripcion TEXT DEFAULT '',
        $colThemeOrden INTEGER DEFAULT 0,
        $colThemeActivo INTEGER DEFAULT 1
      )
    ''');

    // Create Projects table
    await db.execute('''
      CREATE TABLE $tableProjects (
        $colProjectId TEXT PRIMARY KEY,
        $colProjectNombre TEXT NOT NULL,
        $colProjectDescripcion TEXT NOT NULL,
        $colProjectImagen TEXT,
        $colProjectTemaId TEXT NOT NULL,
        $colProjectTemaNombre TEXT NOT NULL,
        $colProjectTemaColor TEXT,
        $colProjectTotalInvertido REAL DEFAULT 0.0,
        $colProjectNumeroInversores INTEGER DEFAULT 0,
        $colProjectCreatedAt TEXT,
        $colProjectActivo INTEGER DEFAULT 1,
        $colProjectPitch TEXT,
        $colProjectProblema TEXT,
        $colProjectSolucion TEXT,
        $colProjectEstrategiaIngresos TEXT,
        $colProjectProyeccionFinanciera TEXT,
        $colProjectParticipantes TEXT,
        $colProjectOrden INTEGER,
        FOREIGN KEY ($colProjectTemaId) REFERENCES $tableThemes($colThemeId)
      )
    ''');

    // Create Investments table
    await db.execute('''
      CREATE TABLE $tableInvestments (
        $colInvestmentId TEXT PRIMARY KEY,
        $colInvestmentUsuarioId TEXT NOT NULL,
        $colInvestmentUsuarioNombre TEXT NOT NULL,
        $colInvestmentPerfil TEXT NOT NULL,
        $colInvestmentProyectoId TEXT NOT NULL,
        $colInvestmentProyectoNombre TEXT NOT NULL,
        $colInvestmentTemaId TEXT NOT NULL,
        $colInvestmentTemaNombre TEXT NOT NULL,
        $colInvestmentTemaColor TEXT NOT NULL,
        $colInvestmentMonto REAL NOT NULL,
        $colInvestmentFechaHora TEXT NOT NULL,
        $colInvestmentObservaciones TEXT,
        $colInvestmentEstado TEXT DEFAULT 'activa',
        FOREIGN KEY ($colInvestmentUsuarioId) REFERENCES $tableUsers($colUserId),
        FOREIGN KEY ($colInvestmentProyectoId) REFERENCES $tableProjects($colProjectId)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_investments_user ON $tableInvestments($colInvestmentUsuarioId)
    ''');
    await db.execute('''
      CREATE INDEX idx_investments_project ON $tableInvestments($colInvestmentProyectoId)
    ''');
    await db.execute('''
      CREATE INDEX idx_investments_theme ON $tableInvestments($colInvestmentTemaId)
    ''');
    await db.execute('''
      CREATE INDEX idx_projects_theme ON $tableProjects($colProjectTemaId)
    ''');
    await db.execute('''
      CREATE INDEX idx_users_username ON $tableUsers($colUserUsername)
    ''');

    _logger.info('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info('Upgrading database from version $oldVersion to $newVersion');

    // Handle future database migrations here
    // For now, we'll recreate tables if version changes
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS $tableInvestments');
      await db.execute('DROP TABLE IF EXISTS $tableProjects');
      await db.execute('DROP TABLE IF EXISTS $tableThemes');
      await db.execute('DROP TABLE IF EXISTS $tableUsers');
      await _onCreate(db, newVersion);
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.info('Database connection closed');
    }
  }

  /// Clear all data from all tables (useful for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableInvestments);
    await db.delete(tableProjects);
    await db.delete(tableThemes);
    await db.delete(tableUsers);
    _logger.info('All data cleared from database');
  }

  /// Check if database is empty (no users, themes, or projects)
  Future<bool> isEmpty() async {
    final db = await database;

    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableUsers')
    ) ?? 0;

    final themeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableThemes')
    ) ?? 0;

    final projectCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableProjects')
    ) ?? 0;

    return userCount == 0 && themeCount == 0 && projectCount == 0;
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableUsers')
    ) ?? 0;

    final themeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableThemes')
    ) ?? 0;

    final projectCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableProjects')
    ) ?? 0;

    final investmentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableInvestments')
    ) ?? 0;

    return {
      'users': userCount,
      'themes': themeCount,
      'projects': projectCount,
      'investments': investmentCount,
    };
  }
}