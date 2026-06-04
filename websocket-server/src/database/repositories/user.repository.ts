import { User, UserProfile } from '../../models/user.model';
import DatabaseConnection from '../connection';
import { logger } from '../../utils/logger';

export class UserRepository {
  private get db() {
    return DatabaseConnection.getInstance();
  }

  private run(sql: string, params: any[] = []): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err: any) {
        if (err) reject(err);
        else resolve(this);
      });
    });
  }

  private get(sql: string, params: any[] = []): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err: any, row: any) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  private all(sql: string, params: any[] = []): Promise<any[]> {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err: any, rows: any[]) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    });
  }

  public async findById(id: string): Promise<User | null> {
    try {
      const row = await this.get('SELECT * FROM users WHERE id = ?', [id]);
      return row ? this.mapRowToUser(row) : null;
    } catch (error) {
      logger.error('Error finding user by id:', error);
      throw error;
    }
  }

  public async findByUsername(username: string): Promise<User | null> {
    try {
      const row = await this.get('SELECT * FROM users WHERE username = ?', [username]);
      return row ? this.mapRowToUser(row) : null;
    } catch (error) {
      logger.error('Error finding user by username:', error);
      throw error;
    }
  }

  public async findAll(): Promise<User[]> {
    try {
      const rows = await this.all('SELECT * FROM users WHERE activo = 1');
      return rows.map(row => this.mapRowToUser(row));
    } catch (error) {
      logger.error('Error finding all users:', error);
      throw error;
    }
  }

  public async findByProfile(perfil: UserProfile): Promise<User[]> {
    try {
      const rows = await this.all('SELECT * FROM users WHERE perfil = ? AND activo = 1', [perfil]);
      return rows.map(row => this.mapRowToUser(row));
    } catch (error) {
      logger.error('Error finding users by profile:', error);
      throw error;
    }
  }

  public async create(user: User): Promise<User> {
    try {
      await this.run(`
        INSERT INTO users (id, nombre, correo, username, password, perfil, saldo, activo, fecha_registro)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        user.id,
        user.nombre,
        user.correo,
        user.username,
        user.password,
        user.perfil,
        user.saldo,
        user.activo ? 1 : 0,
        user.fechaRegistro?.toISOString()
      ]);

      logger.info(`User created: ${user.username}`);
      return user;
    } catch (error) {
      logger.error('Error creating user:', error);
      throw error;
    }
  }

  public async update(user: User): Promise<User> {
    try {
      await this.run(`
        UPDATE users
        SET nombre = ?, correo = ?, username = ?, password = ?, perfil = ?, saldo = ?, activo = ?
        WHERE id = ?
      `, [
        user.nombre,
        user.correo,
        user.username,
        user.password,
        user.perfil,
        user.saldo,
        user.activo ? 1 : 0,
        user.id
      ]);

      logger.info(`User updated: ${user.username}`);
      return user;
    } catch (error) {
      logger.error('Error updating user:', error);
      throw error;
    }
  }

  public async updateBalance(userId: string, delta: number): Promise<User> {
    try {
      const user = await this.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      const newBalance = user.saldo + delta;
      if (newBalance < 0) {
        throw new Error('Insufficient funds');
      }

      user.saldo = newBalance;
      return await this.update(user);
    } catch (error) {
      logger.error('Error updating user balance:', error);
      throw error;
    }
  }

  public async deactivate(userId: string): Promise<void> {
    try {
      await this.run('UPDATE users SET activo = 0 WHERE id = ?', [userId]);
      logger.info(`User deactivated: ${userId}`);
    } catch (error) {
      logger.error('Error deactivating user:', error);
      throw error;
    }
  }

  public async getRanking(): Promise<User[]> {
    try {
      const rows = await this.all(`
        SELECT * FROM users
        WHERE activo = 1 AND perfil = 'student'
        ORDER BY saldo DESC
      `);
      return rows.map(row => this.mapRowToUser(row));
    } catch (error) {
      logger.error('Error getting ranking:', error);
      throw error;
    }
  }

  private mapRowToUser(row: any): User {
    return {
      id: row.id,
      nombre: row.nombre,
      correo: row.correo,
      username: row.username,
      password: row.password,
      perfil: row.perfil as UserProfile,
      saldo: row.saldo,
      activo: row.activo === 1 || row.activo === true,
      fechaRegistro: row.fecha_registro ? new Date(row.fecha_registro) : undefined,
    };
  }
}

// Singleton exportado correctamente
export const userRepository = new UserRepository();