import sqlite3 from 'sqlite3';
import { logger } from '../utils/logger';

export abstract class BaseRepository {
  protected db: sqlite3.Database;

  constructor(db: sqlite3.Database) {
    this.db = db;
  }

  protected run(sql: string, params: any[] = []): Promise<sqlite3.RunResult> {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err) {
        if (err) reject(err);
        else resolve(this);
      });
    });
  }

  protected get(sql: string, params: any[] = []): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  protected all(sql: string, params: any[] = []): Promise<any[]> {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    });
  }

  protected serialize(callback: () => Promise<any>): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.serialize(async () => {
        try {
          const result = await callback();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });
    });
  }
}