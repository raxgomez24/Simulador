export interface Theme {
  id: string;
  nombre: string;
  color: string;
  icon: string;
  numeroProyectos: number;
  totalInvertido: number;
  descripcion: string;
  orden: number;
  activo: boolean;
}

export interface ThemeResponse {
  id: string;
  nombre: string;
  color: string;
  icon: string;
  numeroProyectos: number;
  totalInvertido: number;
  descripcion: string;
  orden: number;
  activo: boolean;
}

export function toThemeResponse(theme: Theme): ThemeResponse {
  return {
    id: theme.id,
    nombre: theme.nombre,
    color: theme.color,
    icon: theme.icon,
    numeroProyectos: theme.numeroProyectos,
    totalInvertido: theme.totalInvertido,
    descripcion: theme.descripcion,
    orden: theme.orden,
    activo: theme.activo,
  };
}