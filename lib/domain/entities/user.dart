import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  student,
  guest,
  teacher,
  employee,
  investor,
}

class User extends Equatable {
  final String id;
  final String nombre;
  final String? correo;
  final String username;
  final UserRole perfil;
  final double saldo;
  final bool activo;
  final DateTime? fechaRegistro;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.nombre,
    this.correo,
    required this.username,
    required this.perfil,
    required this.saldo,
    required this.activo,
    this.fechaRegistro,
    this.createdAt,
    this.lastLogin,
  });

  User copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? username,
    UserRole? perfil,
    double? saldo,
    bool? activo,
    DateTime? fechaRegistro,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      username: username ?? this.username,
      perfil: perfil ?? this.perfil,
      saldo: saldo ?? this.saldo,
      activo: activo ?? this.activo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  String get initials {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0].toUpperCase()}${parts[parts.length - 1][0].toUpperCase()}';
  }

  bool get isAdmin => perfil == UserRole.admin;
  bool get isStudent => perfil == UserRole.student;
  bool get isGuest => perfil == UserRole.guest;
  bool get isTeacher => perfil == UserRole.teacher;
  bool get isEmployee => perfil == UserRole.employee;
  bool get isInvestor => perfil == UserRole.investor;

  // Mapeo de valores del servidor a enums
  static UserRole fromString(String perfil) {
    switch (perfil.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'alumno':
      case 'student':
        return UserRole.student;
      case 'docente':
      case 'teacher':
        return UserRole.teacher;
      case 'administrativo':
      case 'employee':
        return UserRole.employee;
      case 'inversionista':
      case 'investor':
        return UserRole.investor;
      case 'invitado':
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.student;
    }
  }

  static String perfilToString(UserRole perfil) {
    switch (perfil) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.student:
        return 'Alumno';
      case UserRole.teacher:
        return 'Docente';
      case UserRole.employee:
        return 'Administrativo';
      case UserRole.investor:
        return 'Inversionista';
      case UserRole.guest:
        return 'Invitado';
    }
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String?,
      username: json['username'] as String,
      perfil: fromString(json['perfil'] as String? ?? 'student'),
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] as bool? ?? true,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        correo,
        username,
        perfil,
        saldo,
        activo,
        fechaRegistro,
        createdAt,
        lastLogin,
      ];
}
