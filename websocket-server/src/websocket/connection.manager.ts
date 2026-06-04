import WebSocket from 'ws';
import { websocketConfig } from '../config/websocket.config';
import { logger } from '../utils/logger';
import { WebSocketContext } from '../handlers/message.handler';

export class ConnectionManager {
  private static instance: ConnectionManager;
  private connections: Map<WebSocket, WebSocketContext>;
  private userIdToWs: Map<string, WebSocket>;
  private adminClients: Set<WebSocket>;

  private constructor() {
    this.connections = new Map();
    this.userIdToWs = new Map();
    this.adminClients = new Set();
  }

  public static getInstance(): ConnectionManager {
    if (!ConnectionManager.instance) {
      ConnectionManager.instance = new ConnectionManager();
    }
    return ConnectionManager.instance;
  }

  public addConnection(ws: WebSocket): void {
    const context: WebSocketContext = {
      ws,
      userId: undefined,
      username: undefined,
      isAdmin: false,
    };

    this.connections.set(ws, context);
    logger.info(`Connection added. Total connections: ${this.connections.size}`);

    if (this.connections.size > websocketConfig.maxClients) {
      logger.warn(`Maximum number of connections (${websocketConfig.maxClients}) reached`);
    }
  }

  public removeConnection(ws: WebSocket): void {
    const context = this.connections.get(ws);

    if (context && context.userId) {
      this.userIdToWs.delete(context.userId);
    }

    if (context && context.isAdmin) {
      this.adminClients.delete(ws);
    }

    this.connections.delete(ws);
    logger.info(`Connection removed. Total connections: ${this.connections.size}`);
  }

  public removeAllConnections(): void {
    this.connections.forEach((context, ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.close();
      }
    });

    this.connections.clear();
    this.userIdToWs.clear();
    this.adminClients.clear();
    logger.info('All connections removed');
  }

  public registerUser(ws: WebSocket, userId: string, username: string, isAdmin: boolean): void {
    const context = this.connections.get(ws);

    if (context) {
      context.userId = userId;
      context.username = username;
      context.isAdmin = isAdmin;

      this.userIdToWs.set(userId, ws);

      if (isAdmin) {
        this.adminClients.add(ws);
      }

      logger.info(`User registered: ${username} (${userId}), Admin: ${isAdmin}`);
    }
  }

  public getConnectionContext(ws: WebSocket): WebSocketContext {
    return this.connections.get(ws) || {
      ws,
      userId: undefined,
      username: undefined,
      isAdmin: false,
    };
  }

  public getClientByUserId(userId: string): WebSocket | undefined {
    return this.userIdToWs.get(userId);
  }

  public getAllClients(): WebSocket[] {
    return Array.from(this.connections.keys());
  }

  public getAllClientsExcept(userId: string): WebSocket[] {
    return Array.from(this.connections.entries())
      .filter(([_, context]) => context.userId !== userId)
      .map(([ws]) => ws);
  }

  public getAdminClients(): WebSocket[] {
    return Array.from(this.adminClients);
  }

  public getConnectionCount(): number {
    return this.connections.size;
  }

  public getUserCount(): number {
    return this.userIdToWs.size;
  }

  public getAdminCount(): number {
    return this.adminClients.size;
  }
}

export default ConnectionManager;