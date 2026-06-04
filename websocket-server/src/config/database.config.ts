import dotenv from 'dotenv';

dotenv.config();

export interface DatabaseConfig {
  path: string;
  readonly: boolean;
  timeout: number;
}

export const databaseConfig: DatabaseConfig = {
  path: process.env.DB_PATH || '../data/amerike_investment.db',
  readonly: false,
  timeout: 5000,
};

export default databaseConfig;