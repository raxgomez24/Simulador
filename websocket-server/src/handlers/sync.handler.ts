import WebSocket from 'ws';
import { SyncRequestMessage, SyncResponseMessage } from '../models/message.model';
import { WebSocketContext } from './message.handler';
import { syncService } from '../services/sync.service';
import { logger } from '../utils/logger';
import { ErrorCodes, ResponseStatus } from '../config/app.config';
import { toUserResponse } from '../models/user.model';
import { toProjectResponse } from '../models/project.model';
import { toInvestmentResponse } from '../models/investment.model';
import { toSessionResponse } from '../models/session.model';
import { toThemeResponse } from '../models/theme.model';

export class SyncHandler {
  public async handleSyncRequest(message: SyncRequestMessage, context: WebSocketContext): Promise<void> {
    try {
      if (!context.userId) {
        this.sendSyncError(context.ws, ErrorCodes.UNAUTHORIZED, 'You must be authenticated to sync data');
        return;
      }

      const { userId } = message;

      let syncData;

      if (userId && userId !== context.userId && context.isAdmin) {
        syncData = await syncService.getUserSyncData(userId);
      } else {
        syncData = await syncService.getFullSyncData();
      }

      const users = (syncData as any).users ? (syncData as any).users.map(toUserResponse) : undefined;
      const projects = syncData.projects.map(toProjectResponse);
      const investments = syncData.investments.map(toInvestmentResponse);
      const session = syncData.session ? toSessionResponse(syncData.session) : undefined;
      const themes = syncData.themes.map(toThemeResponse);
      const ranking = syncData.ranking.map(toUserResponse);

      const response: SyncResponseMessage = {
        type: 'sync_request',
        status: ResponseStatus.SUCCESS,
        data: {
          users,
          projects,
          investments,
          session,
          themes,
          ranking,
        },
      };

      context.ws.send(JSON.stringify(response));
      logger.info(`Sync data sent to: ${context.username}`);
    } catch (error: any) {
      logger.error('Sync error:', error);
      this.sendSyncError(context.ws, error.code || ErrorCodes.SERVER_ERROR, error.message || 'Sync failed');
    }
  }

  private sendSyncError(ws: WebSocket, code: string, message: string): void {
    const response: SyncResponseMessage = {
      type: 'sync_request',
      status: ResponseStatus.ERROR,
      error: { code, message },
    };

    try {
      ws.send(JSON.stringify(response));
    } catch (error) {
      logger.error('Error sending sync error:', error);
    }
  }
}

export const syncHandler = new SyncHandler();