export interface Project {
  id: string;
  nombre: string;
  descripcion: string;
  imagen?: string;
  temaId: string;
  temaNombre: string;
  temaColor?: string;
  totalInvertido: number;
  numeroInversores: number;
  createdAt?: Date;
  activo: boolean;
  pitch?: string;
  problema?: string;
  solucion?: string;
  estrategiaIngresos?: string;
  proyeccionFinanciera?: string;
  participantes: Array<{ nombre: string; rol: string }>;
  orden?: number;
}

export interface ProjectResponse {
  id: string;
  nombre: string;
  descripcion: string;
  imagen?: string;
  temaId: string;
  temaNombre: string;
  temaColor?: string;
  totalInvertido: number;
  numeroInversores: number;
  createdAt?: string;
  activo: boolean;
  pitch?: string;
  problema?: string;
  solucion?: string;
  estrategiaIngresos?: string;
  proyeccionFinanciera?: string;
  participantes: Array<{ nombre: string; rol: string }>;
  orden?: number;
}

export function toProjectResponse(project: Project): ProjectResponse {
  return {
    id: project.id,
    nombre: project.nombre,
    descripcion: project.descripcion,
    imagen: project.imagen,
    temaId: project.temaId,
    temaNombre: project.temaNombre,
    temaColor: project.temaColor,
    totalInvertido: project.totalInvertido,
    numeroInversores: project.numeroInversores,
    createdAt: project.createdAt?.toISOString(),
    activo: project.activo,
    pitch: project.pitch,
    problema: project.problema,
    solucion: project.solucion,
    estrategiaIngresos: project.estrategiaIngresos,
    proyeccionFinanciera: project.proyeccionFinanciera,
    participantes: project.participantes,
    orden: project.orden,
  };
}