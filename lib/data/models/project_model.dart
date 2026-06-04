import 'dart:convert';

import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';

class ProjectModel extends Equatable {
  final String id;
  final String nombre;
  final String descripcion;
  final String? imagen;
  final String temaId;
  final String temaNombre;
  final String? temaColor;
  final double totalInvertido;
  final int numeroInversores;
  final DateTime? createdAt;
  final bool activo;
  final String? pitch;
  final String? problema;
  final String? solucion;
  final String? estrategiaIngresos;
  final String? proyeccionFinanciera;
  final List<Map<String, String>> participantes;
  final int? orden;

  const ProjectModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagen,
    required this.temaId,
    required this.temaNombre,
    this.temaColor,
    required this.totalInvertido,
    required this.numeroInversores,
    this.createdAt,
    required this.activo,
    this.pitch,
    this.problema,
    this.solucion,
    this.estrategiaIngresos,
    this.proyeccionFinanciera,
    this.participantes = const [],
    this.orden,
  });

  ProjectModel copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? imagen,
    String? temaId,
    String? temaNombre,
    String? temaColor,
    double? totalInvertido,
    int? numeroInversores,
    DateTime? createdAt,
    bool? activo,
    String? pitch,
    String? problema,
    String? solucion,
    String? estrategiaIngresos,
    String? proyeccionFinanciera,
    List<Map<String, String>>? participantes,
    int? orden,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      temaId: temaId ?? this.temaId,
      temaNombre: temaNombre ?? this.temaNombre,
      temaColor: temaColor ?? this.temaColor,
      totalInvertido: totalInvertido ?? this.totalInvertido,
      numeroInversores: numeroInversores ?? this.numeroInversores,
      createdAt: createdAt ?? this.createdAt,
      activo: activo ?? this.activo,
      pitch: pitch ?? this.pitch,
      problema: problema ?? this.problema,
      solucion: solucion ?? this.solucion,
      estrategiaIngresos: estrategiaIngresos ?? this.estrategiaIngresos,
      proyeccionFinanciera: proyeccionFinanciera ?? this.proyeccionFinanciera,
      participantes: participantes ?? this.participantes,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen': imagen,
      'tema_id': temaId,
      'tema_nombre': temaNombre,
      'tema_color': temaColor,
      'total_invertido': totalInvertido,
      'numero_inversores': numeroInversores,
      'created_at': createdAt?.toIso8601String(),
      'activo': activo ? 1 : 0,  // Convert boolean to integer for SQLite
      'pitch': pitch,
      'problema': problema,
      'solucion': solucion,
      'estrategia_ingresos': estrategiaIngresos,
      'proyeccion_financiera': proyeccionFinanciera,
      'participantes': participantes.isEmpty ? null : jsonEncode(participantes),
      'orden': orden,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      imagen: json['imagen'] as String?,
      temaId: json['tema_id'] as String,
      temaNombre: json['tema_nombre'] as String,
      temaColor: json['tema_color'] as String?,
      totalInvertido: (json['total_invertido'] as num).toDouble(),
      numeroInversores: json['numero_inversores'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      activo: json['activo'] == 1 || json['activo'] == true,
      pitch: json['pitch'] as String?,
      problema: json['problema'] as String?,
      solucion: json['solucion'] as String?,
      estrategiaIngresos: json['estrategia_ingresos'] as String?,
      proyeccionFinanciera: json['proyeccion_financiera'] as String?,
      participantes: _parseParticipantes(json['participantes']),
      orden: json['orden'] as int?,
    );
  }

  static List<Map<String, String>> _parseParticipantes(dynamic participantes) {
    if (participantes == null) {
      return const [];
    }

    if (participantes is List) {
      return participantes
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }

    if (participantes is String) {
      try {
        final decoded = jsonDecode(participantes);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }

  Project toEntity() {
    return Project(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      imagen: imagen,
      temaId: temaId,
      temaNombre: temaNombre,
      temaColor: temaColor,
      totalInvertido: totalInvertido,
      numeroInversores: numeroInversores,
      createdAt: createdAt,
      activo: activo,
      pitch: pitch,
      problema: problema,
      solucion: solucion,
      estrategiaIngresos: estrategiaIngresos,
      proyeccionFinanciera: proyeccionFinanciera,
      participantes: participantes,
      orden: orden,
    );
  }

  static ProjectModel fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      nombre: project.nombre,
      descripcion: project.descripcion,
      imagen: project.imagen,
      temaId: project.temaId,
      temaNombre: project.temaNombre,
      temaColor: project.temaColor,
      totalInvertido: project.totalInvertido,
      numeroInversores: project.numeroInversores,
      createdAt: project.createdAt,
      activo: project.activo,
      pitch: project.pitch,
      problema: project.problema,
      solucion: project.solucion,
      estrategiaIngresos: project.estrategiaIngresos,
      proyeccionFinanciera: project.proyeccionFinanciera,
      participantes: project.participantes,
      orden: project.orden,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        descripcion,
        imagen,
        temaId,
        temaNombre,
        temaColor,
        totalInvertido,
        numeroInversores,
        createdAt,
        activo,
        pitch,
        problema,
        solucion,
        estrategiaIngresos,
        proyeccionFinanciera,
        participantes,
        orden,
      ];
}
