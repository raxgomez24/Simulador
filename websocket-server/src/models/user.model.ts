export type UserProfile = 'admin' | 'student' | 'guest';

export interface User {
  id: string;
  nombre: string;
  correo?: string;
  username: string;
  password: string;
  perfil: UserProfile;
  saldo: number;
  activo: boolean;
  fechaRegistro?: Date;
}

export interface UserResponse {
  id: string;
  nombre: string;
  correo?: string;
  username: string;
  perfil: UserProfile;
  saldo: number;
  activo: boolean;
  fechaRegistro?: string;
}

export function toUserResponse(user: User): UserResponse {
  return {
    id: user.id,
    nombre: user.nombre,
    correo: user.correo,
    username: user.username,
    perfil: user.perfil,
    saldo: user.saldo,
    activo: user.activo,
    fechaRegistro: user.fechaRegistro?.toISOString(),
  };
}