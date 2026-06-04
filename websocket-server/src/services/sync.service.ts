import { User, toUserResponse } from '../models/user.model';
import { Project, toProjectResponse } from '../models/project.model';
import { Investment, toInvestmentResponse } from '../models/investment.model';
import { Session, toSessionResponse } from '../models/session.model';
import { Theme, toThemeResponse } from '../models/theme.model';
import { userRepository } from '../database/repositories/user.repository';
import { projectRepository } from '../database/repositories/project.repository';
import { investmentRepository } from '../database/repositories/investment.repository';
import { sessionRepository } from '../database/repositories/session.repository';
import { themeRepository } from '../database/repositories/theme.repository';
import { logger } from '../utils/logger';

export class SyncService {
  public async getFullSyncData(userId?: string): Promise<{
    users: User[];
    projects: Project[];
    investments: Investment[];
    session: Session | null;
    themes: Theme[];
    ranking: User[];
  }> {
    try {
      const [users, projects, investments, session, themes, ranking] = await Promise.all([
        userRepository.findAll(),
        projectRepository.findAll(),
        investmentRepository.findAll(),
        sessionRepository.findActiveSession(),
        themeRepository.findAll(),
        userRepository.getRanking(),
      ]);

      logger.info('Full sync data retrieved');
      return {
        users,
        projects,
        investments,
        session,
        themes,
        ranking,
      };
    } catch (error) {
      logger.error('Error getting full sync data:', error);
      throw error;
    }
  }

  public async getUserSyncData(userId: string): Promise<{
    user: User;
    projects: Project[];
    investments: Investment[];
    session: Session | null;
    themes: Theme[];
    ranking: User[];
  }> {
    try {
      const user = await userRepository.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      const [projects, investments, session, themes, ranking] = await Promise.all([
        projectRepository.findAll(),
        investmentRepository.findByUserId(userId),
        sessionRepository.findActiveSession(),
        themeRepository.findAll(),
        userRepository.getRanking(),
      ]);

      logger.info(`User sync data retrieved for: ${userId}`);
      return {
        user,
        projects,
        investments,
        session,
        themes,
        ranking,
      };
    } catch (error) {
      logger.error('Error getting user sync data:', error);
      throw error;
    }
  }
}

export const syncService = new SyncService();