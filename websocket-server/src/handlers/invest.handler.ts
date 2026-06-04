import WebSocket from 'ws';
import { InvestMessage, InvestResponseMessage } from '../models/message.model';
import { WebSocketContext } from './message.handler';
import { investmentService } from '../services/investment.service';
import { logger } from '../utils/logger';
import { ConnectionManager } from '../websocket/connection.manager';
import { BroadcastService } from '../services/broadcast.service';
import { ErrorCodes, ResponseStatus } from '../config/app.config';
import { toInvestmentResponse } from '../models/investment.model';
import { toUserResponse } from '../models/user.model';
import { toProjectResponse } from '../models/project.model';

export class InvestHandler {
  private broadcastService: BroadcastService;

  constructor() {
    const connectionManager = ConnectionManager.getInstance();
    this.broadcastService = new BroadcastService(connectionManager);
  }

  public async handleInvest(message: InvestMessage, context: WebSocketContext): Promise<void> {
    try {
      if (!context.userId) {
        this.sendInvestError(context.ws, ErrorCodes.UNAUTHORIZED, 'You must be authenticated to make an investment');
        return;
      }

      const { projectId, amount, observations } = message;

      if (!projectId || !amount) {
        this.sendInvestError(context.ws, ErrorCodes.INVALID_AMOUNT, 'Project ID and amount are required');
        return;
      }

      const result = await investmentService.makeInvestment(context.userId, projectId, amount, observations);

      const response: InvestResponseMessage = {
        type: 'invest',
        status: ResponseStatus.SUCCESS,
        investment: toInvestmentResponse(result.investment),
        user: toUserResponse(result.user),
        project: toProjectResponse(result.project),
      };

      context.ws.send(JSON.stringify(response));

      const broadcastMessage: InvestResponseMessage = {
        type: 'invest',
        status: ResponseStatus.SUCCESS,
        investment: toInvestmentResponse(result.investment),
        user: toUserResponse(result.user),
        project: toProjectResponse(result.project),
      };

      this.broadcastService.broadcastToOthers(context.userId!, broadcastMessage);

      logger.info(`Investment processed: ${context.username} invested ${amount} in ${projectId}`);
    } catch (error: any) {
      logger.error('Investment error:', error);
      this.sendInvestError(context.ws, error.code || ErrorCodes.SERVER_ERROR, error.message || 'Investment failed');
    }
  }

  private sendInvestError(ws: WebSocket, code: string, message: string): void {
    const response: InvestResponseMessage = {
      type: 'invest',
      status: ResponseStatus.ERROR,
      error: { code, message },
    };

    try {
      ws.send(JSON.stringify(response));
    } catch (error) {
      logger.error('Error sending invest error:', error);
    }
  }
}

export const investHandler = new InvestHandler();