import { v4 as uuidv4 } from 'uuid';

export class IdGenerator {
  public static generate(): string {
    return uuidv4();
  }

  public static generateShort(): string {
    return uuidv4().split('-')[0];
  }

  public static generateTimestamp(): string {
    const timestamp = Date.now().toString(36);
    const randomPart = Math.random().toString(36).substring(2, 8);
    return `${timestamp}-${randomPart}`;
  }
}

export default IdGenerator;