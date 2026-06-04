import 'package:equatable/equatable.dart';
import '../../domain/entities/theme.dart';

class ThemeModel extends Equatable {
  final String id;
  final String nombre;
  final String color;
  final String icon;
  final int numeroProyectos;
  final double totalInvertido;
  final String descripcion;
  final int orden;
  final bool activo;

  const ThemeModel({
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

  ThemeModel copyWith({
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
    return ThemeModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'color': color,
      'icon': icon,
      'numero_proyectos': numeroProyectos,
      'total_invertido': totalInvertido,
      'descripcion': descripcion,
      'orden': orden,
      'activo': activo ? 1 : 0,  // Convert boolean to integer for SQLite
    };
  }

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      numeroProyectos: json['numero_proyectos'] as int,
      totalInvertido: (json['total_invertido'] as num).toDouble(),
      descripcion: json['descripcion'] as String? ?? '',
      orden: json['orden'] as int? ?? 0,
      // SQLite stores booleans as 0 or 1, need to convert
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  InvestmentTheme toEntity() {
    return InvestmentTheme(
      id: id,
      nombre: nombre,
      color: color,
      icon: icon,
      numeroProyectos: numeroProyectos,
      totalInvertido: totalInvertido,
      descripcion: descripcion,
      orden: orden,
      activo: activo,
    );
  }

  static ThemeModel fromEntity(InvestmentTheme theme) {
    return ThemeModel(
      id: theme.id,
      nombre: theme.nombre,
      color: theme.color,
      icon: theme.icon,
      numeroProyectos: theme.numeroProyectos,
      totalInvertido: theme.totalInvertido,
      descripcion: theme.descripcion,
      orden: theme.orden,
      activo: theme.activo,
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
