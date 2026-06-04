import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

class UserModel extends Equatable {
  final String id;
  final String nombre;
  final String? correo;
  final String username;
  final String password;
  final String perfil;
  final double saldo;
  final bool activo;
  final DateTime? fechaRegistro;

  const UserModel({
    required this.id,
    required this.nombre,
    this.correo,
    required this.username,
    required this.password,
    required this.perfil,
    required this.saldo,
    required this.activo,
    this.fechaRegistro,
  });

  UserModel copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? username,
    String? password,
    String? perfil,
    double? saldo,
    bool? activo,
    DateTime? fechaRegistro,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      username: username ?? this.username,
      password: password ?? this.password,
      perfil: perfil ?? this.perfil,
      saldo: saldo ?? this.saldo,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'username': username,
      'password': password,
      'perfil': perfil,
      'saldo': saldo,
      'activo': activo ? 1 : 0,  // Convert boolean to integer for SQLite
      'fecha_registro': fechaRegistro?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String?,
      username: json['username'] as String,
      password: json['password'] as String? ?? '123456',
      perfil: json['perfil'] as String,
      saldo: (json['saldo'] as num).toDouble(),
      // SQLite stores booleans as 0 or 1, need to convert
      activo: json['activo'] == 1 || json['activo'] == true,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : null,
    );
  }

  User toEntity() {
    return User(
      id: id,
      nombre: nombre,
      correo: correo,
      username: username,
      perfil: User.fromString(perfil),
      saldo: saldo,
      activo: activo,
      fechaRegistro: fechaRegistro,
    );
  }

  static UserModel fromEntity(User user) {
    return UserModel(
      id: user.id,
      nombre: user.nombre,
      correo: user.correo,
      username: user.username,
      password: '123456', // Default password for entities created without one
      perfil: User.perfilToString(user.perfil),
      saldo: user.saldo,
      activo: user.activo,
      fechaRegistro: user.fechaRegistro,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        correo,
        username,
        password,
        perfil,
        saldo,
        activo,
        fechaRegistro,
      ];
}
