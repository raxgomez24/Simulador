# Amerike MBA 2026 - Sistema de Simulación de Inversiones

Aplicación Flutter multiplataforma para la simulación de inversiones en tiempo real.

## Características

- Multiplataforma: Android, iOS, Windows, macOS, Web
- Comunicación en tiempo real vía WebSocket
- State Management con Riverpod y code generation
- Clean Architecture con Repository pattern
- Tema oscuro con Material 3
- Diseño responsivo y optimizado

## Requisitos

- Flutter SDK 3.0+
- Dart 3.0+
- Servidor WebSocket local (Node.js o Dart)

## Instalación

1. Clonar el repositorio:
```bash
git clone <repository-url>
cd Tania
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Generar código (Freezed y Riverpod):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Ejecutar la aplicación:
```bash
# Para development
flutter run

# Para release (Android)
flutter build apk

# Para release (iOS)
flutter build ios
```

## Estructura del Proyecto

```
lib/
├── main.dart                      # Punto de entrada
├── app/                           # Configuración de la app
│   ├── app.dart                   # Widget principal
│   ├── config.dart                # Configuración global
│   └── routes.dart                # Rutas de navegación
├── core/                          # Core y constantes
│   ├── constants/                 # Constantes de la app
│   │   ├── app_colors.dart        # Colores
│   │   ├── app_theme.dart         # Tema
│   │   ├── app_strings.dart       # Strings
│   │   └── api_constants.dart     # Constantes API
│   ├── utils/                     # Utilidades
│   │   ├── validators.dart        # Validadores
│   │   └── formatters.dart        # Formateadores
│   └── errors/                    # Excepciones
│       └── exceptions.dart        # Excepciones personalizadas
├── data/                          # Capa de datos
│   ├── models/                    # Modelos (Freezed)
│   │   ├── user_model.dart
│   │   ├── project_model.dart
│   │   ├── investment_model.dart
│   │   ├── theme_model.dart
│   │   └── session_model.dart
│   ├── datasources/               # Fuentes de datos
│   │   └── remote/
│   │       └── websocket_datasource.dart
│   └── repositories/              # Implementación de repositorios
│       ├── auth_repository_impl.dart
│       ├── project_repository_impl.dart
│       └── investment_repository_impl.dart
├── domain/                        # Capa de dominio
│   ├── entities/                  # Entidades del dominio
│   │   ├── user.dart
│   │   ├── project.dart
│   │   ├── investment.dart
│   │   ├── theme.dart
│   │   └── session.dart
│   ├── repositories/              # Interfaces de repositorios
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── project_repository.dart
│   │   └── investment_repository.dart
│   └── usecases/                  # Casos de uso
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── register_usecase.dart
│       ├── project/
│       │   ├── get_projects_usecase.dart
│       │   └── get_project_detail_usecase.dart
│       └── investment/
│           ├── invest_usecase.dart
│           └── get_investments_usecase.dart
├── presentation/                  # Capa de presentación
│   ├── providers/                 # Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── project_provider.dart
│   │   └── investment_provider.dart
│   ├── screens/                   # Pantallas
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── projects/
│   │   │   ├── projects_list_screen.dart
│   │   │   └── project_detail_screen.dart
│   │   └── admin/
│   │       └── admin_dashboard_screen.dart
│   └── widgets/                   # Widgets reutilizables
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_input.dart
│       │   ├── bottom_nav_bar.dart
│       │   └── timer_badge.dart
│       └── cards/
│           ├── project_card.dart
│           └── category_card.dart
└── services/                      # Servicios
    └── websocket_service.dart     # Servicio WebSocket
```

## Configuración del Servidor WebSocket

La aplicación requiere un servidor WebSocket local. El servidor debe estar escuchando en `ws://localhost:8080`.

### Ejemplo de mensajes WebSocket

#### Login
```json
{
  "type": "auth",
  "action": "login",
  "username": "usuario",
  "password": "contraseña"
}
```

#### Registro como Invitado
```json
{
  "type": "auth",
  "action": "register",
  "username": "usuario",
  "fullName": "Nombre Completo",
  "role": "guest"
}
```

#### Obtener Proyectos
```json
{
  "type": "projects",
  "action": "get_all"
}
```

#### Realizar Inversión
```json
{
  "type": "invest",
  "action": "create",
  "userId": "user-id",
  "projectId": "project-id",
  "amount": 10000
}
```

## Paleta de Colores

- Background Primario: `#121212`
- Background Secundario: `#1E1E1E`
- Background Terciario: `#2D2D44`
- Accent Primario: `#00D4AA`
- Accent Secundario: `#007AFF`
- Éxito: `#10B981`
- Advertencia: `#FF6B35`
- Error: `#EF4444`

## Scripts Disponibles

```bash
# Instalar dependencias
flutter pub get

# Generar código
flutter pub run build_runner build --delete-conflicting-outputs

# Limpiar código generado
flutter pub run build_runner clean

# Ejecutar tests
flutter test

# Análisis de código
flutter analyze

# Formatear código
dart format .

# Ejecutar en emulador
flutter run

# Build para Android (APK)
flutter build apk

# Build para Android (App Bundle)
flutter build appbundle

# Build para iOS
flutter build ios

# Build para Web
flutter build web

# Build para Windows
flutter build windows

# Build para macOS
flutter build macos
```

## Tecnologías Utilizadas

- **Flutter**: Framework UI multiplataforma
- **Dart**: Lenguaje de programación
- **Riverpod**: State management
- **Riverpod Annotation**: Code generation para Riverpod
- **Freezed**: Modelos inmutables con code generation
- **WebSocket**: Comunicación en tiempo real
- **Material 3**: Sistema de diseño

## Desarrollo

### Agregar nuevas pantallas

1. Crear el archivo en `lib/presentation/screens/`
2. Agregar la ruta en `lib/app/routes.dart`
3. Crear los providers necesarios en `lib/presentation/providers/`
4. Agregar navegación desde otras pantallas

### Agregar nuevos modelos

1. Crear el modelo con Freezed en `lib/data/models/`
2. Crear la entidad en `lib/domain/entities/`
3. Ejecutar `flutter pub run build_runner build`
4. Agregar métodos de conversión entre modelo y entidad

### Agregar nuevos casos de uso

1. Crear el caso de uso en `lib/domain/usecases/`
2. Implementar la lógica de negocio
3. Crear el provider correspondiente
4. Usar el provider en las pantallas

## Testing

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ver reporte de coverage
genhtml coverage/lcov.info -o coverage/html
```

## Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## Licencia

Este proyecto es parte del programa MBA 2026 de Amerike.

## Soporte

Para preguntas o soporte, contacta al equipo de desarrollo.
