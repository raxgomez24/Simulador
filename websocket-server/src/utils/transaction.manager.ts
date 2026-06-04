import sqlite3 from 'sqlite3';
import DatabaseConnection from '../database/connection';
import { logger } from './logger';

export class TransactionManager {
  private db: sqlite3.Database;

  constructor() {
    this.db = DatabaseConnection.getInstance();
  }

  public async runTransaction<T>(operation: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        this.db.run('BEGIN TRANSACTION', (err) => {
          if (err) {
            logger.error('Failed to begin transaction:', err);
            return reject(err);
          }

          operation()
            .then((result) => {
              this.db.run('COMMIT', (commitErr) => {
                if (commitErr) {
                  logger.error('Failed to commit transaction:', commitErr);
                  return this.db.run('ROLLBACK', () => reject(commitErr));
                }
                resolve(result);
              });
            })
            .catch((error) => {
              logger.error('Transaction failed, rolling back:', error);
              this.db.run('ROLLBACK', () => reject(error));
            });
        });
      });
    });
  }

  public async executeInTransaction<T>(queries: Array<() => Promise<T>>): Promise<T[]> {
    return this.runTransaction(async () => {
      const results: T[] = [];
      for (const query of queries) {
        results.push(await query());
      }
      return results;
    });
  }
}

export default TransactionManager;