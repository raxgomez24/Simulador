import WebSocket from 'ws';
import { WSMessage, AuthMessage, InvestMessage, SessionUpdateMessage, SyncRequestMessage, HeartbeatMessage } from '../models/message.model';
import { authHandler } from './auth.handler';
import { investHandler } from './invest.handler';
import { sessionHandler } from './session.handler';
import { syncHandler } from './sync.handler';
import { logger } from '../utils/logger';
import { ErrorMessage } from '../models/message.model';
import { ErrorCodes } from '../config/app.config';

export interface WebSocketContext {
  ws: WebSocket;
  userId?: string;
  username?: string;
  isAdmin: boolean;
}

export class MessageHandler {

  public async handleMessage(message: WSMessage, context: WebSocketContext): Promise<void> {
    try {
      switch (message.type) {
        case 'auth':
          await authHandler.handleAuth(message as AuthMessage, context);
          break;

        case 'invest':
          await investHandler.handleInvest(message as InvestMessage, context);
          break;

        case 'session_update':
          await sessionHandler.handleSessionUpdate(message as SessionUpdateMessage, context);
          break;

        case 'sync_request':
          await syncHandler.handleSyncRequest(message as SyncRequestMessage, context);
          break;

        case 'heartbeat':
          this.handleHeartbeat(message as HeartbeatMessage, context);
          break;

        default:
          logger.warn(`Unknown message type: ${message.type}`);
          this.sendError(context.ws, 'SERVER_ERROR', `Unknown message type: ${message.type}`);
      }
    } catch (error: any) {
      logger.error('Error handling message:', error);
      const errorCode = error.code || ErrorCodes.SERVER_ERROR;
      const errorMessage = error.message || 'An error occurred while processing the message';
      this.sendError(context.ws, errorCode, errorMessage);
    }
  }

  private handleHeartbeat(message: HeartbeatMessage, context: WebSocketContext): void {
    const pongMessage = {
      type: 'pong',
      timestamp: new Date().toISOString(),
    };

    try {
      context.ws.send(JSON.stringify(pongMessage));
      logger.debug(`Pong sent to ${context.username || 'unknown client'}`);
    } catch (error) {
      logger.error('Error sending pong:', error);
    }
  }

  private sendError(ws: WebSocket, code: string, message: string): void {
    const errorMessage: ErrorMessage = {
      type: 'error',
      code,
      message,
      timestamp: new Date().toISOString(),
    };

    try {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(errorMessage));
      }
    } catch (error) {
      logger.error('Error sending error message:', error);
    }
  }
}

export const messageHandler = new MessageHandler();