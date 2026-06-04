/// Archivo de datos locales para la aplicación Amerike MBA 2026
///
/// ESTE ES EL ARCHIVO PRINCIPAL DONDE DEBES AGREGAR O MODIFICAR
/// LA INFORMACIÓN DE TEMAS Y PROYECTOS.
///
/// Instrucciones para agregar/modificar información:
///
/// 1. TEMAS (Categorías):
///    - Agrega hasta 10 temas en la lista `mockThemes`
///    - Cada tema necesita: id, nombre, color (hex), icon (emoji o texto)
///    - El color debe ser un código HEX válido (ej: "#FF5722")
///    - El icon puede ser un emoji o un texto descriptivo
///
/// 2. PROYECTOS:
///    - Agrega hasta 50 proyectos en la lista `mockProjects`
///    - Cada proyecto necesita: id, nombre, descripción, temaId, etc.
///    - El `temaId` debe coincidir con el `id` de un tema en `mockThemes`
///    - La imagen puede ser una ruta local (ej: "assets/images/project1.jpg")
///      o una URL (ej: "https://ejemplo.com/imagen.jpg")
///
/// 3. RELACIÓN:
///    - Cada proyecto debe tener un `temaId` válido
///    - Los temas calculan automáticamente el número de proyectos e inversión total

import '../models/project_model.dart';
import '../models/theme_model.dart';

/// ============================================================================
/// TEMAS (CATEGORÍAS DE INVERSIÓN)
/// ============================================================================
/// AGREGA AQUÍ TUS TEMAS - Máximo 10 temas
/// Cada tema representa una categoría de inversión principal
/// ============================================================================

