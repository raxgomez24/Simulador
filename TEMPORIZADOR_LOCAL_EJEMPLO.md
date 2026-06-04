# Temporizador Local - Guía de Uso y Pruebas

## Resumen de Cambios Realizados

Se ha implementado un temporizador local completamente funcional en `/Users/raxgomez/Documents/MBA/Tania/lib/presentation/providers/session_provider.dart` que opera independientemente del WebSocket cuando `AppConfig.useLocalData = true`.

**Archivo modificado principal:** `/Users/raxgomez/Documents/MBA/Tania/lib/presentation/providers/session_provider.dart`

**Archivos de prueba creados:**
- `/Users/raxgomez/Documents/MBA/Tania/test/session_timer_test.dart` - Suite completa de pruebas unitarias

## Nuevas Características

### 1. Timer Local Automático
- El temporizador se inicia automáticamente cuando se usa modo local
- Actualiza el tiempo restante cada segundo usando `DateTime.now()` para precisión
- Se detiene automáticamente cuando el tiempo se agota
- El estado inicial se emite inmediatamente sin espera

### 2. Estados de Sesión Soportados
- `waiting`: Sesión esperando iniciar
- `active`: Sesión en progreso (contador corriendo)
- `paused`: Sesión pausada (contador detenido)
- `ended`: Sesión finalizada

### 3. Métodos de Control Disponibles

#### `startSession()`
Inicia una nueva sesión y comienza el contador.

```dart
ref.read(sessionProvider.notifier).startSession();
```

#### `pauseSession()`
Pausa una sesión activa y detiene el contador.

```dart
ref.read(sessionProvider.notifier).pauseSession();
```

#### `resumeSession()`
Reanuda una sesión pausada y continúa el contador.

```dart
ref.read(sessionProvider.notifier).resumeSession();
```

#### `endSession()`
Finaliza manualmente una sesión en curso.

```dart
ref.read(sessionProvider.notifier).endSession();
```

#### `resetSession({Duration? customDuration})`
Reinicia la sesión a su estado inicial. Opcionalmente puede establecer una duración personalizada.

```dart
// Reiniciar con duración por defecto (de AppConfig.roundDuration)
ref.read(sessionProvider.notifier).resetSession();

// Reiniciar con duración personalizada de 45 minutos
ref.read(sessionProvider.notifier).resetSession(customDuration: Duration(minutes: 45));
```

#### `setSessionDuration(int minutes)`
Establece o actualiza la duración de la sesión en minutos. Si la sesión está activa, ajusta proporcionalmente el tiempo restante.

```dart
// Establecer duración de 60 minutos
ref.read(sessionProvider.notifier).setSessionDuration(60);
```

#### `updateParticipants(int count)`
Actualiza el número de participantes en la sesión.

```dart
ref.read(sessionProvider.notifier).updateParticipants(15);
```

#### `updateProjects(int count)`
Actualiza el número de proyectos en la sesión.

```dart
ref.read(sessionProvider.notifier).updateProjects(8);
```

#### `updateTotalInvested(double amount)`
Actualiza el total invertido en la sesión.

```dart
ref.read(sessionProvider.notifier).updateTotalInvested(500000.0);
```

## Configuración

Para activar el modo local, asegúrate de configurar `/Users/raxgomez/Documents/MBA/Tania/lib/app/config.dart`:

```dart
class AppConfig {
  // Cambia a true para usar el temporizador local
  static const bool useLocalData = true;

  // Duración por defecto de la sesión (puede ser sobrescrita)
  static const Duration roundDuration = Duration(minutes: 30);
}
```

## Guía de Pruebas

### Prueba 1: Flujo Completo de Sesión

```dart
// 1. Verificar que estamos en modo local
assert(AppConfig.useLocalData == true);

// 2. Observar el estado inicial (debe ser 'waiting')
final initialSession = ref.read(sessionProvider);
assert(initialSession.estado == SessionState.waiting);
assert(initialSession.tiempoRestante == Duration(minutes: 30));

// 3. Iniciar la sesión
ref.read(sessionProvider.notifier).startSession();

// 4. Esperar unos segundos y verificar que el tiempo disminuye
await Future.delayed(Duration(seconds: 3));
final activeSession = ref.read(sessionProvider);
assert(activeSession.estado == SessionState.active);
assert(activeSession.tiempoRestante < Duration(minutes: 30));

// 5. Pausar la sesión
ref.read(sessionProvider.notifier).pauseSession();
final pausedSession = ref.read(sessionProvider);
assert(pausedSession.estado == SessionState.paused);

// 6. Esperar y verificar que el tiempo no cambia mientras está pausado
await Future.delayed(Duration(seconds: 2));
final stillPausedSession = ref.read(sessionProvider);
assert(stillPausedSession.tiempoRestante == pausedSession.tiempoRestante);

// 7. Reanudar la sesión
ref.read(sessionProvider.notifier).resumeSession();
final resumedSession = ref.read(sessionProvider);
assert(resumedSession.estado == SessionState.active);

// 8. Finalizar manualmente
ref.read(sessionProvider.notifier).endSession();
final endedSession = ref.read(sessionProvider);
assert(endedSession.estado == SessionState.ended);
```

### Prueba 2: Cambio de Duración en Tiempo Real

