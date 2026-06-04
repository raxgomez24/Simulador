import WebSocket from 'ws';
import { logger } from '../utils/logger';

interface HeartbeatClient {
  ws: WebSocket;
  lastSeen: number;
  timeout: NodeJS.Timeout;
}

export class HeartbeatManager {
  private clients: Map<WebSocket, HeartbeatClient>;
  private interval: number;
  private timeout: number;
  private checkInterval: NodeJS.Timeout | null;

  constructor(interval: number, timeout: number) {
    this.clients = new Map();
    this.interval = interval;
    this.timeout = timeout;
    this.checkInterval = null;

    this.startHeartbeatCheck();
  }

  public registerClient(ws: WebSocket): void {
    if (this.clients.has(ws)) {
      logger.warn('Client already registered for heartbeat');
      return;
    }

    const heartbeatClient: HeartbeatClient = {
      ws,
      lastSeen: Date.now(),
      timeout: setTimeout(() => {
        this.handleHeartbeatTimeout(ws);
      }, this.timeout),
    };

    this.clients.set(ws, heartbeatClient);
    logger.debug('Client registered for heartbeat');
  }

  public unregisterClient(ws: WebSocket): void {
    const client = this.clients.get(ws);

    if (client) {
      clearTimeout(client.timeout);
      this.clients.delete(ws);
      logger.debug('Client unregistered from heartbeat');
    }
  }

  public updateHeartbeat(ws: WebSocket): void {
    const client = this.clients.get(ws);

    if (client) {
      clearTimeout(client.timeout);
      client.lastSeen = Date.now();
      client.timeout = setTimeout(() => {
        this.handleHeartbeatTimeout(ws);
      }, this.timeout);
    }
  }

  private startHeartbeatCheck(): void {
    this.checkInterval = setInterval(() => {
      const now = Date.now();
      const staleClients: WebSocket[] = [];

      this.clients.forEach((client, ws) => {
        const timeSinceLastSeen = now - client.lastSeen;

        if (timeSinceLastSeen > this.timeout) {
          staleClients.push(ws);
        }
      });

      staleClients.forEach((ws) => {
        logger.warn('Client heartbeat timeout, closing connection');
        this.unregisterClient(ws);
        if (ws.readyState === WebSocket.OPEN) {
          ws.close(1000, 'Heartbeat timeout');
        }
      });
    }, Math.max(this.timeout / 2, 5000));
  }

  private handleHeartbeatTimeout(ws: WebSocket): void {
    logger.warn('Heartbeat timeout for client');
    this.unregisterClient(ws);

    if (ws.readyState === WebSocket.OPEN) {
      ws.close(1000, 'Heartbeat timeout');
    }
  }

  public stop(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }

    this.clients.forEach((client, ws) => {
      clearTimeout(client.timeout);
    });

    this.clients.clear();
    logger.info('Heartbeat manager stopped');
  }

  public getClientCount(): number {
    return this.clients.size;
  }
}

export default HeartbeatManager;