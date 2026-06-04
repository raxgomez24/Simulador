export interface BaseMessage {
  type: string;
  timestamp?: string;
}

export interface AuthMessage extends BaseMessage {
  type: 'auth';
  action?: 'login' | 'register_guest' | 'logout';
  username?: string;
  password?: string;
  nombre?: string;
  correo?: string;
  perfil?: string;
  saldo?: number;
  activo?: boolean;
  fechaRegistro?: string;
}

export interface AuthResponseMessage extends BaseMessage {
  type: 'auth';
  status: 'success' | 'error';
  data?: any;
  user?: any;
  sessionId?: string;
  error?: {
    code: string;
    message: string;
  };
  errorCode?: string;
  errorMessage?: string;
}

export interface InvestMessage extends BaseMessage {
  type: 'invest';
  projectId: string;
  amount: number;
  observations?: string;
}

export interface InvestResponseMessage extends BaseMessage {
  type: 'invest';
  status: 'success' | 'error';
  investment?: any;
  user?: any;
  project?: any;
  error?: {
    code: string;
    message: string;
  };
}

export interface SessionUpdateMessage extends BaseMessage {
  type: 'session_update';
  action: 'start' | 'pause' | 'resume' | 'end' | 'update_time';
  tiempoRestante?: number;
  estado?: 'waiting' | 'active' | 'paused' | 'ended';
}

export interface SessionUpdateResponseMessage extends BaseMessage {
  type: 'session_update';
  session?: any;
  error?: {
    code: string;
    message: string;
  };
}

export interface SyncRequestMessage extends BaseMessage {
  type: 'sync_request';
  userId?: string;
}

export interface SyncResponseMessage extends BaseMessage {
  type: 'sync_request';
  status: 'success' | 'error';
  data?: {
    users?: any[];
    projects?: any[];
    investments?: any[];
    session?: any;
    themes?: any[];
    ranking?: any[];
  };
  error?: {
    code: string;
    message: string;
  };
}

export interface HeartbeatMessage extends BaseMessage {
  type: 'heartbeat';
  timestamp: string;
}

export interface PongMessage extends BaseMessage {
  type: 'pong';
  timestamp: string;
}

export interface ErrorMessage extends BaseMessage {
  type: 'error';
  code: string;
  message: string;
  timestamp: string;
}

export type WSMessage =
  | AuthMessage
  | AuthResponseMessage
  | InvestMessage
  | InvestResponseMessage
  | SessionUpdateMessage
  | SessionUpdateResponseMessage
  | SyncRequestMessage
  | SyncResponseMessage
  | HeartbeatMessage
  | PongMessage
  | ErrorMessage;