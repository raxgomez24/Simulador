import { Investment } from '../../models/investment.model';
import DatabaseConnection from '../connection';
import { logger } from '../../utils/logger';

export class InvestmentRepository {
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

  public async findById(id: string): Promise<Investment | null> {
    try {
      const row = await this.get('SELECT * FROM investments WHERE id = ?', [id]);
      return row ? this.mapRowToInvestment(row) : null;
    } catch (error) {
      logger.error('Error finding investment by id:', error);
      throw error;
    }
  }

  public async findAll(): Promise<Investment[]> {
    try {
      const rows = await this.all('SELECT * FROM investments ORDER BY fecha_hora DESC');
      return rows.map(row => this.mapRowToInvestment(row));
    } catch (error) {
      logger.error('Error finding all investments:', error);
      throw error;
    }
  }

  public async findByUserId(userId: string): Promise<Investment[]> {
    try {
      const rows = await this.all('SELECT * FROM investments WHERE usuario_id = ? ORDER BY fecha_hora DESC', [userId]);
      return rows.map(row => this.mapRowToInvestment(row));
    } catch (error) {
      logger.error('Error finding investments by user id:', error);
      throw error;
    }
  }

  public async findByProjectId(projectId: string): Promise<Investment[]> {
    try {
      const rows = await this.all('SELECT * FROM investments WHERE proyecto_id = ? ORDER BY fecha_hora DESC', [projectId]);
      return rows.map(row => this.mapRowToInvestment(row));
    } catch (error) {
      logger.error('Error finding investments by project id:', error);
      throw error;
    }
  }

  public async findByThemeId(temaId: string): Promise<Investment[]> {
    try {
      const rows = await this.all('SELECT * FROM investments WHERE tema_id = ? ORDER BY fecha_hora DESC', [temaId]);
      return rows.map(row => this.mapRowToInvestment(row));
    } catch (error) {
      logger.error('Error finding investments by theme id:', error);
      throw error;
    }
  }

  public async create(investment: Investment): Promise<Investment> {
    try {
      await this.run(`
        INSERT INTO investments (id, usuario_id, usuario_nombre, perfil, proyecto_id, proyecto_nombre,
                               tema_id, tema_nombre, tema_color, monto, fecha_hora, observaciones, estado)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        investment.id,
        investment.usuarioId,
        investment.usuarioNombre,
        investment.perfil,
        investment.proyectoId,
        investment.proyectoNombre,
        investment.temaId,
        investment.temaNombre,
        investment.temaColor,
        investment.monto,
        investment.fechaHora.toISOString(),
        investment.observaciones,
        investment.estado
      ]);

      logger.info(`Investment created: ${investment.id} - ${investment.monto}`);
      return investment;
    } catch (error) {
      logger.error('Error creating investment:', error);
      throw error;
    }
  }

  public async updateStatus(id: string, estado: string): Promise<Investment> {
    try {
      const investment = await this.findById(id);
      if (!investment) {
        throw new Error('Investment not found');
      }

      investment.estado = estado as any;

      await this.run('UPDATE investments SET estado = ? WHERE id = ?', [estado, id]);

      logger.info(`Investment status updated: ${id} - ${estado}`);
      return investment;
    } catch (error) {
      logger.error('Error updating investment status:', error);
      throw error;
    }
  }

  public async getTotalInvestedByUser(userId: string): Promise<number> {
    try {
      const result = await this.get('SELECT COALESCE(SUM(monto), 0) as total FROM investments WHERE usuario_id = ? AND estado = ?', [userId, 'activa']);
      return result?.total || 0;
    } catch (error) {
      logger.error('Error getting total invested by user:', error);
      throw error;
    }
  }

  public async getTotalInvestedInProject(projectId: string): Promise<number> {
    try {
      const result = await this.get('SELECT COALESCE(SUM(monto), 0) as total FROM investments WHERE proyecto_id = ? AND estado = ?', [projectId, 'activa']);
      return result?.total || 0;
    } catch (error) {
      logger.error('Error getting total invested in project:', error);
      throw error;
    }
  }

  public async getInvestorCountForProject(projectId: string): Promise<number> {
    try {
      const result = await this.get('SELECT COUNT(DISTINCT usuario_id) as count FROM investments WHERE proyecto_id = ? AND estado = ?', [projectId, 'activa']);
      return result?.count || 0;
    } catch (error) {
      logger.error('Error getting investor count for project:', error);
      throw error;
    }
  }

  private mapRowToInvestment(row: any): Investment {
    return {
      id: row.id,
      usuarioId: row.usuario_id,
      usuarioNombre: row.usuario_nombre,
      perfil: row.perfil,
      proyectoId: row.proyecto_id,
      proyectoNombre: row.proyecto_nombre,
      temaId: row.tema_id,
      temaNombre: row.tema_nombre,
      temaColor: row.tema_color,
      monto: row.monto,
      fechaHora: new Date(row.fecha_hora),
      observaciones: row.observaciones,
      estado: row.estado as any,
    };
  }
}

export const investmentRepository = new InvestmentRepository();