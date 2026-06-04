# Integración WebSocket - Sistema de Inversiones

## Descripción

Se ha integrado el sistema de WebSocket con el sistema de inversiones para permitir actualizaciones en tiempo real entre todos los dispositivos conectados. Cuando un usuario crea, actualiza o elimina una inversión, todos los demás usuarios ven los cambios reflejados instantáneamente en los rankings y proyectos.

## Arquitectura

### Componentes Principales

1. **`investmentWebSocketProvider`**: Escucha mensajes del WebSocket y actualiza el estado local
2. **`InvestmentWebSocketNotifier`**: Maneja eventos de inversión y dispara actualizaciones
3. **`investmentOperationsProvider`**: Wrapper para operaciones de inversión con broadcast
4. **`InvestmentOperationsNotifier`**: Ejecuta operaciones y notifica a todos los dispositivos

### Flujo de Datos

```
Usuario A crea inversión
    ↓
InvestmentOperationsNotifier.createInvestment()
    ↓
InvestmentRepository.createInvestment()
    ↓
InvestmentWebSocketNotifier.broadcastInvestmentCreated()
    ↓
WebSocket broadcast → Todos los dispositivos
    ↓
InvestmentWebSocketNotifier.handleWebSocketMessage()
    ↓
Invalidación de providers (investments, projects, rankings)
    ↓
UI se actualiza automáticamente en todos los dispositivos
```

## Uso

### 1. Crear una Inversión con Broadcast

```dart
class MyInvestmentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final ops = ref.read(investmentOperationsProvider);

        try {
          final investment = await ops.createInvestment(
            usuarioId: 'user123',
            usuarioNombre: 'Juan Pérez',
            perfil: 'student',
            proyectoId: 'proj456',
            proyectoNombre: 'Proyecto Alpha',
            temaId: 'tema1',
            temaNombre: 'Tecnología',
            temaColor: '#00D4AA',
            monto: 1000.0,
            observaciones: 'Inversión inicial',
            sessionState: SessionState.active,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Inversión creada y sincronizada!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      },
      child: Text('Invertir'),
    );
  }
}
```

### 2. Actualizar una Inversión con Broadcast

```dart
final ops = ref.read(investmentOperationsProvider);

try {
  final updatedInvestment = await ops.updateInvestment(
    id: 'inv789',
    monto: 1500.0, // Actualizar monto
    observaciones: 'Inversión incrementada',
  );

  // Todos los dispositivos verán el monto actualizado
} catch (e) {
  print('Error actualizando: $e');
}
```

### 3. Eliminar una Inversión con Broadcast

```dart
final ops = ref.read(investmentOperationsProvider);

try {
  await ops.deleteInvestment('inv789');

  // Todos los dispositivos verán la inversión eliminada
  // y los rankings se actualizarán automáticamente
} catch (e) {
  print('Error eliminando: $e');
}
```

## Mensajes WebSocket

### Formato de Mensajes

Los mensajes siguen el formato definido en `WSMessage`:

```json
{
  "type": "investment",
  "action": "created|updated|deleted",
  "data": {
    "id": "inv123",
    "usuario_id": "user456",
    "usuario_nombre": "Juan Pérez",
    "perfil": "student",
    "proyecto_id": "proj789",
    "proyecto_nombre": "Proyecto Alpha",
    "tema_id": "tema1",
    "tema_nombre": "Tecnología",
    "tema_color": "#00D4AA",
    "monto": 1000.0,
    "fecha_hora": "2026-06-03T10:30:00Z",
    "observaciones": "Inversión inicial",
    "estado": "activa"
  },
  "timestamp": "2026-06-03T10:30:00Z"
}
```

### Tipos de Acciones

- **`created`**: Nueva inversión creada
- **`updated`**: Inversión actualizada (monto, estado, observaciones)
- **`deleted`**: Inversión eliminada o cancelada

## Actualizaciones Automáticas

Cuando se recibe un evento del WebSocket, automáticamente se invalidan los siguientes providers:

- **`investmentsProvider`**: Lista de inversiones del usuario
- **`projectInvestmentsProvider`**: Inversiones de un proyecto específico
- **`projectsProvider`**: Lista de proyectos con montos actualizados
- **`projectDetailProvider`**: Detalle de un proyecto específico

