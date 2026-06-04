import sqlite3 from 'sqlite3';
import { promisify } from 'util';
import path from 'path';
import fs from 'fs';
import { databaseConfig } from '../config/database.config';
import { logger } from '../utils/logger';

class DatabaseConnection {
  private static instance: sqlite3.Database | null = null;
  private static isConnected: boolean = false;
  private static isInitializing: boolean = false;
  private static initPromise: Promise<void> | null = null;

  private constructor() {}

  public static async initialize(): Promise<void> {
    if (DatabaseConnection.isConnected) return;

    if (DatabaseConnection.isInitializing) {
      return DatabaseConnection.initPromise!;
    }

    DatabaseConnection.isInitializing = true;
    DatabaseConnection.initPromise = DatabaseConnection._initialize();
    await DatabaseConnection.initPromise;
    DatabaseConnection.isInitializing = false;
  }

  private static async _initialize(): Promise<void> {
    try {
      const dbPath = path.resolve(__dirname, '../../', databaseConfig.path);
      logger.info(`Connecting to database at: ${dbPath}`);

      // Asegurar que el directorio existe
      const dbDir = path.dirname(dbPath);
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
        logger.info(`Created database directory: ${dbDir}`);
      }

      DatabaseConnection.instance = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          logger.error('Failed to connect to database:', err);
          throw err;
        }
        DatabaseConnection.isConnected = true;
        logger.info('Database connected successfully');
      });

      DatabaseConnection.instance.serialize(() => {
        DatabaseConnection.instance?.run('PRAGMA journal_mode = WAL');
        DatabaseConnection.instance?.run('PRAGMA synchronous = NORMAL');
        DatabaseConnection.instance?.run('PRAGMA cache_size = -64000');
        DatabaseConnection.instance?.run('PRAGMA temp_store = MEMORY');
      });

      // Crear tablas si no existen
      await DatabaseConnection.createTables();

    } catch (error) {
      logger.error('Failed to connect to database:', error);
      throw error;
    }
  }

  public static getInstance(): sqlite3.Database {
    if (!DatabaseConnection.isConnected || !DatabaseConnection.instance) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return DatabaseConnection.instance!;
  }

  private static async createTables(): Promise<void> {
    const db = DatabaseConnection.instance!;
    const run = DatabaseConnection.promisify<void>(db, 'run');

    logger.info('Creating database tables...');

    // Tabla de usuarios
    await run(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        correo TEXT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        perfil TEXT NOT NULL,
        saldo REAL DEFAULT 0.0,
        activo INTEGER DEFAULT 1,
        fecha_registro TEXT,
        created_at TEXT,
        last_login TEXT
      )
    `);

    // Tabla de temas
    await run(`
      CREATE TABLE IF NOT EXISTS themes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        numero_proyectos INTEGER DEFAULT 0,
        total_invertido REAL DEFAULT 0.0,
        descripcion TEXT DEFAULT '',
        orden INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1
      )
    `);

    // Tabla de proyectos
    await run(`
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        imagen TEXT,
        tema_id TEXT NOT NULL,
        tema_nombre TEXT NOT NULL,
        tema_color TEXT,
        total_invertido REAL DEFAULT 0.0,
        numero_inversores INTEGER DEFAULT 0,
        created_at TEXT,
        activo INTEGER DEFAULT 1,
        pitch TEXT,
        problema TEXT,
        solucion TEXT,
        estrategia_ingresos TEXT,
        proyeccion_financiera TEXT,
        participantes TEXT,
        orden INTEGER,
        FOREIGN KEY (tema_id) REFERENCES themes(id)
      )
    `);

    // Tabla de inversiones
    await run(`
      CREATE TABLE IF NOT EXISTS investments (
        id TEXT PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        usuario_nombre TEXT NOT NULL,
        perfil TEXT NOT NULL,
        proyecto_id TEXT NOT NULL,
        proyecto_nombre TEXT NOT NULL,
        tema_id TEXT NOT NULL,
        tema_nombre TEXT NOT NULL,
        tema_color TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha_hora TEXT NOT NULL,
        observaciones TEXT,
        estado TEXT DEFAULT 'activa',
        FOREIGN KEY (usuario_id) REFERENCES users(id),
        FOREIGN KEY (proyecto_id) REFERENCES projects(id)
      )
    `);

    // Crear índices
    await run('CREATE INDEX IF NOT EXISTS idx_investments_user ON investments(usuario_id)');
    await run('CREATE INDEX IF NOT EXISTS idx_investments_project ON investments(proyecto_id)');
    await run('CREATE INDEX IF NOT EXISTS idx_investments_theme ON investments(tema_id)');
    await run('CREATE INDEX IF NOT EXISTS idx_projects_theme ON projects(tema_id)');
    await run('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');

    logger.info('Database tables created successfully');
  }

  public static close(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (DatabaseConnection.isConnected && DatabaseConnection.instance) {
        try {
          DatabaseConnection.instance!.close((err) => {
            if (err) {
              logger.error('Error closing database:', err);
              reject(err);
            } else {
              DatabaseConnection.isConnected = false;
              DatabaseConnection.instance = null;
              logger.info('Database connection closed');
              resolve();
            }
          });
        } catch (error) {
          logger.error('Error closing database:', error);
          reject(error);
        }
      } else {
        resolve();
      }
    });
  }

  public static isConnectedToDatabase(): boolean {
    return DatabaseConnection.isConnected;
  }

  public static promisify<T>(db: sqlite3.Database, method: string): (...args: any[]) => Promise<T> {
    return promisify(db[method].bind(db));
  }
}

export default DatabaseConnection;