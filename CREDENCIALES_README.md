# Sistema de Credenciales Externas - Amerike MBA 2026

## Descripción

El sistema ahora lee usuarios y contraseñas desde el archivo `users_credentials.json` ubicado en la raíz del proyecto. Esto permite modificar credenciales sin cambiar el código.

## Ubicación del Archivo

El archivo debe estar en: `/Users/raxgomez/Documents/MBA/Tania/users_credentials.json`

## Formato del Archivo

El archivo JSON tiene la siguiente estructura:

```json
{
  "users": [
    {
      "id": "unique_id",
      "nombre": "Nombre completo",
      "correo": "correo@email.com",
      "username": "usuario",
      "password": "contraseña",
      "perfil": "Admin|Docente|Administrativo|Inversionista|Alumno|Invitado",
      "saldo": 1000000,
      "activo": true,
      "fecha_registro": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

## Usuarios Actuales

| Usuario   | Contraseña | Perfil          | Saldo    |
|-----------|-----------|-----------------|----------|
| **admin** | **admin123** | **Admin** | **$0** |
| juan      | 123456    | Alumno          | $1M      |
| maria      | 123456    | Alumno          | $1M      |
| carlos     | 123456    | Alumno          | $1M      |
| ana        | 123456    | Docente         | $3M      |
| roberto    | 123456    | Docente         | $3M      |
| tania      | 123456    | Administrativo  | $6M      |
| felipe     | 123456    | Inversionista   | $10M     |
| sofia      | 123456    | Invitado        | $2M      |

## ⚠️ Contraseñas de Acceso

**IMPORTANTE - LEER ANTES DE INICIAR SESIÓN:**

- **Administrador**: `admin` / `admin123` ✅
- **Todos los demás usuarios**: `su username` / `123456` ✅

**Ejemplo:**
- Docente Ana: `ana` / `123456`
- Alumno Juan: `juan` / `123456`

## Cómo Modificar Usuarios

1. Abre el archivo `users_credentials.json` en un editor de texto
2. Modifica los datos necesarios (nombre, correo, contraseña, saldo, etc.)
3. Guarda el archivo
4. Reinicia la aplicación para que los cambios surtan efecto

## Cómo Agregar Nuevos Usuarios

1. Abre el archivo `users_credentials.json`
2. Agrega un nuevo objeto al array `users` con el siguiente formato:

```json
{
  "id": "usuario_XXX",
  "nombre": "Nuevo Usuario",
  "correo": "nuevo@email.com",
  "username": "nuevo_usuario",
  "password": "tu_contraseña",
  "perfil": "Alumno",
  "saldo": 1000000,
  "activo": true,
  "fecha_registro": "2024-01-01T00:00:00.000Z"
}
```

3. Guarda el archivo y reinicia la aplicación

## Perfiles Disponibles

- **Admin**: Sin límite de saldo
- **Docente**: $4,000,000 iniciales
- **Administrativo**: $6,000,000 iniciales
- **Inversionista**: $10,000,000 iniciales
- **Alumno**: $1,000,000 iniciales
- **Invitado**: $2,000,000 iniciales

## Notas Importantes

1. **Límite de Usuarios**: El sistema tiene un límite de 100 usuarios
2. **Contraseñas**: Puedes usar cualquier contraseña en el archivo JSON
3. **Saldos**: Los saldos se especifican en el archivo y se usarán al crear el usuario en la base de datos
4. **Prioridad**: El sistema busca primero en el archivo JSON, si no encuentra, busca en la base de datos SQLite

## Solución de Problemas

### "Archivo de credenciales no encontrado"
- Asegúrate de que el archivo `users_credentials.json` esté en la carpeta correcta
- La carpeta correcta es: `/Users/raxgomez/Documents/MBA/Tania/`

### "Usuario o contraseña incorrectos"
- Verifica que el username y password coincidan exactamente con los del archivo
- Recuerda que todas las contraseñas actuales son: `123456`

### Error al parsear JSON
- Verifica que el formato JSON sea válido usando un validador online
- Asegúrate de que todas las comillas y comas estén correctas

## Ejemplo de Usuario Completo

```json
{
  "id": "custom_001",
  "nombre": "Juan Pérez",
  "correo": "juan.perez@empresa.com",
  "username": "juanp",
  "password": "mi_contraseña_segura",
  "perfil": "Inversionista",
  "saldo": 5000000,
  "activo": true,
  "fecha_registro": "2024-05-31T12:00:00.000Z"
}
```

---

**Última actualización**: 2026-05-31
**Versión**: 1.0
