import { Session, SessionState, toSessionResponse } from '../models/session.model';
import { sessionRepository } from '../database/repositories/session.repository';
import { logger } from '../utils/logger';
import { ErrorCodes } from '../config/app.config';
import { appConfig } from '../config/app.config';
import { v4 as uuidv4 } from 'uuid';

export class SessionService {
  private currentSession: Session | null = null;
  private sessionTimer: NodeJS.Timeout | null = null;

  public async getCurrentSession(): Promise<Session | null> {
    if (!this.currentSession) {
      this.currentSession = await sessionRepository.findActiveSession();
    }
    return this.currentSession;
  }

  public async createSession(tiempoTotal: number = appConfig.roundDuration): Promise<Session> {
    try {
      if (this.currentSession) {
        throw { code: ErrorCodes.SERVER_ERROR, message: 'A session is already active' };
      }

      const session: Session = {
        id: uuidv4(),
        tiempoRestante: tiempoTotal,
        tiempoTotal,
        estado: 'waiting',
        numeroParticipantes: 0,
        numeroProyectos: 0,
        totalInvertido: 0,
        startedAt: new Date(),
      };

      this.currentSession = await sessionRepository.create(session);
      logger.info(`Session created: ${session.id}`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Create session error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to create session' };
    }
  }

  public async startSession(sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      if (session.estado === 'active') {
        throw { code: ErrorCodes.SERVER_ERROR, message: 'Session is already active' };
      }

      session.estado = 'active';
      session.startedAt = new Date();

      this.currentSession = await sessionRepository.update(session);

      this.startSessionTimer();

      logger.info(`Session started: ${session.id}`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Start session error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to start session' };
    }
  }

  public async pauseSession(sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      if (session.estado !== 'active') {
        throw { code: ErrorCodes.SERVER_ERROR, message: 'Session is not active' };
      }

      session.estado = 'paused';

      this.currentSession = await sessionRepository.update(session);

      this.stopSessionTimer();

      logger.info(`Session paused: ${session.id}`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Pause session error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to pause session' };
    }
  }

  public async resumeSession(sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      if (session.estado !== 'paused') {
        throw { code: ErrorCodes.SERVER_ERROR, message: 'Session is not paused' };
      }

      session.estado = 'active';

      this.currentSession = await sessionRepository.update(session);

      this.startSessionTimer();

      logger.info(`Session resumed: ${session.id}`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Resume session error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to resume session' };
    }
  }

  public async endSession(sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      if (session.estado === 'ended') {
        throw { code: ErrorCodes.SERVER_ERROR, message: 'Session is already ended' };
      }

      session.estado = 'ended';
      session.tiempoRestante = 0;
      session.endedAt = new Date();

      this.currentSession = await sessionRepository.update(session);

      this.stopSessionTimer();

      logger.info(`Session ended: ${session.id}`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('End session error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to end session' };
    }
  }

  public async updateSessionTime(tiempoRestante: number, sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      session.tiempoRestante = Math.max(0, tiempoRestante);

      if (session.tiempoRestante <= 0 && session.estado !== 'ended') {
        session.estado = 'ended';
        session.endedAt = new Date();
        this.stopSessionTimer();
      }

      this.currentSession = await sessionRepository.update(session);

      logger.info(`Session time updated: ${session.id} - ${session.tiempoRestante}s`);
      return this.currentSession;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Update session time error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to update session time' };
    }
  }

  public async updateSessionStats(numeroParticipantes: number, numeroProyectos: number, totalInvertido: number, sessionId?: string): Promise<Session> {
    try {
      let session: Session | null;

      if (sessionId) {
        session = await sessionRepository.findById(sessionId);
      } else {
        session = this.currentSession;
      }

      if (!session) {
        throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Session not found' };
      }

      this.currentSession = await sessionRepository.updateParticipantsAndStats(
        session.id,
        numeroParticipantes,
        numeroProyectos,
        totalInvertido
      );

      return this.currentSession;
    } catch (error: any) {
      logger.error('Update session stats error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Failed to update session stats' };
    }
  }

  private startSessionTimer(): void {
    this.stopSessionTimer();

    this.sessionTimer = setInterval(async () => {
      if (!this.currentSession || this.currentSession.estado !== 'active') {
        this.stopSessionTimer();
        return;
      }

      if (this.currentSession.tiempoRestante > 0) {
        this.currentSession.tiempoRestante--;
        await sessionRepository.updateTiempoRestante(this.currentSession.id, this.currentSession.tiempoRestante);
      } else {
        await this.endSession(this.currentSession.id);
      }
    }, 1000);
  }

  private stopSessionTimer(): void {
    if (this.sessionTimer) {
      clearInterval(this.sessionTimer);
      this.sessionTimer = null;
    }
  }

  public cleanup(): void {
    this.stopSessionTimer();
  }
}

export const sessionService = new SessionService();