import 'package:equatable/equatable.dart';
import '../../domain/entities/session.dart';

class SessionModel extends Equatable {
  final String id;
  final int tiempoRestante;
  final int tiempoTotal;
  final String estado;
  final int numeroParticipantes;
  final int numeroProyectos;
  final double totalInvertido;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const SessionModel({
    required this.id,
    required this.tiempoRestante,
    required this.tiempoTotal,
    required this.estado,
    required this.numeroParticipantes,
    required this.numeroProyectos,
    required this.totalInvertido,
    this.startedAt,
    this.endedAt,
  });

  SessionModel copyWith({
    String? id,
    int? tiempoRestante,
    int? tiempoTotal,
    String? estado,
    int? numeroParticipantes,
    int? numeroProyectos,
    double? totalInvertido,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      tiempoRestante: tiempoRestante ?? this.tiempoRestante,
      tiempoTotal: tiempoTotal ?? this.tiempoTotal,
      estado: estado ?? this.estado,
      numeroParticipantes: numeroParticipantes ?? this.numeroParticipantes,
      numeroProyectos: numeroProyectos ?? this.numeroProyectos,
      totalInvertido: totalInvertido ?? this.totalInvertido,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tiempoRestante': tiempoRestante,
      'tiempoTotal': tiempoTotal,
      'estado': estado,
      'numeroParticipantes': numeroParticipantes,
      'numeroProyectos': numeroProyectos,
      'totalInvertido': totalInvertido,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      tiempoRestante: json['tiempoRestante'] as int,
      tiempoTotal: json['tiempoTotal'] as int,
      estado: json['estado'] as String,
      numeroParticipantes: json['numeroParticipantes'] as int,
      numeroProyectos: json['numeroProyectos'] as int,
      totalInvertido: (json['totalInvertido'] as num).toDouble(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  Session toEntity() {
    return Session(
      id: id,
      tiempoRestante: Duration(seconds: tiempoRestante),
      tiempoTotal: Duration(seconds: tiempoTotal),
      estado: _parseState(estado),
      numeroParticipantes: numeroParticipantes,
      numeroProyectos: numeroProyectos,
      totalInvertido: totalInvertido,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  static SessionState _parseState(String state) {
    switch (state.toLowerCase()) {
      case 'waiting':
        return SessionState.waiting;
      case 'active':
        return SessionState.active;
      case 'paused':
        return SessionState.paused;
      case 'ended':
        return SessionState.ended;
      default:
        return SessionState.waiting;
    }
  }

  static String stateToString(SessionState state) {
    switch (state) {
      case SessionState.waiting:
        return 'waiting';
      case SessionState.active:
        return 'active';
      case SessionState.paused:
        return 'paused';
      case SessionState.ended:
        return 'ended';
    }
  }

  static SessionModel fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      tiempoRestante: session.tiempoRestante.inSeconds,
      tiempoTotal: session.tiempoTotal.inSeconds,
      estado: stateToString(session.estado),
      numeroParticipantes: session.numeroParticipantes,
      numeroProyectos: session.numeroProyectos,
      totalInvertido: session.totalInvertido,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tiempoRestante,
        tiempoTotal,
        estado,
        numeroParticipantes,
        numeroProyectos,
        totalInvertido,
        startedAt,
        endedAt,
      ];
}
