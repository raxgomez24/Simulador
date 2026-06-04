import WebSocket from 'ws';
import { ConnectionManager } from '../websocket/connection.manager';
import { logger } from '../utils/logger';

export class BroadcastService {
  private connectionManager: ConnectionManager;

  constructor(connectionManager: ConnectionManager) {
    this.connectionManager = connectionManager;
  }

  public broadcastToAll(message: object): void {
    const messageStr = JSON.stringify(message);
    const clients = this.connectionManager.getAllClients();

    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        try {
          client.send(messageStr);
        } catch (error) {
          logger.error('Error broadcasting to client:', error);
        }
      }
    });

    logger.debug(`Broadcasted message to ${clients.length} clients`);
  }

  public broadcastToUser(userId: string, message: object): void {
    const messageStr = JSON.stringify(message);
    const client = this.connectionManager.getClientByUserId(userId);

    if (client && client.readyState === WebSocket.OPEN) {
      try {
        client.send(messageStr);
        logger.debug(`Broadcasted message to user: ${userId}`);
      } catch (error) {
        logger.error(`Error broadcasting to user ${userId}:`, error);
      }
    }
  }

  public broadcastToAdmins(message: object): void {
    const messageStr = JSON.stringify(message);
    const clients = this.connectionManager.getAdminClients();

    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        try {
          client.send(messageStr);
        } catch (error) {
          logger.error('Error broadcasting to admin:', error);
        }
      }
    });

    logger.debug(`Broadcasted message to ${clients.length} admin clients`);
  }

  public broadcastToOthers(userId: string, message: object): void {
    const messageStr = JSON.stringify(message);
    const clients = this.connectionManager.getAllClientsExcept(userId);

    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        try {
          client.send(messageStr);
        } catch (error) {
          logger.error('Error broadcasting to client:', error);
        }
      }
    });

    logger.debug(`Broadcasted message to all clients except: ${userId}`);
  }
}

export default BroadcastService;