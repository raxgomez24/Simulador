import WebSocket from 'ws';
import { Server as WSServer } from 'ws';
import { websocketConfig } from '../config/websocket.config';
import { messageHandler } from '../handlers/message.handler';
import { ConnectionManager } from './connection.manager';
import { HeartbeatManager } from './heartbeat.manager';
import { logger } from '../utils/logger';

export class WebSocketServer {
  private wss: WSServer;
  private connectionManager: ConnectionManager;
  private heartbeatManager: HeartbeatManager;

  constructor() {
    this.wss = new WSServer({ port: websocketConfig.port, host: websocketConfig.host });
    this.connectionManager = ConnectionManager.getInstance();
    this.heartbeatManager = new HeartbeatManager(websocketConfig.heartbeatInterval, websocketConfig.heartbeatTimeout);

    this.setupServer();
  }

  private setupServer(): void {
    this.wss.on('connection', (ws: WebSocket, req) => {
      const clientIp = req.socket.remoteAddress;
      logger.info(`New WebSocket connection from: ${clientIp}`);

      this.connectionManager.addConnection(ws);

      ws.on('message', async (data: WebSocket.Data) => {
        try {
          const messageStr = data.toString();
          logger.debug(`Message received: ${messageStr}`);

          const message = JSON.parse(messageStr);
          const context = this.connectionManager.getConnectionContext(ws);

          await messageHandler.handleMessage(message, context);
        } catch (error) {
          logger.error('Error processing message:', error);
        }
      });

      ws.on('close', () => {
        logger.info(`WebSocket connection closed: ${clientIp}`);
        const context = this.connectionManager.getConnectionContext(ws);
        if (context.userId) {
          this.connectionManager.removeConnection(ws);
        }
      });

      ws.on('error', (error) => {
        logger.error(`WebSocket error for ${clientIp}:`, error);
      });

      this.heartbeatManager.registerClient(ws);
    });

    this.wss.on('listening', () => {
      logger.info(`WebSocket server listening on ws://${websocketConfig.host}:${websocketConfig.port}`);
    });

    this.wss.on('error', (error) => {
      logger.error('WebSocket server error:', error);
    });
  }

  public getConnections(): number {
    return this.connectionManager.getConnectionCount();
  }

  public close(): void {
    logger.info('Shutting down WebSocket server...');
    this.heartbeatManager.stop();
    this.connectionManager.removeAllConnections();
    this.wss.close();
  }
}

export default WebSocketServer;