final List<Map<String, dynamic>> mockThemes = [
  {
    'id': 'tecnologia',
    'nombre': 'Tecnología',
    'color': '#2196F3', // Azul
    'icon': '💻',
    'numeroProyectos': 0, // Se calcula automáticamente
    'totalInvertido': 0.0, // Se calcula automáticamente
  },
  {
    'id': 'salud',
    'nombre': 'Salud y Bienestar',
    'color': '#4CAF50', // Verde
    'icon': '🏥',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'educacion',
    'nombre': 'Educación',
    'color': '#FF9800', // Naranja
    'icon': '📚',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'energia',
    'nombre': 'Energía Sostenible',
    'color': '#00BCD4', // Cyan
    'icon': '⚡',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'finanzas',
    'nombre': 'Finanzas',
    'color': '#9C27B0', // Púrpura
    'icon': '💰',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'retail',
    'nombre': 'Comercio y Retail',
    'color': '#E91E63', // Rosa
    'icon': '🛒',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'inmobiliaria',
    'nombre': 'Bienes Raíces',
    'color': '#795548', // Marrón
    'icon': '🏠',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
  {
    'id': 'transporte',
    'nombre': 'Transporte y Logística',
    'color': '#607D8B', // Gris azulado
    'icon': '🚚',
    'numeroProyectos': 0,
    'totalInvertido': 0.0,
  },
];

/// ============================================================================
/// PROYECTOS DE INVERSIÓN
/// ============================================================================
/// AGREGA AQUÍ TUS PROYECTOS - Máximo 50 proyectos
/// Cada proyecto debe tener un `temaId` que exista en la lista de temas arriba
/// ============================================================================

final List<Map<String, dynamic>> mockProjects = [
  // PROYECTOS DE TECNOLOGÍA
  {
    'id': 'proj_tech_001',
    'nombre': 'Inteligencia Artificial Médica',
    'descripcion': 'Plataforma de IA que ayuda a diagnosticar enfermedades raras mediante análisis de imágenes médicas y datos clínicos. Utiliza redes neuronales profundas para identificar patrones que los médicos podrían pasar por alto.',
    'imagen': null, // Puedes poner una ruta como "assets/images/ai_medical.jpg"
    'temaId': 'tecnologia',
    'totalInvertido': 250000.0,
    'numeroInversores': 12,
    'activo': true,
  },
  {
    'id': 'proj_tech_002',
    'nombre': 'Blockchain para Supply Chain',
    'descripcion': 'Sistema de trazabilidad basado en blockchain para cadenas de suministro internacionales. Permite rastrear productos desde el origen hasta el consumidor final con total transparencia.',
    'imagen': null,
    'temaId': 'tecnologia',
    'totalInvertido': 180000.0,
    'numeroInversores': 8,
    'activo': true,
  },
  {
    'id': 'proj_tech_003',
    'nombre': 'EdTech Plataforma',
    'descripcion': 'Plataforma educativa adaptativa que personaliza el contenido según el estilo de aprendizaje de cada estudiante. Utiliza machine learning para optimizar el proceso de enseñanza.',
    'imagen': null,
    'temaId': 'tecnologia',
    'totalInvertido': 320000.0,
    'numeroInversores': 15,
    'activo': true,
  },
  {
    'id': 'proj_tech_004',
    'nombre': 'Ciberseguridad Corporativa',
    'descripcion': 'Solución integral de ciberseguridad para PYMES que incluye monitoreo en tiempo real, detección de amenazas y respuesta automatizada a incidentes.',
    'imagen': null,
    'temaId': 'tecnologia',
    'totalInvertido': 210000.0,
    'numeroInversores': 10,
    'activo': true,
  },
  {
    'id': 'proj_tech_005',
    'nombre': 'IoT Smart Agriculture',
    'descripcion': 'Sistema de sensores IoT y análisis predictivo para agricultura de precisión. Optimiza el uso de agua, fertilizantes y pesticidas reduciendo costos y aumentando rendimientos.',
    'imagen': null,
    'temaId': 'tecnologia',
    'totalInvertido': 275000.0,
    'numeroInversores': 11,
    'activo': true,
  },

  // PROYECTOS DE SALUD
  {
    'id': 'proj_health_001',
    'nombre': 'Telemedicina 2.0',
    'descripcion': 'Plataforma de telemedicina con consulta virtual, recetas electrónicas y seguimiento de pacientes crónicos. Incluye integración con dispositivos médicos IoT.',
    'imagen': null,
    'temaId': 'salud',
    'totalInvertido': 450000.0,
    'numeroInversores': 20,
    'activo': true,
  },
  {
    'id': 'proj_health_002',
    'nombre': 'Biotecnología Farmacéutica',
    'descripcion': 'Investigación y desarrollo de fármacos basados en biotecnología para tratamiento de enfermedades autoinmunes. Utiliza CRISPR y otras tecnologías de edición genética.',
    'imagen': null,
    'temaId': 'salud',
    'totalInvertido': 680000.0,
    'numeroInversores': 25,
    'activo': true,
  },
  {
    'id': 'proj_health_003',
    'nombre': 'Dispositivos Wearables',
    'descripcion': 'Línea de dispositivos wearable que monitorean signos vitales, actividad física y salud mental con alertas en tiempo real para pacientes de alto riesgo.',
    'imagen': null,
    'temaId': 'salud',
    'totalInvertido': 380000.0,
    'numeroInversores': 18,
    'activo': true,
  },
  {
    'id': 'proj_health_004',
    'nombre': 'Salud Mental Digital',
    'descripcion': 'App de terapia cognitivo-conductual con IA que ofrece soporte 24/7 para ansiedad, depresión y trastornos del sueño. Incluye conexión con terapeutas humanos.',
    'imagen': null,
    'temaId': 'salud',
    'totalInvertido': 290000.0,
    'numeroInversores': 14,
    'activo': true,
  },
  {
    'id': 'proj_health_005',
    'nombre': 'Nutrición Personalizada',
    'descripcion': 'Plataforma que crea planes de nutrición basados en genética, estilo de vida y objetivos de salud. Incluye delivery de comidas personalizadas.',
    'imagen': null,
    'temaId': 'salud',
    'totalInvertido': 220000.0,
    'numeroInversores': 12,
    'activo': true,
  },

  // PROYECTOS DE EDUCACIÓN
  {
    'id': 'proj_edu_001',
    'nombre': 'Universidad Virtual',
    'descripcion': 'Plataforma de educación superior completamente online con certificaciones reconocidas internacionalmente. Ofrece programas en tecnología, negocios y ciencias.',
    'imagen': null,
    'temaId': 'educacion',
    'totalInvertido': 520000.0,
    'numeroInversores': 22,
    'activo': true,
  },
  {
    'id': 'proj_edu_002',
    'nombre': 'Formación Profesional VR',
    'descripcion': 'Plataforma de formación profesional que utiliza realidad virtual para simulaciones prácticas en medicina, ingeniería y oficios técnicos.',
    'imagen': null,
    'temaId': 'educacion',
    'totalInvertido': 340000.0,
    'numeroInversores': 16,
    'activo': true,
  },
  {
    'id': 'proj_edu_003',
    'nombre': 'Idiomas con IA',
    'descripcion': 'App de aprendizaje de idiomas que utiliza IA para crear conversaciones naturales y corregir pronunciación en tiempo real. Soporta 15 idiomas.',
    'imagen': null,
    'temaId': 'educacion',
    'totalInvertido': 260000.0,
    'numeroInversores': 13,
    'activo': true,
  },
  {
    'id': 'proj_edu_004',
    'nombre': 'STEM para Niños',
    'descripcion': 'Plataforma educativa gamificada para niños que enseña ciencia, tecnología, ingeniería y matemáticas mediante proyectos prácticos y experimentos virtuales.',
    'imagen': null,
    'temaId': 'educacion',
    'totalInvertido': 190000.0,
    'numeroInversores': 10,
    'activo': true,
  },

  // PROYECTOS DE ENERGÍA SOSTENIBLE
  {
    'id': 'proj_energy_001',
    'nombre': 'Parque Solar Comunitario',
    'descripcion': 'Desarrollo de parques solares para abastecer a comunidades rurales con energía renovable. Incluye almacenamiento en baterías y red inteligente.',
    'imagen': null,
    'temaId': 'energia',
    'totalInvertido': 750000.0,
    'numeroInversores': 30,
    'activo': true,
  },
  {
    'id': 'proj_energy_002',
    'nombre': 'Energía Eólica Offshore',
    'descripcion': 'Proyecto de parques eólicos en alta mar con turbinas de última generación. Capacidad para generar electricidad para 50,000 hogares.',
    'imagen': null,
    'temaId': 'energia',
    'totalInvertido': 1200000.0,
    'numeroInversores': 45,
    'activo': true,
  },
  {
    'id': 'proj_energy_003',
    'nombre': 'Biocombustibles Avanzados',
    'descripcion': 'Producción de biocombustibles de segunda generación a partir de residuos agrícolas. Proceso sostenible con huella de carbono negativa.',
    'imagen': null,
    'temaId': 'energia',
    'totalInvertido': 480000.0,
    'numeroInversores': 20,
    'activo': true,
  },
  {
    'id': 'proj_energy_004',
    'nombre': 'Hidrógeno Verde',
    'descripcion': 'Planta de producción de hidrógeno verde mediante electrólisis con energía renovable. Abastece a industria del transporte y manufactura.',
    'imagen': null,
    'temaId': 'energia',
    'totalInvertido': 890000.0,
    'numeroInversores': 35,
    'activo': true,
  },

  // PROYECTOS DE FINANZAS
  {
    'id': 'proj_finance_001',
    'nombre': 'Fintech Pagos Internacionales',
    'descripcion': 'Plataforma de pagos transfronterizos con comisiones bajas y transferencias instantáneas utilizando blockchain. Enfocada en remesas y comercio B2B.',
    'imagen': null,
    'temaId': 'finanzas',
    'totalInvertido': 420000.0,
    'numeroInversores': 18,
    'activo': true,
  },
  {
    'id': 'proj_finance_002',
    'nombre': 'Inversión Social',
    'descripcion': 'Plataforma de inversión que permite a usuarios invertir en proyectos con impacto social y ambiental. Reportes de ESG en tiempo real.',
    'imagen': null,
    'temaId': 'finanzas',
    'totalInvertido': 360000.0,
    'numeroInversores': 15,
    'activo': true,
  },
  {
    'id': 'proj_finance_003',
    'nombre': 'Crédito para PYMES',
    'descripcion': 'Plataforma de crédito para pequeñas y medianas empresas utilizando análisis alternativo de datos y machine learning para evaluación de riesgo.',
    'imagen': null,
    'temaId': 'finanzas',
    'totalInvertido': 580000.0,
    'numeroInversores': 24,
    'activo': true,
  },
  {
    'id': 'proj_finance_004',
    'nombre': 'Seguros Digitalizados',
    'descripcion': 'Aseguradora digital que ofrece pólizas personalizadas con precios dinámicos basados en comportamiento. Proceso 100% digital y sin papeleo.',
    'imagen': null,
    'temaId': 'finanzas',
    'totalInvertido': 440000.0,
    'numeroInversores': 19,
    'activo': true,
  },

  // PROYECTOS DE RETAIL
  {
    'id': 'proj_retail_001',
    'nombre': 'Marketplace Local',
    'descripcion': 'Plataforma de e-commerce que conecta productores locales con consumidores. Enfocado en productos artesanales, orgánicos y de comercio justo.',
    'imagen': null,
    'temaId': 'retail',
    'totalInvertido': 280000.0,
    'numeroInversores': 12,
    'activo': true,
  },
  {
    'id': 'proj_retail_002',
    'nombre': 'Tienda Inteligente',
    'descripcion': 'Cadena de tiendas con tecnología de reconocimiento de imágenes, pagos automáticos y personalización de ofertas en tiempo real.',
    'imagen': null,
    'temaId': 'retail',
    'totalInvertido': 620000.0,
    'numeroInversores': 28,
    'activo': true,
  },
  {
    'id': 'proj_retail_003',
    'nombre': 'Moda Sostenible',
    'descripcion': 'Marca de ropa sostenible con materiales reciclados y producción ética. Modelo de negocio circular con programa de reciclaje de prendas.',
    'imagen': null,
    'temaId': 'retail',
    'totalInvertido': 340000.0,
    'numeroInversores': 16,
    'activo': true,
  },

  // PROYECTOS INMOBILIARIOS
  {
    'id': 'proj_real_estate_001',
    'nombre': 'Vivienda Asequible',
    'descripcion': 'Desarrollo de viviendas asequibles con construcción modular y eficiente en energía. Enfocado en clase media emergente.',
    'imagen': null,
    'temaId': 'inmobiliaria',
    'totalInvertido': 920000.0,
    'numeroInversores': 38,
    'activo': true,
  },
  {
    'id': 'proj_real_estate_002',
    'nombre': 'Coworking Híbrido',
    'descripcion': 'Red de espacios de coworking con modelo híbrido físico-virtual. Incluye salas de reuniones VR y servicios para nómadas digitales.',
    'imagen': null,
    'temaId': 'inmobiliaria',
    'totalInvertido': 560000.0,
    'numeroInversores': 22,
    'activo': true,
  },
  {
    'id': 'proj_real_estate_003',
    'nombre': 'Logística Urbana',
    'descripcion': 'Centros de distribución urbanos automatizados para e-commerce de último kilómetro. Reducen tiempos de entrega y tráfico urbano.',
    'imagen': null,
    'temaId': 'inmobiliaria',
    'totalInvertido': 780000.0,
    'numeroInversores': 32,
    'activo': true,
  },

  // PROYECTOS DE TRANSPORTE
  {
    'id': 'proj_transport_001',
    'nombre': 'Logística Verde',
    'descripcion': 'Empresa de logística con flota de vehículos eléctricos y rutas optimizadas por IA. Reducción de 60% en emisiones de CO2.',
    'imagen': null,
    'temaId': 'transporte',
    'totalInvertido': 640000.0,
    'numeroInversores': 26,
    'activo': true,
  },
  {
    'id': 'proj_transport_002',
    'nombre': 'Movilidad Compartida',
    'descripcion': 'Plataforma de movilidad compartida que integra transporte público, bicicletas eléctricas y scooters en una sola app.',
    'imagen': null,
    'temaId': 'transporte',
    'totalInvertido': 380000.0,
    'numeroInversores': 17,
    'activo': true,
  },
  {
    'id': 'proj_transport_003',
    'nombre': 'Drone Delivery',
    'descripcion': 'Servicio de entrega por drones para medicamentos y productos urgentes. Enfocado en zonas rurales y de difícil acceso.',
    'imagen': null,
    'temaId': 'transporte',
    'totalInvertido': 460000.0,
    'numeroInversores': 20,
    'activo': true,
  },
];

/// ============================================================================
/// FUNCIONES DE UTILIDAD (NO MODIFICAR)
/// ============================================================================
/// Estas funciones calculan automáticamente los datos de los temas
/// ============================================================================

/// Calcula el número de proyectos y el total invertido para cada tema
List<ThemeModel> getProcessedThemes() {
  final themes = <ThemeModel>[];

  for (var themeData in mockThemes) {
    final themeId = themeData['id'] as String;

    // Contar proyectos y sumar inversiones para este tema
    final themeProjects = mockProjects.where((p) => p['temaId'] == themeId).toList();
    final numeroProyectos = themeProjects.length;
    final totalInvertido = themeProjects.fold<double>(
      0.0,
      (sum, project) => sum + (project['totalInvertido'] as double),
    );

    // Actualizar los datos calculados
    themeData['numeroProyectos'] = numeroProyectos;
    themeData['totalInvertido'] = totalInvertido;

    // Obtener el nombre del tema para los proyectos
    final themeNombre = themeData['nombre'] as String;
    final themeColor = themeData['color'] as String;

    themes.add(ThemeModel.fromJson({
      ...themeData,
      'nombre': themeNombre,
      'color': themeColor,
    }));
  }

  return themes;
}

/// Obtiene los proyectos con información completa del tema
List<ProjectModel> getProcessedProjects() {
  final projects = <ProjectModel>[];

  // Crear un mapa de temas para búsqueda rápida
  final themeMap = <String, Map<String, dynamic>>{};
  for (var theme in mockThemes) {
    themeMap[theme['id'] as String] = theme;
  }

  for (var projectData in mockProjects) {
    final themeId = projectData['temaId'] as String;
    final theme = themeMap[themeId];

    if (theme != null) {
      projects.add(ProjectModel.fromJson({
        ...projectData,
        'temaNombre': theme['nombre'] as String,
        'temaColor': theme['color'] as String,
        'createdAt': DateTime.now().toIso8601String(),
      }));
    }
  }

  return projects;
}

/// ============================================================================
/// USUARIOS DE PRUEBA PARA INICIAR SESIÓN
/// ============================================================================
/// AGREGA AQUÍ TUS USUARIOS DE PRUEBA
/// Cada usuario puede iniciar sesión con su username y password
/// ============================================================================

final List<Map<String, dynamic>> mockUsers = [
  // ADMINISTRADOR
  {
    'id': 'user_admin_001',
    'nombre': 'Administrador Principal',
    'correo': 'admin@amerike.edu',
    'username': 'admin',
    'password': 'admin123',
    'perfil': 'Admin',
    'saldo': 0,
    'activo': true,
    'fechaRegistro': '2024-01-15T00:00:00.000Z',
  },

  // ALUMNOS ($1,000,000 MXN)
  {
    'id': 'user_student_001',
    'nombre': 'Juan Pérez García',
    'correo': 'juan.perez@alumno.amerike.edu',
    'username': 'juan',
    'password': '123456',
    'perfil': 'Alumno',
    'saldo': 1000000,
    'activo': true,
    'fechaRegistro': '2024-03-10T10:30:00.000Z',
  },
  {
    'id': 'user_student_002',
    'nombre': 'María López Sánchez',
    'correo': 'maria.lopez@alumno.amerike.edu',
    'username': 'maria',
    'password': '123456',
    'perfil': 'Alumno',
    'saldo': 1000000,
    'activo': true,
    'fechaRegistro': '2024-03-12T14:20:00.000Z',
  },
  {
    'id': 'user_student_003',
    'nombre': 'Carlos Rodríguez Martínez',
    'correo': 'carlos.rm@alumno.amerike.edu',
    'username': 'carlos',
    'password': '123456',
    'perfil': 'Alumno',
    'saldo': 1000000,
    'activo': true,
    'fechaRegistro': '2024-03-15T09:45:00.000Z',
  },

  // DOCENTES ($3,000,000 MXN)
  {
    'id': 'user_teacher_001',
    'nombre': 'Dra. Ana Martínez Hernández',
    'correo': 'ana.martinez@amerike.edu',
    'username': 'ana',
    'password': '123456',
    'perfil': 'Docente',
    'saldo': 3000000,
    'activo': true,
    'fechaRegistro': '2024-02-01T08:00:00.000Z',
  },
  {
    'id': 'user_teacher_002',
    'nombre': 'Dr. Roberto González Torres',
    'correo': 'roberto.gonzalez@amerike.edu',
    'username': 'roberto',
    'password': '123456',
    'perfil': 'Docente',
    'saldo': 3000000,
    'activo': true,
    'fechaRegistro': '2024-02-05T10:15:00.000Z',
  },

  // ADMINISTRATIVOS ($6,000,000 MXN)
  {
    'id': 'user_employee_001',
    'nombre': 'Tania Jiménez Narcia',
    'correo': 'tjimenez@amerike.edu',
    'username': 'tania',
    'password': '123456',
    'perfil': 'Administrativo',
    'saldo': 6000000,
    'activo': true,
    'fechaRegistro': '2024-01-20T09:00:00.000Z',
  },

  // INVERSIONISTAS ($10,000,000 MXN)
  {
    'id': 'user_investor_001',
    'nombre': 'Felipe Castillo Moreno',
    'correo': 'felipe.castillo@inversor.com',
    'username': 'felipe',
    'password': '123456',
    'perfil': 'Inversionista',
    'saldo': 10000000,
    'activo': true,
    'fechaRegistro': '2024-02-20T11:30:00.000Z',
  },

  // INVITADOS ($2,000,000 MXN)
  {
    'id': 'user_guest_001',
    'nombre': 'Sofía Ramírez Vega',
    'correo': 'sofia.ramirez@correo.com',
    'username': 'sofia',
    'password': '123456',
    'perfil': 'Invitado',
    'saldo': 2000000,
    'activo': true,
    'fechaRegistro': '2024-04-01T16:45:00.000Z',
  },
];
