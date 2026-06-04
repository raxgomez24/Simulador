import { Investment } from '../models/investment.model';
import { Project } from '../models/project.model';
import { User } from '../models/user.model';
import { investmentRepository } from '../database/repositories/investment.repository';
import { projectRepository } from '../database/repositories/project.repository';
import { userRepository } from '../database/repositories/user.repository';
import { logger } from '../utils/logger';
import { ErrorCodes } from '../config/app.config';
import { appConfig } from '../config/app.config';
import { TransactionManager } from '../utils/transaction.manager';
import { v4 as uuidv4 } from 'uuid';

export class InvestmentService {
  public async makeInvestment(userId: string, projectId: string, amount: number, observaciones?: string): Promise<{ investment: Investment; user: User; project: Project }> {
    const transactionManager = new TransactionManager();

    try {
      return await transactionManager.runTransaction(async () => {
        const user = await userRepository.findById(userId);
        if (!user) {
          throw { code: ErrorCodes.USER_NOT_FOUND, message: 'User not found' };
        }

        const project = await projectRepository.findById(projectId);
        if (!project) {
          throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Project not found' };
        }

        if (amount < appConfig.minInvestment || amount > appConfig.maxInvestment) {
          throw { code: ErrorCodes.INVALID_AMOUNT, message: `Amount must be between ${appConfig.minInvestment} and ${appConfig.maxInvestment}` };
        }

        if (user.saldo < amount) {
          throw { code: ErrorCodes.INSUFFICIENT_FUNDS, message: 'Insufficient funds' };
        }

        const investment: Investment = {
          id: uuidv4(),
          usuarioId: user.id,
          usuarioNombre: user.nombre,
          perfil: user.perfil,
          proyectoId: project.id,
          proyectoNombre: project.nombre,
          temaId: project.temaId,
          temaNombre: project.temaNombre,
          temaColor: project.temaColor || '#FFFFFF',
          monto: amount,
          fechaHora: new Date(),
          observaciones,
          estado: 'activa' as any,
        };

        await investmentRepository.create(investment);

        const updatedUser = await userRepository.updateBalance(userId, -amount);

        const updatedProject = await projectRepository.updateInvestmentStats(projectId, amount, true);

        logger.info(`Investment made: ${user.username} invested ${amount} in ${project.nombre}`);

        return { investment, user: updatedUser, project: updatedProject };
      });
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Investment error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Investment failed' };
    }
  }

  public async getInvestmentsByUser(userId: string): Promise<Investment[]> {
    try {
      return await investmentRepository.findByUserId(userId);
    } catch (error) {
      logger.error('Error getting investments by user:', error);
      return [];
    }
  }

  public async getInvestmentsByProject(projectId: string): Promise<Investment[]> {
    try {
      return await investmentRepository.findByProjectId(projectId);
    } catch (error) {
      logger.error('Error getting investments by project:', error);
      return [];
    }
  }

  public async getAllInvestments(): Promise<Investment[]> {
    try {
      return await investmentRepository.findAll();
    } catch (error) {
      logger.error('Error getting all investments:', error);
      return [];
    }
  }

  public async cancelInvestment(investmentId: string, userId: string): Promise<{ investment: Investment; user: User; project: Project }> {
    const transactionManager = new TransactionManager();

    try {
      return await transactionManager.runTransaction(async () => {
        const investment = await investmentRepository.findById(investmentId);
        if (!investment) {
          throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Investment not found' };
        }

        if (investment.usuarioId !== userId) {
          throw { code: ErrorCodes.UNAUTHORIZED, message: 'Unauthorized to cancel this investment' };
        }

        if (investment.estado !== 'activa') {
          throw { code: ErrorCodes.SERVER_ERROR, message: 'Investment cannot be cancelled' };
        }

        const user = await userRepository.findById(userId);
        if (!user) {
          throw { code: ErrorCodes.USER_NOT_FOUND, message: 'User not found' };
        }

        const project = await projectRepository.findById(investment.proyectoId);
        if (!project) {
          throw { code: ErrorCodes.PROJECT_NOT_FOUND, message: 'Project not found' };
        }

        await investmentRepository.updateStatus(investmentId, 'cancelada');

        const updatedUser = await userRepository.updateBalance(userId, investment.monto);

        const updatedProject = await projectRepository.updateInvestmentStats(investment.proyectoId, investment.monto, false);

        logger.info(`Investment cancelled: ${investmentId} by ${user.username}`);

        return { investment, user: updatedUser, project: updatedProject };
      });
    } catch (error: any) {
      if (error.code) {
        throw error;
      }
      logger.error('Cancel investment error:', error);
      throw { code: ErrorCodes.SERVER_ERROR, message: 'Cancel investment failed' };
    }
  }
}

export const investmentService = new InvestmentService();