```dart
// 1. Iniciar sesión con duración por defecto (30 min)
ref.read(sessionProvider.notifier).startSession();
await Future.delayed(Duration(seconds: 2));

// 2. Cambiar duración a 60 minutos
ref.read(sessionProvider.notifier).setSessionDuration(60);
final extendedSession = ref.read(sessionProvider);
assert(extendedSession.tiempoTotal == Duration(minutes: 60));
assert(extendedSession.tiempoRestante > Duration(minutes: 55)); // Aproximadamente

// 3. Cambiar duración a 15 minutos
ref.read(sessionProvider.notifier).setSessionDuration(15);
final shortenedSession = ref.read(sessionProvider);
assert(shortenedSession.tiempoTotal == Duration(minutes: 15));
assert(shortenedSession.tiempoRestante < Duration(minutes: 15));
```

### Prueba 3: Reinicio con Duración Personalizada

```dart
// 1. Iniciar sesión
ref.read(sessionProvider.notifier).startSession();
await Future.delayed(Duration(seconds: 3));

// 2. Reiniciar con nueva duración
ref.read(sessionProvider.notifier).resetSession(customDuration: Duration(minutes: 45));
final resetSession = ref.read(sessionProvider);
assert(resetSession.estado == SessionState.waiting);
assert(resetSession.tiempoTotal == Duration(minutes: 45));
assert(resetSession.tiempoRestante == Duration(minutes: 45));

// 3. Iniciar nuevamente
ref.read(sessionProvider.notifier).startSession();
assert(ref.read(sessionProvider).estado == SessionState.active);
```

### Prueba 4: Actualización de Metadatos

```dart
// 1. Iniciar sesión
ref.read(sessionProvider.notifier).startSession();

// 2. Actualizar participantes
ref.read(sessionProvider.notifier).updateParticipants(20);
assert(ref.read(sessionProvider).numeroParticipantes == 20);

// 3. Actualizar proyectos
ref.read(sessionProvider.notifier).updateProjects(12);
assert(ref.read(sessionProvider).numeroProyectos == 12);

// 4. Actualizar total invertido
ref.read(sessionProvider.notifier).updateTotalInvested(1250000.50);
assert(ref.read(sessionProvider).totalInvertido == 1250000.50);
```

### Prueba 5: Auto-terminación por Tiempo Agotado

```dart
// 1. Reiniciar con duración corta para pruebas
ref.read(sessionProvider.notifier).resetSession(customDuration: Duration(seconds: 5));
ref.read(sessionProvider.notifier).startSession();

// 2. Esperar a que el tiempo se agote
await Future.delayed(Duration(seconds: 6));

// 3. Verificar que la sesión terminó automáticamente
final autoEndedSession = ref.read(sessionProvider);
assert(autoEndedSession.estado == SessionState.ended);
assert(autoEndedSession.tiempoRestante == Duration.zero);
```

## Implementación en Panel de Administración

Para integrar el temporizador en el panel de administración, puedes usar los siguientes ejemplos de widgets:

```dart
// Widget para mostrar el temporizador
class SessionTimerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Estado: ${session.estadoTexto}'),
            Text('Tiempo Restante: ${_formatDuration(session.tiempoRestante)}'),
            Text('Progreso: ${(session.progreso * 100).toStringAsFixed(1)}%'),
            LinearProgressIndicator(value: session.progreso),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Widget para controles de administración
class SessionControlsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Column(
      children: [
        ElevatedButton(
          onPressed: session.isActive
              ? () => ref.read(sessionProvider.notifier).pauseSession()
              : () => ref.read(sessionProvider.notifier).startSession(),
          child: Text(session.isActive ? 'Pausar' : 'Iniciar'),
        ),
        ElevatedButton(
          onPressed: session.isPaused
              ? () => ref.read(sessionProvider.notifier).resumeSession()
              : null,
          child: Text('Reanudar'),
        ),
        ElevatedButton(
          onPressed: () => ref.read(sessionProvider.notifier).endSession(),
          child: Text('Finalizar'),
        ),
        ElevatedButton(
          onPressed: () => ref.read(sessionProvider.notifier).resetSession(),
          child: Text('Reiniciar'),
        ),
        DropdownButton<int>(
          value: session.tiempoTotal.inMinutes,
          items: [
            DropdownMenuItem(value: 15, child: Text('15 minutos')),
            DropdownMenuItem(value: 30, child: Text('30 minutos')),
            DropdownMenuItem(value: 45, child: Text('45 minutos')),
            DropdownMenuItem(value: 60, child: Text('60 minutos')),
          ],
          onChanged: (minutes) {
            if (minutes != null) {
              ref.read(sessionProvider.notifier).setSessionDuration(minutes);
            }
          },
        ),
      ],
    );
  }
}
```

## Notas Importantes

1. **Persistencia**: El temporizador local mantiene su estado durante la sesión de la aplicación. Si la app se cierra, se perderá el estado. Para persistencia permanente, se debería implementar almacenamiento local (SharedPreferences, Hive, etc.).

2. **Precision**: El temporizador usa `DateTime.now()` para calcular el tiempo transcurrido, lo que lo hace más preciso que simplemente decrementar un contador cada segundo.

3. **Manejo de Pausa**: El tiempo de pausa se calcula y resta del tiempo total, asegurando que el temporizador sea preciso incluso con múltiples pausas.

4. **Configuración por Defecto**: La duración inicial se toma de `AppConfig.roundDuration`, pero puede ser modificada en cualquier momento.

5. **Solo Modo Local**: Todos los métodos de control solo funcionan cuando `AppConfig.useLocalData = true`. En modo WebSocket, el estado es controlado por el servidor.
