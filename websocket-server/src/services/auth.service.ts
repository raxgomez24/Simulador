import { User, UserProfile, toUserResponse } from '../models/user.model';
import { userRepository } from '../database/repositories/user.repository';
import { logger } from '../utils/logger';
import { ErrorCodes } from '../config/app.config';
import { appConfig } from '../config/app.config';
import { v4 as uuidv4 } from 'uuid';

export class AuthService {
  public async authenticate(username: string, password: string): Promise<User> {
    try {
      const user = await userRepository.findByUsername(username);

      if (!user) {
        throw { code: ErrorCodes.INVALID_CREDENTIALS, message: 'Invalid credentials' };
      }

      if (!user.activo) {
        throw { code: ErrorCodes.INVALID_CREDENTIALS, message: 'User account is inactive' };
      }

      if (user.password !== password) {
        throw { code: ErrorCodes.INVALID_CREDENTIALS, message: 'Invalid credentials' };
      }

      logger.info(`User authenticated: ${username}`);
      return user;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Authentication error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Authentication failed' };
    }
  }

  public async registerUser(nombre: string, username: string, password: string, perfil: UserProfile = 'student', correo?: string): Promise<User> {
    try {
      const existingUser = await userRepository.findByUsername(username);
      if (existingUser) {
        throw { code: ErrorCodes.USER_EXISTS, message: 'Username already exists' };
      }

      const newUser: User = {
        id: uuidv4(),
        nombre,
        correo,
        username,
        password,
        perfil,
        saldo: appConfig.initialBalance,
        activo: true,
        fechaRegistro: new Date(),
      };

      await userRepository.create(newUser);
      logger.info(`New user registered: ${username}`);
      return newUser;
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Registration error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Registration failed' };
    }
  }

  public async getUserById(userId: string): Promise<User | null> {
    try {
      return await userRepository.findById(userId);
    } catch (error) {
      logger.error('Error getting user by id:', error);
      return null;
    }
  }

  public async getAllUsers(): Promise<User[]> {
    try {
      return await userRepository.findAll();
    } catch (error) {
      logger.error('Error getting all users:', error);
      return [];
    }
  }

  public async getRanking(): Promise<User[]> {
    try {
      return await userRepository.getRanking();
    } catch (error) {
      logger.error('Error getting ranking:', error);
      return [];
    }
  }

  public isAdmin(user: User): boolean {
    return user.perfil === 'admin';
  }
}

export const authService = new AuthService();