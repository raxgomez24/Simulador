export type InvestmentStatus = 'activa' | 'cancelada' | 'completada';

export interface Investment {
  id: string;
  usuarioId: string;
  usuarioNombre: string;
  perfil: string;
  proyectoId: string;
  proyectoNombre: string;
  temaId: string;
  temaNombre: string;
  temaColor: string;
  monto: number;
  fechaHora: Date;
  observaciones?: string;
  estado: InvestmentStatus;
}

export interface InvestmentResponse {
  id: string;
  usuarioId: string;
  usuarioNombre: string;
  perfil: string;
  proyectoId: string;
  proyectoNombre: string;
  temaId: string;
  temaNombre: string;
  temaColor: string;
  monto: number;
  fechaHora: string;
  observaciones?: string;
  estado: InvestmentStatus;
}

export function toInvestmentResponse(investment: Investment): InvestmentResponse {
  return {
    id: investment.id,
    usuarioId: investment.usuarioId,
    usuarioNombre: investment.usuarioNombre,
    perfil: investment.perfil,
    proyectoId: investment.proyectoId,
    proyectoNombre: investment.proyectoNombre,
    temaId: investment.temaId,
    temaNombre: investment.temaNombre,
    temaColor: investment.temaColor,
    monto: investment.monto,
    fechaHora: investment.fechaHora.toISOString(),
    observaciones: investment.observaciones,
    estado: investment.estado,
  };
}