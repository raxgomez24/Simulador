import 'package:equatable/equatable.dart';
import 'user.dart';

enum InvestmentStatus {
  activa,
  cancelada,
  pendiente,
}

extension InvestmentStatusExtension on InvestmentStatus {
  String get displayName {
    switch (this) {
      case InvestmentStatus.activa:
        return 'Activa';
      case InvestmentStatus.cancelada:
        return 'Cancelada';
      case InvestmentStatus.pendiente:
        return 'Pendiente';
    }
  }

  String get toServerString {
    switch (this) {
      case InvestmentStatus.activa:
        return 'activa';
      case InvestmentStatus.cancelada:
        return 'cancelada';
      case InvestmentStatus.pendiente:
        return 'pendiente';
    }
  }

  static InvestmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'activa':
        return InvestmentStatus.activa;
      case 'cancelada':
        return InvestmentStatus.cancelada;
      case 'pendiente':
        return InvestmentStatus.pendiente;
      default:
        return InvestmentStatus.pendiente;
    }
  }
}

class Investment extends Equatable {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final UserRole perfil;
  final String proyectoId;
  final String proyectoNombre;
  final String temaId;
  final String temaNombre;
  final String temaColor;
  final double monto;
  final DateTime fechaHora;
  final String? observaciones;
  final InvestmentStatus estado;

  const Investment({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.perfil,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.temaId,
    required this.temaNombre,
    required this.temaColor,
    required this.monto,
    required this.fechaHora,
    this.observaciones,
    this.estado = InvestmentStatus.activa,
  });

  Investment copyWith({
    String? id,
    String? usuarioId,
    String? usuarioNombre,
    UserRole? perfil,
    String? proyectoId,
    String? proyectoNombre,
    String? temaId,
    String? temaNombre,
    String? temaColor,
    double? monto,
    DateTime? fechaHora,
    String? observaciones,
    InvestmentStatus? estado,
  }) {
    return Investment(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      perfil: perfil ?? this.perfil,
      proyectoId: proyectoId ?? this.proyectoId,
      proyectoNombre: proyectoNombre ?? this.proyectoNombre,
      temaId: temaId ?? this.temaId,
      temaNombre: temaNombre ?? this.temaNombre,
      temaColor: temaColor ?? this.temaColor,
      monto: monto ?? this.monto,
      fechaHora: fechaHora ?? this.fechaHora,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
    );
  }

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        usuarioNombre,
        perfil,
        proyectoId,
        proyectoNombre,
        temaId,
        temaNombre,
        temaColor,
        monto,
        fechaHora,
        observaciones,
        estado,
      ];

  static Investment fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      usuarioNombre: json['usuarioNombre'] as String,
      perfil: User.fromString(json['perfil'] as String? ?? 'student'),
      proyectoId: json['proyectoId'] as String,
      proyectoNombre: json['proyectoNombre'] as String,
      temaId: json['temaId'] as String? ?? '',
      temaNombre: json['temaNombre'] as String? ?? '',
      temaColor: json['temaColor'] as String? ?? '#00D4AA',
      monto: (json['monto'] as num).toDouble(),
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] != null
          ? InvestmentStatusExtension.fromString(json['estado'] as String)
          : InvestmentStatus.activa,
    );
  }
}
