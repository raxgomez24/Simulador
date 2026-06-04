# Instrucciones de Instalación y Ejecución

## Paso 1: Verificar Flutter

Asegúrate de tener Flutter instalado en tu sistema:

```bash
flutter --version
```

Si no tienes Flutter instalado, descárgalo de https://flutter.dev/docs/get-started/install

## Paso 2: Instalar Dependencias

Navega al directorio del proyecto e instala las dependencias:

```bash
cd /Users/raxgomez/Documents/MBA/Tania
flutter pub get
```

## Paso 3: Generar Código

El proyecto usa code generation con Freezed y Riverpod. Necesitas generar los archivos:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Este comando creará:
- Archivos `.g.dart` para serialización JSON
- Archivos `.freezed.dart` para modelos inmutables
- Archivos `.g.dart` para providers de Riverpod

## Paso 4: Verificar el Código

Ejecuta el analizador de código para verificar que no haya errores:

```bash
flutter analyze
```

## Paso 5: Ejecutar la Aplicación

### En un Emulador o Dispositivo Físico

```bash
flutter run
```

### Específico para Android

```bash
# Lista de dispositivos conectados
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Build APK
flutter build apk

# Build App Bundle (para Play Store)
flutter build appbundle
```

### Específico para iOS

```bash
# Build para iOS
flutter build ios

# Nota: Para iOS necesitas una Mac con Xcode instalado
```

### Específico para Web

```bash
# Build para Web
flutter build web

# Ejecutar en web
flutter run -d chrome
```

### Específico para Windows

```bash
# Build para Windows
flutter build windows

# Ejecutar en Windows
flutter run -d windows
```

### Específico para macOS

```bash
# Build para macOS
flutter build macos

# Ejecutar en macOS
flutter run -d macos
```

## Paso 6: Configurar el Servidor WebSocket

La aplicación requiere un servidor WebSocket ejecutándose en `ws://localhost:8080`.

### Opción A: Servidor Node.js

Crea un archivo `server.js`:

```javascript
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

console.log('Servidor WebSocket ejecutándose en ws://localhost:8080');

wss.on('connection', (ws) => {
  console.log('Nuevo cliente conectado');

  ws.on('message', (message) => {
    console.log('Mensaje recibido:', message.toString());
    const data = JSON.parse(message.toString());

    // Manejar diferentes tipos de mensajes
    switch (data.type) {
      case 'auth':
        // Manejar autenticación
        ws.send(JSON.stringify({
          type: 'auth',
          status: 'success',
          data: {
            id: '1',
            nombre: 'Usuario Demo',
            username: 'demo',
            rol: 'student',
            saldo: 1000000,
            activo: true,
          },
        }));
        break;

      case 'projects':
        // Manejar solicitud de proyectos
        ws.send(JSON.stringify({
          type: 'projects',
          status: 'success',
          data: [
            {
              id: '1',
              nombre: 'Proyecto Demo',
              descripcion: 'Descripción del proyecto demo',
              temaId: '1',
              temaNombre: 'Tecnología',
              temaColor: '#00D4AA',
              totalInvertido: 500000,
              numeroInversores: 5,
              activo: true,
            },
          ],
        }));
        break;

      // Agregar más casos según sea necesario
    }
  });

  ws.on('close', () => {
    console.log('Cliente desconectado');
  });
});
```

Instalar dependencias y ejecutar:

```bash
npm install ws
node server.js
```

### Opción B: Servidor Dart

Crea un archivo `server.dart`:

```dart
import 'dart:io';
import 'dart:convert';

void main() async {
  final server = await HttpServer.bind('localhost', 8080);
  print('Servidor WebSocket ejecutándose en ws://localhost:8080');

  await for (var request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen(
        (message) {
          print('Mensaje recibido: $message');
          final data = json.decode(message as String);

          // Manejar diferentes tipos de mensajes
          switch (data['type']) {
            case 'auth':
              socket.add(json.encode({
                'type': 'auth',
                'status': 'success',
                'data': {
                  'id': '1',
                  'nombre': 'Usuario Demo',
                  'username': 'demo',
                  'rol': 'student',
                  'saldo': 1000000,
                  'activo': true,
                },
              }));
              break;

            case 'projects':
              socket.add(json.encode({
                'type': 'projects',
                'status': 'success',
                'data': [
                  {
                    'id': '1',
                    'nombre': 'Proyecto Demo',
                    'descripcion': 'Descripción del proyecto demo',
                    'temaId': '1',
                    'temaNombre': 'Tecnología',
                    'temaColor': '#00D4AA',
                    'totalInvertido': 500000,
                    'numeroInversores': 5,
                    'activo': true,
                  },
                ],
              }));
              break;
          }
        },
        onError: (error) => print('Error: $error'),
        onDone: () => print('Cliente desconectado'),
      );
    }
  }
}
```

Ejecutar:

```bash
dart server.dart
```

## Paso 7: Probar la Aplicación

1. Asegúrate de que el servidor WebSocket esté ejecutándose
2. Ejecuta la aplicación con `flutter run`
3. La pantalla de login debería aparecer
4. Puedes:
   - Iniciar sesión con un usuario existente
   - Registrarte como invitado

## Solución de Problemas

### Error: "No such file or directory" al ejecutar build_runner

```bash
flutter pub cache repair
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: Connection refused al conectar al WebSocket

- Verifica que el servidor WebSocket esté ejecutándose
- Verifica que esté escuchando en el puerto 8080
- Revisa el firewall de tu sistema

### Error: Dependencias no encontradas

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problemas con el emulador

```bash
# Reiniciar el emulador
flutter emulators
flutter emulators --launch <emulator-id>

# O usar un dispositivo físico
flutter devices
```

## Comandos Útiles

```bash
# Limpiar el proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Formatear código
dart format .

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Ver logs en tiempo real
flutter logs

# Hot reload (mientras la app está corriendo)
presiona 'r' en la terminal

# Hot restart (mientras la app está corriendo)
presiona 'R' en la terminal

# Salir de la app
presiona 'q' en la terminal
```

## Próximos Pasos

1. Configurar el servidor WebSocket con la lógica de negocio real
2. Integrar con una base de datos (SQLite, PostgreSQL, etc.)
3. Implementar autenticación real
4. Agregar más casos de prueba
5. Configurar CI/CD para builds automáticos
6. Preparar para publicación en stores (Google Play, App Store)

## Soporte

Si encuentras algún problema:
1. Revisa los logs: `flutter logs`
2. Ejecuta el analizador: `flutter analyze`
3. Limpia y reconstruye: `flutter clean && flutter pub get`
4. Consulta la documentación oficial de Flutter: https://flutter.dev/docs
