import 'package:equatable/equatable.dart';

class InvestmentTheme extends Equatable {
  final String id;
  final String nombre;
  final String color;
  final String icon;
  final int numeroProyectos;
  final double totalInvertido;
  final String descripcion;
  final int orden;
  final bool activo;

  const InvestmentTheme({
    required this.id,
    required this.nombre,
    required this.color,
    required this.icon,
    required this.numeroProyectos,
    required this.totalInvertido,
    this.descripcion = '',
    this.orden = 0,
    this.activo = true,
  });

  InvestmentTheme copyWith({
    String? id,
    String? nombre,
    String? color,
    String? icon,
    int? numeroProyectos,
    double? totalInvertido,
    String? descripcion,
    int? orden,
    bool? activo,
  }) {
    return InvestmentTheme(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      numeroProyectos: numeroProyectos ?? this.numeroProyectos,
      totalInvertido: totalInvertido ?? this.totalInvertido,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
    );
  }

  factory InvestmentTheme.empty() {
    return const InvestmentTheme(
      id: '',
      nombre: 'Sin tema',
      color: '#00D4AA',
      icon: '🎯',
      numeroProyectos: 0,
      totalInvertido: 0,
      descripcion: '',
      orden: 0,
      activo: false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        color,
        icon,
        numeroProyectos,
        totalInvertido,
        descripcion,
        orden,
        activo,
      ];
}
