import WebSocket from 'ws';
import { AuthMessage, AuthResponseMessage } from '../models/message.model';
import { WebSocketContext } from './message.handler';
import { authService } from '../services/auth.service';
import { logger } from '../utils/logger';
import { ConnectionManager } from '../websocket/connection.manager';
import { ErrorCodes, ResponseStatus } from '../config/app.config';

export class AuthHandler {
  constructor() {}

  public async handleAuth(message: AuthMessage, context: WebSocketContext): Promise<void> {
    try {
      const { username, password, action } = message;

      // Manejar registro de invitado
      if (action === 'register_guest') {
        await this.handleRegisterGuest(message, context);
        return;
      }

      // Manejar logout
      if (action === 'logout') {
        await this.handleLogout(context);
        return;
      }

      // Autenticación normal (login)
      if (!username || !password) {
        this.sendAuthError(context.ws, ErrorCodes.INVALID_CREDENTIALS, 'Username and password are required');
        return;
      }

      const user = await authService.authenticate(username, password);

      context.userId = user.id;
      context.username = user.username;
      context.isAdmin = authService.isAdmin(user);

      const connectionManager = ConnectionManager.getInstance();
      connectionManager.registerUser(context.ws, user.id, user.username, context.isAdmin);

      const currentSession = await authService.getUserById(user.id);

      const response: AuthResponseMessage = {
        type: 'auth',
        status: ResponseStatus.SUCCESS,
        data: {
          id: user.id,
          nombre: user.nombre,
          correo: user.correo,
          username: user.username,
          perfil: user.perfil,
          saldo: user.saldo,
          activo: user.activo,
          fecha_registro: user.fechaRegistro?.toISOString(),
        },
        sessionId: currentSession?.id,
      };

      context.ws.send(JSON.stringify(response));
      logger.info(`User authenticated: ${username} (${user.id})`);
    } catch (error: any) {
      logger.error('Authentication error:', error);
      this.sendAuthError(context.ws, error.code || ErrorCodes.INVALID_CREDENTIALS, error.message || 'Authentication failed');
    }
  }

  private async handleRegisterGuest(message: AuthMessage, context: WebSocketContext): Promise<void> {
    try {
      const { username, nombre, correo, password, perfil, saldo, activo, fechaRegistro } = message;

      if (!username || !nombre) {
        this.sendAuthError(context.ws, ErrorCodes.INVALID_CREDENTIALS, 'Username and nombre are required');
        return;
      }

      const user = await authService.registerUser(
        nombre,
        username,
        password || 'guest123',
        perfil as any || 'student',
        correo
      );

      context.userId = user.id;
      context.username = user.username;
      context.isAdmin = authService.isAdmin(user);

      const connectionManager = ConnectionManager.getInstance();
      connectionManager.registerUser(context.ws, user.id, user.username, context.isAdmin);

      const response: AuthResponseMessage = {
        type: 'auth',
        status: ResponseStatus.SUCCESS,
        data: {
          id: user.id,
          nombre: user.nombre,
          correo: user.correo,
          username: user.username,
          perfil: user.perfil,
          saldo: user.saldo,
          activo: user.activo,
          fecha_registro: user.fechaRegistro?.toISOString(),
        },
      };

      context.ws.send(JSON.stringify(response));
      logger.info(`Guest user registered: ${username} (${user.id})`);
    } catch (error: any) {
      logger.error('Guest registration error:', error);
      this.sendAuthError(context.ws, error.code || ErrorCodes.SERVER_ERROR, error.message || 'Guest registration failed');
    }
  }

  private async handleLogout(context: WebSocketContext): Promise<void> {
    try {
      const connectionManager = ConnectionManager.getInstance();
      connectionManager.removeConnection(context.ws);

      context.userId = undefined;
      context.username = undefined;
      context.isAdmin = false;

      const response: AuthResponseMessage = {
        type: 'auth',
        status: ResponseStatus.SUCCESS,
        data: { message: 'Logged out successfully' },
      };

      context.ws.send(JSON.stringify(response));
      logger.info(`User logged out: ${context.username || 'unknown'}`);
    } catch (error: any) {
      logger.error('Logout error:', error);
    }
  }

  private sendAuthError(ws: WebSocket, code: string, message: string): void {
    const response: AuthResponseMessage = {
      type: 'auth',
      status: ResponseStatus.ERROR,
      error: { code, message },
    };

    try {
      ws.send(JSON.stringify(response));
    } catch (error) {
      logger.error('Error sending auth error:', error);
    }
  }
}

export const authHandler = new AuthHandler();