Esto asegura que:
- Los rankings se actualizan automáticamente
- Los montos totales de proyectos se recalculan
- Las listas de inversión se refrescan
- La UI se actualiza sin intervención del usuario

## Ejemplo Completo: Screen de Inversión

```dart
class InvestmentFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const InvestmentFormScreen({
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends ConsumerState<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider)!;
      final theme = ref.read(currentThemeProvider)!;
      final ops = ref.read(investmentOperationsProvider);

      final investment = await ops.createInvestment(
        usuarioId: user.id,
        usuarioNombre: user.nombre,
        perfil: user.perfil.toString(),
        proyectoId: widget.projectId,
        proyectoNombre: widget.projectName,
        temaId: theme.id,
        temaNombre: theme.nombre,
        temaColor: theme.color,
        monto: double.parse(_amountController.text),
        observaciones: _notesController.text.isEmpty
            ? null
            : _notesController.text,
        sessionState: ref.read(sessionStateProvider),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Inversión de \$${investment.monto} realizada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al invertir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invertir en ${widget.projectName}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto a invertir',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingrese un monto válido';
                }
                if (amount < 100) {
                  return 'La inversión mínima es \$100';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitInvestment,
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : Text('Confirmar Inversión'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

### 1. Verificar Conexión WebSocket

```dart
final wsNotifier = ref.read(investmentWebSocketProvider);
final dataSource = ref.read(webSocketDataSourceProvider);

print('Conectado: ${dataSource.isConnected}');
print('Estado: ${dataSource.connectionState}');
```

### 2. Simular Evento WebSocket

```dart
// Para pruebas, puedes simular un mensaje entrante:
final testMessage = {
  'type': 'investment',
  'action': 'created',
  'data': {
    'id': 'test123',
    'monto': 500.0,
    // ... otros campos
  },
  'timestamp': DateTime.now().toIso8601String(),
};

wsNotifier.handleWebSocketMessage(testMessage);
// Verificar que los providers se invalidan
```

## Troubleshooting

### Los rankings no se actualizan

**Verifica:**
1. Que el `investmentWebSocketProvider` está siendo escuchado en el widget
2. Que el WebSocket está conectado (`dataSource.isConnected`)
3. Que los providers están usando `ref.watch` en lugar de `ref.read`

### La inversión se crea pero no se broadcast

**Verifica:**
1. Que estás usando `investmentOperationsProvider` en lugar del repositorio directo
2. Que no hay excepciones en el broadcast (revisa logs)
3. Que el WebSocket está conectado antes de hacer broadcast

### Error "Provider not found"

**Verifica:**
1. Que el provider está declarado antes de usarlo
2. Que el `ProviderScope` envuelve la app
3. Que no estás intentando usar el provider fuera del árbol de widgets

## Mejoras Futuras

1. **Optimización**: Actualizar solo el proyecto afectado en lugar de invalidar todos
2. **Batch Operations**: Agrupar múltiples actualizaciones en un solo broadcast
3. **Conflict Resolution**: Manejar conflictos cuando múltiples usuarios invierten simultáneamente
4. **Offline Support**: Queue de operaciones cuando no hay conexión
5. **Retry Logic**: Reintentar broadcast si falla

## Archivos Modificados

- `lib/presentation/providers/investment_provider.dart`
  - Agregado `investmentWebSocketProvider`
  - Agregado `InvestmentWebSocketNotifier`
  - Agregado `investmentOperationsProvider`
  - Agregado `InvestmentOperationsNotifier`

## Archivos Relacionados

- `lib/data/models/websocket_message.dart`: Definición de mensajes
- `lib/data/datasources/remote/websocket_datasource.dart`: Conexión WebSocket
- `lib/presentation/providers/websocket_provider.dart`: Provider de WebSocket
- `lib/presentation/providers/project_provider.dart`: Providers de proyectos

## Notas Importantes

1. **Sincronización Bidireccional**: El sistema permite que TODOS los dispositivos se actualicen, no solo el que hace la inversión
2. **Invalidación Automática**: No necesitas llamar a `ref.invalidate` manualmente, el sistema lo hace automáticamente
3. **Estado Consistente**: Los rankings y montos siempre reflejan el último estado conocido
4. **Logs de Debug**: Usa los logs con emojis 📊 💰 🔄 🗑️ 📢 para debuggear problemas
