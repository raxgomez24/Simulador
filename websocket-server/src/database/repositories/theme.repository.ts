import { Theme } from '../../models/theme.model';
import DatabaseConnection from '../connection';
import { logger } from '../../utils/logger';

export class ThemeRepository {
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

  public async findById(id: string): Promise<Theme | null> {
    try {
      const row = await this.get('SELECT * FROM themes WHERE id = ?', [id]);
      return row ? this.mapRowToTheme(row) : null;
    } catch (error) {
      logger.error('Error finding theme by id:', error);
      throw error;
    }
  }

  public async findAll(): Promise<Theme[]> {
    try {
      const rows = await this.all('SELECT * FROM themes WHERE activo = 1 ORDER BY orden ASC');
      return rows.map(row => this.mapRowToTheme(row));
    } catch (error) {
      logger.error('Error finding all themes:', error);
      throw error;
    }
  }

  public async create(theme: Theme): Promise<Theme> {
    try {
      await this.run(`
        INSERT INTO themes (id, nombre, color, icon, numero_proyectos, total_invertido, descripcion, orden, activo)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        theme.id,
        theme.nombre,
        theme.color,
        theme.icon,
        theme.numeroProyectos,
        theme.totalInvertido,
        theme.descripcion,
        theme.orden,
        theme.activo ? 1 : 0
      ]);

      logger.info(`Theme created: ${theme.nombre}`);
      return theme;
    } catch (error) {
      logger.error('Error creating theme:', error);
      throw error;
    }
  }

  public async update(theme: Theme): Promise<Theme> {
    try {
      await this.run(`
        UPDATE themes
        SET nombre = ?, color = ?, icon = ?, numero_proyectos = ?, total_invertido = ?, descripcion = ?, orden = ?, activo = ?
        WHERE id = ?
      `, [
        theme.nombre,
        theme.color,
        theme.icon,
        theme.numeroProyectos,
        theme.totalInvertido,
        theme.descripcion,
        theme.orden,
        theme.activo ? 1 : 0,
        theme.id
      ]);

      logger.info(`Theme updated: ${theme.nombre}`);
      return theme;
    } catch (error) {
      logger.error('Error updating theme:', error);
      throw error;
    }
  }

  public async updateInvestmentStats(themeId: string, deltaProjects: number, deltaInvested: number): Promise<Theme> {
    try {
      const theme = await this.findById(themeId);
      if (!theme) {
        throw new Error('Theme not found');
      }

      theme.numeroProyectos = Math.max(0, theme.numeroProyectos + deltaProjects);
      theme.totalInvertido = Math.max(0, theme.totalInvertido + deltaInvested);

      return await this.update(theme);
    } catch (error) {
      logger.error('Error updating theme investment stats:', error);
      throw error;
    }
  }

  public async deactivate(themeId: string): Promise<void> {
    try {
      await this.run('UPDATE themes SET activo = 0 WHERE id = ?', [themeId]);
      logger.info(`Theme deactivated: ${themeId}`);
    } catch (error) {
      logger.error('Error deactivating theme:', error);
      throw error;
    }
  }

  private mapRowToTheme(row: any): Theme {
    return {
      id: row.id,
      nombre: row.nombre,
      color: row.color,
      icon: row.icon,
      numeroProyectos: row.numero_proyectos,
      totalInvertido: row.total_invertido,
      descripcion: row.descripcion,
      orden: row.orden,
      activo: row.activo === 1 || row.activo === true,
    };
  }
}

export const themeRepository = new ThemeRepository();