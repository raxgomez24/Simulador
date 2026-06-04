export type SessionState = 'waiting' | 'active' | 'paused' | 'ended';

export interface Session {
  id: string;
  tiempoRestante: number;
  tiempoTotal: number;
  estado: SessionState;
  numeroParticipantes: number;
  numeroProyectos: number;
  totalInvertido: number;
  startedAt?: Date;
  endedAt?: Date;
}

export interface SessionResponse {
  id: string;
  tiempoRestante: number;
  tiempoTotal: number;
  estado: SessionState;
  numeroParticipantes: number;
  numeroProyectos: number;
  totalInvertido: number;
  startedAt?: string;
  endedAt?: string;
}

export function toSessionResponse(session: Session): SessionResponse {
  return {
    id: session.id,
    tiempoRestante: session.tiempoRestante,
    tiempoTotal: session.tiempoTotal,
    estado: session.estado,
    numeroParticipantes: session.numeroParticipantes,
    numeroProyectos: session.numeroProyectos,
    totalInvertido: session.totalInvertido,
    startedAt: session.startedAt?.toISOString(),
    endedAt: session.endedAt?.toISOString(),
  };
}