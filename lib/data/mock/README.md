# Sistema de Datos Locales (Mock Data)

Este archivo explica cómo configurar y usar los datos locales en la aplicación Amerike MBA 2026.

## Configuración

Para activar o desactivar el modo de datos locales, edita el archivo `lib/app/config.dart`:

```dart
// Cambia a true para usar datos locales (mock data)
// Cambia a false para usar el servidor WebSocket
static const bool useLocalData = true;
```

## Agregar o Modificar Datos

El archivo principal donde debes agregar o modificar la información es:

**`lib/data/mock/mock_data.dart`**

### Estructura del Archivo

El archivo se divide en tres secciones principales:

#### 1. Temas (Categorías de Inversión)

Ubicado en la lista `mockThemes`. Cada tema tiene la siguiente estructura:

```dart
{
  'id': 'tecnologia',           // Identificador único (sin espacios, minúsculas)
  'nombre': 'Tecnología',       // Nombre visible del tema
  'color': '#2196F3',           // Color en formato HEX
  'icon': '💻',                 // Icono (puede ser emoji o texto)
  'numeroProyectos': 0,         // Se calcula automáticamente
  'totalInvertido': 0.0,        // Se calcula automáticamente
}
```

**Límites:**
- Máximo 10 temas
- El color debe ser un código HEX válido (ej: "#FF5722")
- El icon puede ser un emoji o un texto descriptivo
- `numeroProyectos` y `totalInvertido` se calculan automáticamente

#### 2. Proyectos de Inversión

Ubicado en la lista `mockProjects`. Cada proyecto tiene la siguiente estructura:

```dart
{
  'id': 'proj_tech_001',                    // Identificador único
  'nombre': 'Nombre del Proyecto',          // Título del proyecto
  'descripcion': 'Descripción detallada...', // Descripción completa
  'imagen': null,                           // Ruta de imagen (opcional)
  'temaId': 'tecnologia',                   // ID del tema al que pertenece
  'totalInvertido': 250000.0,               // Monto total invertido
  'numeroInversores': 12,                   // Número de inversores
  'activo': true,                           // Estado del proyecto
}
```

**Límites:**
- Máximo 50 proyectos
- `temaId` debe coincidir con el `id` de un tema existente
- `imagen` puede ser:
  - `null` (sin imagen)
  - Ruta local: `"assets/images/project1.jpg"`
  - URL: `"https://ejemplo.com/imagen.jpg"`

#### 3. Usuarios de Prueba

Ubicado en la lista `mockUsers`. Cada usuario tiene la siguiente estructura:

```dart
{
  'id': 'user_student_001',              // Identificador único
  'nombre': 'Juan Pérez García',         // Nombre completo
  'correo': 'juan@ejemplo.com',          // Correo electrónico
  'username': 'juan',                    // Usuario para login
  'password': '123456',                  // Contraseña para login
  'perfil': 'Alumno',                    // Perfil: Admin, Alumno, Docente, Administrativo, Inversionista, Invitado
  'saldo': 1000000,                      // Saldo inicial de inversión
  'activo': true,                        // Estado del usuario
  'fechaRegistro': '2024-03-10T10:30:00.000Z', // Fecha de registro
}
```

**Perfiles y montos iniciales:**
- Admin: $0 (solo administración)
- Alumno: $1,000,000 MXN
- Docente: $3,000,000 MXN
- Administrativo: $6,000,000 MXN
- Inversionista: $10,000,000 MXN
- Invitado: $2,000,000 MXN

**Usuarios de prueba incluidos:**
- `admin` / `admin123` - Administrador
- `juan` / `123456` - Alumno ($1,000,000)
- `maria` / `123456` - Alumno ($1,000,000)
- `carlos` / `123456` - Alumno ($1,000,000)
- `ana` / `123456` - Docente ($3,000,000)
- `roberto` / `123456` - Docente ($3,000,000)
- `laura` / `123456` - Administrativo ($6,000,000)
- `felipe` / `123456` - Inversionista ($10,000,000)
- `sofia` / `123456` - Invitado ($2,000,000)

