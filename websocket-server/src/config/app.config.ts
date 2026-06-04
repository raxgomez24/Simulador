import dotenv from 'dotenv';

dotenv.config();

export interface AppConfig {
  initialBalance: number;
  roundDuration: number;
  minInvestment: number;
  maxInvestment: number;
  logLevel: string;
}

export const appConfig: AppConfig = {
  initialBalance: parseFloat(process.env.INITIAL_BALANCE || '1000000'),
  roundDuration: parseInt(process.env.ROUND_DURATION || '1800', 10),
  minInvestment: parseInt(process.env.MIN_INVESTMENT || '10000', 10),
  maxInvestment: parseInt(process.env.MAX_INVESTMENT || '500000', 10),
  logLevel: process.env.LOG_LEVEL || 'info',
};

export default appConfig;

// Message Types
export const MessageTypes = {
  AUTH: 'auth',
  PROJECTS: 'projects',
  PROJECT_DETAIL: 'project_detail',
  INVESTMENTS: 'investments',
  INVEST: 'invest',
  SESSION: 'session',
  RANKING: 'ranking',
  USERS: 'users',
  ERROR: 'error',
  HEARTBEAT: 'heartbeat',
  PONG: 'pong',
  SYNC_REQUEST: 'sync_request',
  SESSION_UPDATE: 'session_update',
} as const;

// Response Status
export const ResponseStatus = {
  SUCCESS: 'success',
  ERROR: 'error',
  PENDING: 'pending',
} as const;

// Error Codes
export const ErrorCodes = {
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  USER_EXISTS: 'USER_EXISTS',
  INSUFFICIENT_FUNDS: 'INSUFFICIENT_FUNDS',
  INVALID_AMOUNT: 'INVALID_AMOUNT',
  PROJECT_NOT_FOUND: 'PROJECT_NOT_FOUND',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  SERVER_ERROR: 'SERVER_ERROR',
  UNAUTHORIZED: 'UNAUTHORIZED',
  CONNECTION_LOST: 'CONNECTION_LOST',
} as const;

// Session States
export const SessionStates = {
  WAITING: 'waiting',
  ACTIVE: 'active',
  PAUSED: 'paused',
  ENDED: 'ended',
} as const;

// User Roles
export const UserRoles = {
  ADMIN: 'admin',
  STUDENT: 'student',
  GUEST: 'guest',
} as const;