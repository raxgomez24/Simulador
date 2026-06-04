import dotenv from 'dotenv';

dotenv.config();

export interface WebSocketConfig {
  port: number;
  host: string;
  heartbeatInterval: number;
  heartbeatTimeout: number;
  maxClients: number;
}

export const websocketConfig: WebSocketConfig = {
  port: parseInt(process.env.WS_PORT || '8080', 10),
  host: process.env.WS_HOST || '0.0.0.0',
  heartbeatInterval: parseInt(process.env.HEARTBEAT_INTERVAL || '30000', 10),
  heartbeatTimeout: parseInt(process.env.HEARTBEAT_TIMEOUT || '10000', 10),
  maxClients: 100,
};

export default websocketConfig;