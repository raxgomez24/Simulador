import { Project } from '../../models/project.model';
import DatabaseConnection from '../connection';
import { logger } from '../../utils/logger';

export class ProjectRepository {
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

  public async findById(id: string): Promise<Project | null> {
    try {
      const row = await this.get('SELECT * FROM projects WHERE id = ?', [id]);
      return row ? this.mapRowToProject(row) : null;
    } catch (error) {
      logger.error('Error finding project by id:', error);
      throw error;
    }
  }

  public async findAll(): Promise<Project[]> {
    try {
      const rows = await this.all('SELECT * FROM projects WHERE activo = 1 ORDER BY orden ASC, nombre ASC');
      return rows.map(row => this.mapRowToProject(row));
    } catch (error) {
      logger.error('Error finding all projects:', error);
      throw error;
    }
  }

  public async findByThemeId(temaId: string): Promise<Project[]> {
    try {
      const rows = await this.all('SELECT * FROM projects WHERE tema_id = ? AND activo = 1 ORDER BY orden ASC', [temaId]);
      return rows.map(row => this.mapRowToProject(row));
    } catch (error) {
      logger.error('Error finding projects by theme id:', error);
      throw error;
    }
  }

  public async create(project: Project): Promise<Project> {
    try {
      const participantesJson = project.participantes.length > 0 ? JSON.stringify(project.participantes) : null;

      await this.run(`
        INSERT INTO projects (id, nombre, descripcion, imagen, tema_id, tema_nombre, tema_color,
                            total_invertido, numero_inversores, created_at, activo, pitch,
                            problema, solucion, estrategia_ingresos, proyeccion_financiera,
                            participantes, orden)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        project.id,
        project.nombre,
        project.descripcion,
        project.imagen,
        project.temaId,
        project.temaNombre,
        project.temaColor,
        project.totalInvertido,
        project.numeroInversores,
        project.createdAt?.toISOString(),
        project.activo ? 1 : 0,
        project.pitch,
        project.problema,
        project.solucion,
        project.estrategiaIngresos,
        project.proyeccionFinanciera,
        participantesJson,
        project.orden
      ]);

      logger.info(`Project created: ${project.nombre}`);
      return project;
    } catch (error) {
      logger.error('Error creating project:', error);
      throw error;
    }
  }

  public async update(project: Project): Promise<Project> {
    try {
      const participantesJson = project.participantes.length > 0 ? JSON.stringify(project.participantes) : null;

      await this.run(`
        UPDATE projects
        SET nombre = ?, descripcion = ?, imagen = ?, tema_id = ?, tema_nombre = ?, tema_color = ?,
            total_invertido = ?, numero_inversores = ?, activo = ?, pitch = ?, problema = ?,
            solucion = ?, estrategia_ingresos = ?, proyeccion_financiera = ?, participantes = ?, orden = ?
        WHERE id = ?
      `, [
        project.nombre,
        project.descripcion,
        project.imagen,
        project.temaId,
        project.temaNombre,
        project.temaColor,
        project.totalInvertido,
        project.numeroInversores,
        project.activo ? 1 : 0,
        project.pitch,
        project.problema,
        project.solucion,
        project.estrategiaIngresos,
        project.proyeccionFinanciera,
        participantesJson,
        project.orden,
        project.id
      ]);

      logger.info(`Project updated: ${project.nombre}`);
      return project;
    } catch (error) {
      logger.error('Error updating project:', error);
      throw error;
    }
  }

  public async updateInvestmentStats(projectId: string, amount: number, isInvesting: boolean): Promise<Project> {
    try {
      const project = await this.findById(projectId);
      if (!project) {
        throw new Error('Project not found');
      }

      const delta = isInvesting ? amount : -amount;
      const investorDelta = isInvesting ? 1 : -1;

      project.totalInvertido = Math.max(0, project.totalInvertido + delta);
      project.numeroInversores = Math.max(0, project.numeroInversores + investorDelta);

      return await this.update(project);
    } catch (error) {
      logger.error('Error updating project investment stats:', error);
      throw error;
    }
  }

  public async deactivate(projectId: string): Promise<void> {
    try {
      await this.run('UPDATE projects SET activo = 0 WHERE id = ?', [projectId]);
      logger.info(`Project deactivated: ${projectId}`);
    } catch (error) {
      logger.error('Error deactivating project:', error);
      throw error;
    }
  }

  private mapRowToProject(row: any): Project {
    let participantes: Array<{ nombre: string; rol: string }> = [];

    if (row.participantes) {
      try {
        if (typeof row.participantes === 'string') {
          participantes = JSON.parse(row.participantes);
        } else {
          participantes = row.participantes;
        }
      } catch (error) {
        logger.warn('Failed to parse participantes JSON:', error);
      }
    }

    return {
      id: row.id,
      nombre: row.nombre,
      descripcion: row.descripcion,
      imagen: row.imagen,
      temaId: row.tema_id,
      temaNombre: row.tema_nombre,
      temaColor: row.tema_color,
      totalInvertido: row.total_invertido,
      numeroInversores: row.numero_inversores,
      createdAt: row.created_at ? new Date(row.created_at) : undefined,
      activo: row.activo === 1 || row.activo === true,
      pitch: row.pitch,
      problema: row.problema,
      solucion: row.solucion,
      estrategiaIngresos: row.estrategia_ingresos,
      proyeccionFinanciera: row.proyeccion_financiera,
      participantes,
      orden: row.orden,
    };
  }
}

export const projectRepository = new ProjectRepository();