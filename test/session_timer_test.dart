import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amerike_investment_sim/presentation/providers/session_provider.dart';
import 'package:amerike_investment_sim/domain/entities/session.dart';
import 'package:amerike_investment_sim/app/config.dart';

void main() {
  group('Session Timer Local Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Configurar modo local para pruebas
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Inicialización de sesión en modo local', () async {
      // Esperar a que el provider se inicialice completamente (Stream.periodic tarda 1 segundo en emitir)
      await Future.delayed(const Duration(milliseconds: 2500));

      // Obtener el estado inicial
      final sessionAsync = container.read(sessionProvider);

      // Verificar que no sea loading y obtener el valor
      expect(sessionAsync.hasValue, true, reason: 'El provider debería tener un valor después de 2.5s');
      final session = sessionAsync.value!;

      // Verificar estado inicial
      expect(session.estado, SessionState.waiting);
      expect(session.tiempoRestante, AppConfig.roundDuration);
      expect(session.tiempoTotal, AppConfig.roundDuration);
    });

    test('Iniciar sesión cambia estado a active', () async {
      // Esperar un momento para que el provider se inicialice
      await Future.delayed(const Duration(milliseconds: 1500));

      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();

      // Esperar actualización
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar estado activo
      final sessionAsync = container.read(sessionProvider);
      expect(sessionAsync.hasValue, true);
      final session = sessionAsync.value!;

      expect(session.estado, SessionState.active);
      expect(session.startedAt, isNotNull);
    });

    test('El temporizador decrementa el tiempo restante', () async {
      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();

      // Obtener tiempo inicial
      await Future.delayed(const Duration(milliseconds: 1500));
      final initialTime = container.read(sessionProvider).value!.tiempoRestante;

      // Esperar 2 segundos
      await Future.delayed(const Duration(seconds: 2));

      // Verificar que el tiempo disminuyó
      final currentTime = container.read(sessionProvider).value!.tiempoRestante;
      expect(currentTime, lessThan(initialTime));
      expect(
        initialTime - currentTime,
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    });

    test('Pausar sesión detiene el temporizador', () async {
      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Pausar sesión
      container.read(sessionProvider.notifier).pauseSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar estado pausado
      final pausedSession = container.read(sessionProvider).value!;
      expect(pausedSession.estado, SessionState.paused);

      // Obtener tiempo mientras está pausado
      final pausedTime = pausedSession.tiempoRestante;

      // Esperar 2 segundos
      await Future.delayed(const Duration(seconds: 2));

      // Verificar que el tiempo no cambió
      final stillPausedSession = container.read(sessionProvider).value!;
      expect(stillPausedSession.tiempoRestante, pausedTime);
    });

    test('Reanudar sesión continúa el temporizador', () async {
      // Iniciar y pausar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));
      container.read(sessionProvider.notifier).pauseSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Obtener tiempo pausado
      final pausedTime = container.read(sessionProvider).value!.tiempoRestante;

      // Reanudar sesión
      container.read(sessionProvider.notifier).resumeSession();
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar estado activo y que el tiempo sea aproximadamente igual al tiempo pausado
      final resumedSession = container.read(sessionProvider).value!;
      expect(resumedSession.estado, SessionState.active);
      // El tiempo debe ser muy cercano al tiempo pausado (diferencia máxima de 500ms)
      final timeDifference = (resumedSession.tiempoRestante - pausedTime).abs();
      expect(timeDifference.inMilliseconds, lessThan(500));

      // Esperar y verificar que el tiempo disminuye
      await Future.delayed(const Duration(seconds: 2));
      final afterResumeTime = container.read(sessionProvider).value!.tiempoRestante;
      expect(afterResumeTime, lessThan(resumedSession.tiempoRestante));
    });

    test('Finalizar sesión manualmente', () async {
      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Finalizar sesión
      container.read(sessionProvider.notifier).endSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar estado finalizado
      final endedSession = container.read(sessionProvider).value!;
      expect(endedSession.estado, SessionState.ended);
      expect(endedSession.endedAt, isNotNull);
    });

    test('Reiniciar sesión restaura estado inicial', () async {
      // Iniciar sesión y dejar que corra un poco
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(seconds: 2));

      // Reiniciar sesión
      container.read(sessionProvider.notifier).resetSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar estado inicial
      final resetSession = container.read(sessionProvider).value!;
      expect(resetSession.estado, SessionState.waiting);
      expect(resetSession.tiempoRestante, AppConfig.roundDuration);
      expect(resetSession.tiempoTotal, AppConfig.roundDuration);
    });

    test('Reiniciar sesión con duración personalizada', () async {
      // Reiniciar con duración de 45 minutos
      container.read(sessionProvider.notifier).resetSession(
        customDuration: const Duration(minutes: 45),
      );
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar duración personalizada
      final customSession = container.read(sessionProvider).value!;
      expect(customSession.tiempoTotal, const Duration(minutes: 45));
      expect(customSession.tiempoRestante, const Duration(minutes: 45));
    });

    test('Cambiar duración de sesión activa', () async {
      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(seconds: 1));

      // Cambiar duración a 60 minutos
      container.read(sessionProvider.notifier).setSessionDuration(60);
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verificar nueva duración
      final updatedSession = container.read(sessionProvider).value!;
      expect(updatedSession.tiempoTotal, const Duration(minutes: 60));
      expect(updatedSession.tiempoRestante, greaterThan(const Duration(minutes: 55)));
    });

    test('Actualizar participantes, proyectos e inversiones', () async {
      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Actualizar participantes
      container.read(sessionProvider.notifier).updateParticipants(25);
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(container.read(sessionProvider).value!.numeroParticipantes, 25);

      // Actualizar proyectos
      container.read(sessionProvider.notifier).updateProjects(15);
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(container.read(sessionProvider).value!.numeroProyectos, 15);

      // Actualizar total invertido
      container.read(sessionProvider.notifier).updateTotalInvested(750000.0);
      await Future.delayed(const Duration(milliseconds: 1500));
      expect(container.read(sessionProvider).value!.totalInvertido, 750000.0);
    });

    test('Auto-terminación por tiempo agotado', () async {
      // Reiniciar con duración corta
      container.read(sessionProvider.notifier).resetSession(
        customDuration: const Duration(seconds: 3),
      );
      await Future.delayed(const Duration(milliseconds: 1500));

      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Esperar a que se agote el tiempo
      await Future.delayed(const Duration(seconds: 4));

      // Verificar que terminó automáticamente
      final autoEndedSession = container.read(sessionProvider).value!;
      expect(autoEndedSession.estado, SessionState.ended);
      expect(autoEndedSession.tiempoRestante, Duration.zero);
    });

    test('Cálculo de progreso', () async {
      // Reiniciar con duración conocida
      container.read(sessionProvider.notifier).resetSession(
        customDuration: const Duration(seconds: 10),
      );
      await Future.delayed(const Duration(milliseconds: 1500));

      // Iniciar sesión
      container.read(sessionProvider.notifier).startSession();
      await Future.delayed(const Duration(milliseconds: 1500));

      // Esperar 3 segundos
      await Future.delayed(const Duration(seconds: 3));

      // Verificar progreso aproximado
      final session = container.read(sessionProvider).value!;
      const expectedProgress = 3.0 / 10.0; // 3 segundos de 10
      expect(session.progreso, closeTo(expectedProgress, 0.2));
    });
  });
}
