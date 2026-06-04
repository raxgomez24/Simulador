import { WebSocketServer } from './websocket/server';
import DatabaseConnection from './database/connection';
import { sessionService } from './services/session.service';
import { logger } from './utils/logger';
import dotenv from 'dotenv';

dotenv.config();

class Application {
  private wsServer: WebSocketServer | null = null;

  public async start(): Promise<void> {
    try {
      logger.info('Starting Amerike MBA 2026 WebSocket Server...');

      await DatabaseConnection.initialize();
      logger.info('Database connection established');

      this.wsServer = new WebSocketServer();

      this.setupGracefulShutdown();

      logger.info('Server started successfully');
    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  private setupGracefulShutdown(): void {
    const shutdown = async (signal: string) => {
      logger.info(`Received ${signal}, shutting down gracefully...`);

      if (this.wsServer) {
        this.wsServer.close();
      }

      sessionService.cleanup();
      await DatabaseConnection.close();

      logger.info('Server shut down complete');
      process.exit(0);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    process.on('uncaughtException', (error) => {
      logger.error('Uncaught exception:', error);
      shutdown('uncaughtException');
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled rejection at:', promise, 'reason:', reason);
    });
  }
}

const app = new Application();
app.start();

export default Application;