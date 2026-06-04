import WebSocket from 'ws';
import { SessionUpdateMessage, SessionUpdateResponseMessage } from '../models/message.model';
import { WebSocketContext } from './message.handler';
import { sessionService } from '../services/session.service';
import { logger } from '../utils/logger';
import { ConnectionManager } from '../websocket/connection.manager';
import { BroadcastService } from '../services/broadcast.service';
import { ErrorCodes } from '../config/app.config';
import { toSessionResponse } from '../models/session.model';

export class SessionHandler {
  private broadcastService: BroadcastService;

  constructor() {
    const connectionManager = ConnectionManager.getInstance();
    this.broadcastService = new BroadcastService(connectionManager);
  }

  public async handleSessionUpdate(message: SessionUpdateMessage, context: WebSocketContext): Promise<void> {
    try {
      if (!context.userId) {
        this.sendSessionError(context.ws, ErrorCodes.UNAUTHORIZED, 'You must be authenticated to update session');
        return;
      }

      if (!context.isAdmin) {
        this.sendSessionError(context.ws, ErrorCodes.UNAUTHORIZED, 'Only admins can update session');
        return;
      }

      const { action, tiempoRestante } = message;

      let session;

      switch (action) {
        case 'start':
          session = await sessionService.startSession();
          break;

        case 'pause':
          session = await sessionService.pauseSession();
          break;

        case 'resume':
          session = await sessionService.resumeSession();
          break;

        case 'end':
          session = await sessionService.endSession();
          break;

        case 'update_time':
          if (tiempoRestante === undefined) {
            this.sendSessionError(context.ws, 'INVALID_AMOUNT', 'tiempoRestante is required for update_time action');
            return;
          }
          session = await sessionService.updateSessionTime(tiempoRestante);
          break;

        default:
          this.sendSessionError(context.ws, ErrorCodes.SERVER_ERROR, `Unknown action: ${action}`);
          return;
      }

      const response: SessionUpdateResponseMessage = {
        type: 'session_update',
        session: toSessionResponse(session),
      };

      context.ws.send(JSON.stringify(response));

      const broadcastMessage: SessionUpdateResponseMessage = {
        type: 'session_update',
        session: toSessionResponse(session),
      };

      this.broadcastService.broadcastToAll(broadcastMessage);

      logger.info(`Session ${action}ed by admin: ${context.username}`);
    } catch (error: any) {
      logger.error('Session update error:', error);
      this.sendSessionError(context.ws, error.code || ErrorCodes.SERVER_ERROR, error.message || 'Session update failed');
    }
  }

  private sendSessionError(ws: WebSocket, code: string, message: string): void {
    const response: SessionUpdateResponseMessage = {
      type: 'session_update',
      error: { code, message },
    };

    try {
      ws.send(JSON.stringify(response));
    } catch (error) {
      logger.error('Error sending session error:', error);
    }
  }
}

export const sessionHandler = new SessionHandler();