import { Session } from '../../models/session.model';
import DatabaseConnection from '../connection';
import { logger } from '../../utils/logger';

export class SessionRepository {
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

  public async findById(id: string): Promise<Session | null> {
    try {
      const row = await this.get('SELECT * FROM sessions WHERE id = ?', [id]);
      return row ? this.mapRowToSession(row) : null;
    } catch (error) {
      logger.error('Error finding session by id:', error);
      throw error;
    }
  }

  public async findActiveSession(): Promise<Session | null> {
    try {
      const row = await this.get("SELECT * FROM sessions WHERE estado IN ('active', 'paused') ORDER BY created_at DESC LIMIT 1");
      return row ? this.mapRowToSession(row) : null;
    } catch (error) {
      logger.error('Error finding active session:', error);
      throw error;
    }
  }

  public async findAll(): Promise<Session[]> {
    try {
      const rows = await this.all('SELECT * FROM sessions ORDER BY created_at DESC');
      return rows.map(row => this.mapRowToSession(row));
    } catch (error) {
      logger.error('Error finding all sessions:', error);
      throw error;
    }
  }

  public async create(session: Session): Promise<Session> {
    try {
      await this.run(`
        INSERT INTO sessions (id, tiempo_restante, tiempo_total, estado, numero_participantes, numero_proyectos, total_invertido, started_at, ended_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        session.id,
        session.tiempoRestante,
        session.tiempoTotal,
        session.estado,
        session.numeroParticipantes,
        session.numeroProyectos,
        session.totalInvertido,
        session.startedAt?.toISOString(),
        session.endedAt?.toISOString()
      ]);

      logger.info(`Session created: ${session.id}`);
      return session;
    } catch (error) {
      logger.error('Error creating session:', error);
      throw error;
    }
  }

  public async update(session: Session): Promise<Session> {
    try {
      await this.run(`
        UPDATE sessions
        SET tiempo_restante = ?, estado = ?, numero_participantes = ?, numero_proyectos = ?, total_invertido = ?, ended_at = ?
        WHERE id = ?
      `, [
        session.tiempoRestante,
        session.estado,
        session.numeroParticipantes,
        session.numeroProyectos,
        session.totalInvertido,
        session.endedAt?.toISOString(),
        session.id
      ]);

      logger.info(`Session updated: ${session.id}`);
      return session;
    } catch (error) {
      logger.error('Error updating session:', error);
      throw error;
    }
  }

  public async updateTiempoRestante(sessionId: string, tiempoRestante: number): Promise<Session> {
    try {
      const session = await this.findById(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      session.tiempoRestante = tiempoRestante;

      if (tiempoRestante <= 0 && session.estado !== 'ended') {
        session.estado = 'ended' as any;
        session.endedAt = new Date();
      }

      return await this.update(session);
    } catch (error) {
      logger.error('Error updating session tiempo restante:', error);
      throw error;
    }
  }

  public async updateEstado(sessionId: string, estado: string): Promise<Session> {
    try {
      const session = await this.findById(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      session.estado = estado as any;

      if (estado === 'ended' && !session.endedAt) {
        session.endedAt = new Date();
      } else if (estado === 'active' && !session.startedAt) {
        session.startedAt = new Date();
      }

      return await this.update(session);
    } catch (error) {
      logger.error('Error updating session estado:', error);
      throw error;
    }
  }

  public async updateParticipantsAndStats(sessionId: string, numeroParticipantes: number, numeroProyectos: number, totalInvertido: number): Promise<Session> {
    try {
      const session = await this.findById(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      session.numeroParticipantes = numeroParticipantes;
      session.numeroProyectos = numeroProyectos;
      session.totalInvertido = totalInvertido;

      return await this.update(session);
    } catch (error) {
      logger.error('Error updating session participants and stats:', error);
      throw error;
    }
  }

  private mapRowToSession(row: any): Session {
    return {
      id: row.id,
      tiempoRestante: row.tiempo_restante,
      tiempoTotal: row.tiempo_total,
      estado: row.estado as any,
      numeroParticipantes: row.numero_participantes,
      numeroProyectos: row.numero_proyectos,
      totalInvertido: row.total_invertido,
      startedAt: row.started_at ? new Date(row.started_at) : undefined,
      endedAt: row.ended_at ? new Date(row.ended_at) : undefined,
    };
  }
}

export const sessionRepository = new SessionRepository();