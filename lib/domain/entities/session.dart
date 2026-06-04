import 'package:equatable/equatable.dart';

enum SessionState {
  waiting,
  active,
  paused,
  ended,
}

class Session extends Equatable {
  final String id;
  final Duration tiempoRestante;
  final Duration tiempoTotal;
  final SessionState estado;
  final int numeroParticipantes;
  final int numeroProyectos;
  final double totalInvertido;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const Session({
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

  Session copyWith({
    String? id,
    Duration? tiempoRestante,
    Duration? tiempoTotal,
    SessionState? estado,
    int? numeroParticipantes,
    int? numeroProyectos,
    double? totalInvertido,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Session(
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

  double get progreso {
    if (tiempoTotal.inMilliseconds == 0) return 0.0;
    return 1.0 - (tiempoRestante.inMilliseconds / tiempoTotal.inMilliseconds);
  }

  String get estadoTexto {
    switch (estado) {
      case SessionState.waiting:
        return 'Esperando';
      case SessionState.active:
        return 'Activa';
      case SessionState.paused:
        return 'Pausada';
      case SessionState.ended:
        return 'Finalizada';
    }
  }

  bool get isActive => estado == SessionState.active;
  bool get isEnded => estado == SessionState.ended;
  bool get isPaused => estado == SessionState.paused;
  bool get isWaiting => estado == SessionState.waiting;

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