#### 4. Funciones de Utilidad

No necesitas modificar estas funciones. Ellas procesan automáticamente los datos:

- `getProcessedThemes()`: Calcula el número de proyectos y total invertido por tema
- `getProcessedProjects()`: Asigna el nombre y color del tema a cada proyecto

## Ejemplos de Uso

### Agregar un Nuevo Tema

```dart
{
  'id': 'agricultura',
  'nombre': 'Agricultura Sostenible',
  'color': '#8BC34A',  // Verde claro
  'icon': '🌱',
  'numeroProyectos': 0,
  'totalInvertido': 0.0,
},
```

### Agregar un Nuevo Proyecto

```dart
{
  'id': 'proj_agri_001',
  'nombre': 'Huertos Urbanos',
  'descripcion': 'Sistema de huertos urbanos automatizados con IoT para optimizar el cultivo en espacios reducidos.',
  'imagen': 'assets/images/huertos.jpg',
  'temaId': 'agricultura',
  'totalInvertido': 150000.0,
  'numeroInversores': 8,
  'activo': true,
},
```

## Colores HEX Comunes

Aquí tienes algunos códigos HEX útiles:

- Rojo: `#F44336`
- Naranja: `#FF9800`
- Amarillo: `#FFEB3B`
- Verde: `#4CAF50`
- Azul: `#2196F3`
- Índigo: `#3F51B5`
- Púrpura: `#9C27B0`
- Rosa: `#E91E63`
- Cian: `#00BCD4`
- Marrón: `#795548`
- Gris: `#9E9E9E`

## Emojis Comunes para Iconos

- Tecnología: `💻`, `🔧`, `⚙️`
- Salud: `🏥`, `💊`, `❤️`
- Educación: `📚`, `🎓`, `✏️`
- Energía: `⚡`, `🔋`, `☀️`
- Finanzas: `💰`, `📈`, `💳`
- Retail: `🛒`, `🛍️`, `🏪`
- Inmobiliaria: `🏠`, `🏢`, `🏗️`
- Transporte: `🚚`, `✈️`, `🚂`
- Agricultura: `🌱`, `🌾`, `🚜`
- Medio ambiente: `🌍`, `♻️`, `🌿`

## Verificación de Datos

Para verificar que los datos están correctamente configurados:

1. Asegúrate que `useLocalData = true` en `lib/app/config.dart`
2. Ejecuta la aplicación: `flutter run`
3. La aplicación debería cargar los temas y proyectos sin errores
4. Verifica en la consola que no haya errores de conexión WebSocket

## Solución de Problemas

### Error: "Tema no encontrado"
- Verifica que el `temaId` de cada proyecto coincida con el `id` de un tema existente
- Los IDs son case-sensitive (diferencian mayúsculas y minúsculas)

### Error: "Proyecto no encontrado"
- Verifica que el `id` del proyecto sea único
- No debe haber proyectos con el mismo `id`

### Pantalla en blanco
- Verifica que hay al menos un tema y un proyecto
- Revisa la consola de Flutter para ver errores específicos

## Cambiar a Modo Servidor

Para usar el servidor WebSocket en lugar de datos locales:

1. Cambia en `lib/app/config.dart`:
   ```dart
   static const bool useLocalData = false;
   ```

2. Asegúrate que el servidor esté corriendo en `ws://localhost:8080`

3. Reinicia la aplicación

## Notas Importantes

- Los cambios en `mock_data.dart` requieren reiniciar la aplicación (hot reload no actualiza los datos)
- Mantén los IDs únicos y descriptivos
- Usa descripciones claras y concisas para los proyectos
- El sistema calcula automáticamente las estadísticas de los temas
- Puedes agregar hasta 10 temas y 50 proyectos según las especificaciones
