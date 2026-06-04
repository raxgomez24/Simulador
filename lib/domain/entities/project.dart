import 'package:equatable/equatable.dart';

class Project extends Equatable {
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

  const Project({
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

  Project copyWith({
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
    return Project(
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

  String get truncatedDescription {
    if (descripcion.length <= 100) {
      return descripcion;
    }
    return '${descripcion.substring(0, 100)}...';
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
