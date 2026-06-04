import 'package:equatable/equatable.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/user.dart';

class InvestmentModel extends Equatable {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final String perfil;
  final String proyectoId;
  final String proyectoNombre;
  final String temaId;
  final String temaNombre;
  final String temaColor;
  final double monto;
  final DateTime fechaHora;
  final String? observaciones;
  final String estado;

  const InvestmentModel({
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
    this.estado = 'activa',
  });

  InvestmentModel copyWith({
    String? id,
    String? usuarioId,
    String? usuarioNombre,
    String? perfil,
    String? proyectoId,
    String? proyectoNombre,
    String? temaId,
    String? temaNombre,
    String? temaColor,
    double? monto,
    DateTime? fechaHora,
    String? observaciones,
    String? estado,
  }) {
    return InvestmentModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'perfil': perfil,
      'proyecto_id': proyectoId,
      'proyecto_nombre': proyectoNombre,
      'tema_id': temaId,
      'tema_nombre': temaNombre,
      'tema_color': temaColor,
      'monto': monto,
      'fecha_hora': fechaHora.toIso8601String(),
      'observaciones': observaciones,
      'estado': estado,
    };
  }

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: json['usuario_nombre'] as String,
      perfil: json['perfil'] as String? ?? 'student',
      proyectoId: json['proyecto_id'] as String,
      proyectoNombre: json['proyecto_nombre'] as String,
      temaId: json['tema_id'] as String? ?? '',
      temaNombre: json['tema_nombre'] as String? ?? '',
      temaColor: json['tema_color'] as String? ?? '#FFFFFF',
      monto: (json['monto'] as num).toDouble(),
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] as String? ?? 'activa',
    );
  }

  Investment toEntity() {
    return Investment(
      id: id,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      perfil: User.fromString(perfil),
      proyectoId: proyectoId,
      proyectoNombre: proyectoNombre,
      temaId: temaId,
      temaNombre: temaNombre,
      temaColor: temaColor,
      monto: monto,
      fechaHora: fechaHora,
      observaciones: observaciones,
      estado: InvestmentStatusExtension.fromString(estado),
    );
  }

  static InvestmentModel fromEntity(Investment investment) {
    return InvestmentModel(
      id: investment.id,
      usuarioId: investment.usuarioId,
      usuarioNombre: investment.usuarioNombre,
      perfil: User.perfilToString(investment.perfil),
      proyectoId: investment.proyectoId,
      proyectoNombre: investment.proyectoNombre,
      temaId: investment.temaId,
      temaNombre: investment.temaNombre,
      temaColor: investment.temaColor,
      monto: investment.monto,
      fechaHora: investment.fechaHora,
      observaciones: investment.observaciones,
      estado: investment.estado.toServerString,
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
}
