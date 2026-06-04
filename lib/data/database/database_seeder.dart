import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/theme_model.dart';
import '../models/project_model.dart';
import 'database_helper.dart';
import 'user_dao.dart';
import 'theme_dao.dart';
import 'project_dao.dart';

/// Database seeder for initializing default data
///
/// This class handles the seeding of initial data into the database when
/// it's first created or when it needs to be reset.
class DatabaseSeeder {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final UserDao _userDao = UserDao();
  final ThemeDao _themeDao = ThemeDao();
  final ProjectDao _projectDao = ProjectDao();
  final _logger = Logger('DatabaseSeeder');

  /// Check if database needs seeding
  Future<bool> needsSeeding() async {
    return await _dbHelper.isEmpty();
  }

  /// Seed all default data into the database
  Future<void> seedAll() async {
    _logger.info('Starting database seeding...');

    if (!await needsSeeding()) {
      _logger.info('Database already contains data. Skipping seeding.');
      return;
    }

    try {
      // Seed themes first (as they're referenced by projects)
      await seedThemes();

      // Seed projects (they reference themes)
      await seedProjects();

      // Seed users (they can be independent)
      await seedUsers();

      // Seed investments (they reference users and projects)
      // Note: We're not seeding default investments as they should be user-generated

      _logger.info('Database seeding completed successfully');

      // Log final statistics
      final stats = await _dbHelper.getStatistics();
      _logger.info('Database statistics: $stats');
    } catch (e) {
      _logger.severe('Error during database seeding: $e');
      rethrow;
    }
  }

  /// Seed default themes
  Future<void> seedThemes() async {
    _logger.info('Seeding themes...');

    final themes = [
      ThemeModel(
        id: 'tecnologia',
        nombre: 'Tecnología',
        color: '#2196F3',
        icon: '💻',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Proyectos de tecnología, software, IA y desarrollo',
        orden: 1,
        activo: true,
      ),
      ThemeModel(
        id: 'salud',
        nombre: 'Salud y Bienestar',
        color: '#4CAF50',
        icon: '🏥',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Proyectos de salud, medicina, bienestar y vida',
        orden: 2,
        activo: true,
      ),
      ThemeModel(
        id: 'educacion',
        nombre: 'Educación',
        color: '#FF9800',
        icon: '📚',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Proyectos educativos, e-learning y formación',
        orden: 3,
        activo: true,
      ),
      ThemeModel(
        id: 'energia',
        nombre: 'Energía Sostenible',
        color: '#00BCD4',
        icon: '⚡',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Energías renovables y sostenibilidad ambiental',
        orden: 4,
        activo: true,
      ),
      ThemeModel(
        id: 'finanzas',
        nombre: 'Finanzas',
        color: '#9C27B0',
        icon: '💰',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Servicios financieros, fintech y gestión de capital',
        orden: 5,
        activo: true,
      ),
      ThemeModel(
        id: 'retail',
        nombre: 'Comercio y Retail',
        color: '#E91E63',
        icon: '🛒',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Comercio electrónico, retail y comercio local',
        orden: 6,
        activo: true,
      ),
      ThemeModel(
        id: 'inmobiliaria',
        nombre: 'Bienes Raíces',
        color: '#795548',
        icon: '🏠',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Inmobiliario, construcción y desarrollo urbano',
        orden: 7,
        activo: true,
      ),
      ThemeModel(
        id: 'transporte',
        nombre: 'Transporte y Logística',
        color: '#607D8B',
        icon: '🚚',
        numeroProyectos: 0,
        totalInvertido: 0,
        descripcion: 'Transporte, logística y movilidad',
        orden: 8,
        activo: true,
      ),
    ];

    await _themeDao.insertThemes(themes);
    _logger.info('Seeded ${themes.length} themes');
  }

  /// Seed default projects
  Future<void> seedProjects() async {
    _logger.info('Seeding projects...');

    final projects = _getDefaultProjects();
    await _projectDao.insertProjects(projects);
    _logger.info('Seeded ${projects.length} projects');
  }

  /// Seed default users
  Future<void> seedUsers() async {
    _logger.info('Seeding users...');

    final users = _getDefaultUsers();
    await _userDao.insertUsers(users);
    _logger.info('Seeded ${users.length} users');
  }

  /// Get default projects data
  List<ProjectModel> _getDefaultProjects() {
    return [
      // PROYECTOS DE TECNOLOGÍA
      ProjectModel(
        id: 'proj_tech_001',
        nombre: 'Inteligencia Artificial Médica',
        descripcion: 'Plataforma de IA que ayuda a diagnosticar enfermedades raras mediante análisis de imágenes médicas y datos clínicos. Utiliza redes neuronales profundas para identificar patrones que los médicos podrían pasar por alto.',
        imagen: null,
        temaId: 'tecnologia',
        temaNombre: 'Tecnología',
        temaColor: '#2196F3',
        totalInvertido: 250000.0,
        numeroInversores: 12,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_tech_002',
        nombre: 'Blockchain para Supply Chain',
        descripcion: 'Sistema de trazabilidad basado en blockchain para cadenas de suministro internacionales. Permite rastrear productos desde el origen hasta el consumidor final con total transparencia.',
        imagen: null,
        temaId: 'tecnologia',
        temaNombre: 'Tecnología',
        temaColor: '#2196F3',
        totalInvertido: 180000.0,
        numeroInversores: 8,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_tech_003',
        nombre: 'EdTech Plataforma',
        descripcion: 'Plataforma educativa adaptativa que personaliza el contenido según el estilo de aprendizaje de cada estudiante. Utiliza machine learning para optimizar el proceso de enseñanza.',
        imagen: null,
        temaId: 'tecnologia',
        temaNombre: 'Tecnología',
        temaColor: '#2196F3',
        totalInvertido: 320000.0,
        numeroInversores: 15,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
      ProjectModel(
        id: 'proj_tech_004',
        nombre: 'Ciberseguridad Corporativa',
        descripcion: 'Solución integral de ciberseguridad para PYMES que incluye monitoreo en tiempo real, detección de amenazas y respuesta automatizada a incidentes.',
        imagen: null,
        temaId: 'tecnologia',
        temaNombre: 'Tecnología',
        temaColor: '#2196F3',
        totalInvertido: 210000.0,
        numeroInversores: 10,
        createdAt: DateTime.now(),
        activo: true,
        orden: 4,
      ),
      ProjectModel(
        id: 'proj_tech_005',
        nombre: 'IoT Smart Agriculture',
        descripcion: 'Sistema de sensores IoT y análisis predictivo para agricultura de precisión. Optimiza el uso de agua, fertilizantes y pesticidas reduciendo costos y aumentando rendimientos.',
        imagen: null,
        temaId: 'tecnologia',
        temaNombre: 'Tecnología',
        temaColor: '#2196F3',
        totalInvertido: 275000.0,
        numeroInversores: 11,
        createdAt: DateTime.now(),
        activo: true,
        orden: 5,
      ),

      // PROYECTOS DE SALUD
      ProjectModel(
        id: 'proj_health_001',
        nombre: 'Telemedicina 2.0',
        descripcion: 'Plataforma de telemedicina con consulta virtual, recetas electrónicas y seguimiento de pacientes crónicos. Incluye integración con dispositivos médicos IoT.',
        imagen: null,
        temaId: 'salud',
        temaNombre: 'Salud y Bienestar',
        temaColor: '#4CAF50',
        totalInvertido: 450000.0,
        numeroInversores: 20,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_health_002',
        nombre: 'Biotecnología Farmacéutica',
        descripcion: 'Investigación y desarrollo de fármacos basados en biotecnología para tratamiento de enfermedades autoinmunes. Utiliza CRISPR y otras tecnologías de edición genética.',
        imagen: null,
        temaId: 'salud',
        temaNombre: 'Salud y Bienestar',
        temaColor: '#4CAF50',
        totalInvertido: 680000.0,
        numeroInversores: 25,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_health_003',
        nombre: 'Dispositivos Wearables',
        descripcion: 'Línea de dispositivos wearable que monitorean signos vitales, actividad física y salud mental con alertas en tiempo real para pacientes de alto riesgo.',
        imagen: null,
        temaId: 'salud',
        temaNombre: 'Salud y Bienestar',
        temaColor: '#4CAF50',
        totalInvertido: 380000.0,
        numeroInversores: 18,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
      ProjectModel(
        id: 'proj_health_004',
        nombre: 'Salud Mental Digital',
        descripcion: 'App de terapia cognitivo-conductual con IA que ofrece soporte 24/7 para ansiedad, depresión y trastornos del sueño. Incluye conexión con terapeutas humanos.',
        imagen: null,
        temaId: 'salud',
        temaNombre: 'Salud y Bienestar',
        temaColor: '#4CAF50',
        totalInvertido: 290000.0,
        numeroInversores: 14,
        createdAt: DateTime.now(),
        activo: true,
        orden: 4,
      ),
      ProjectModel(
        id: 'proj_health_005',
        nombre: 'Nutrición Personalizada',
        descripcion: 'Plataforma que crea planes de nutrición basados en genética, estilo de vida y objetivos de salud. Incluye delivery de comidas personalizadas.',
        imagen: null,
        temaId: 'salud',
        temaNombre: 'Salud y Bienestar',
        temaColor: '#4CAF50',
        totalInvertido: 220000.0,
        numeroInversores: 12,
        createdAt: DateTime.now(),
        activo: true,
        orden: 5,
      ),

      // PROYECTOS DE EDUCACIÓN
      ProjectModel(
        id: 'proj_edu_001',
        nombre: 'Universidad Virtual',
        descripcion: 'Plataforma de educación superior completamente online con certificaciones reconocidas internacionalmente. Ofrece programas en tecnología, negocios y ciencias.',
        imagen: null,
        temaId: 'educacion',
        temaNombre: 'Educación',
        temaColor: '#FF9800',
        totalInvertido: 520000.0,
        numeroInversores: 22,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_edu_002',
        nombre: 'Formación Profesional VR',
        descripcion: 'Plataforma de formación profesional que utiliza realidad virtual para simulaciones prácticas en medicina, ingeniería y oficios técnicos.',
        imagen: null,
        temaId: 'educacion',
        temaNombre: 'Educación',
        temaColor: '#FF9800',
        totalInvertido: 340000.0,
        numeroInversores: 16,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_edu_003',
        nombre: 'Idiomas con IA',
        descripcion: 'App de aprendizaje de idiomas que utiliza IA para crear conversaciones naturales y corregir pronunciación en tiempo real. Soporta 15 idiomas.',
        imagen: null,
        temaId: 'educacion',
        temaNombre: 'Educación',
        temaColor: '#FF9800',
        totalInvertido: 260000.0,
        numeroInversores: 13,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
      ProjectModel(
        id: 'proj_edu_004',
        nombre: 'STEM para Niños',
        descripcion: 'Plataforma educativa gamificada para niños que enseña ciencia, tecnología, ingeniería y matemáticas mediante proyectos prácticos y experimentos virtuales.',
        imagen: null,
        temaId: 'educacion',
        temaNombre: 'Educación',
        temaColor: '#FF9800',
        totalInvertido: 190000.0,
        numeroInversores: 10,
        createdAt: DateTime.now(),
        activo: true,
        orden: 4,
      ),

      // PROYECTOS DE ENERGÍA SOSTENIBLE
      ProjectModel(
        id: 'proj_energy_001',
        nombre: 'Parque Solar Comunitario',
        descripcion: 'Desarrollo de parques solares para abastecer a comunidades rurales con energía renovable. Incluye almacenamiento en baterías y red inteligente.',
        imagen: null,
        temaId: 'energia',
        temaNombre: 'Energía Sostenible',
        temaColor: '#00BCD4',
        totalInvertido: 750000.0,
        numeroInversores: 30,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_energy_002',
        nombre: 'Energía Eólica Offshore',
        descripcion: 'Proyecto de parques eólicos en alta mar con turbinas de última generación. Capacidad para generar electricidad para 50,000 hogares.',
        imagen: null,
        temaId: 'energia',
        temaNombre: 'Energía Sostenible',
        temaColor: '#00BCD4',
        totalInvertido: 1200000.0,
        numeroInversores: 45,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_energy_003',
        nombre: 'Biocombustibles Avanzados',
        descripcion: 'Producción de biocombustibles de segunda generación a partir de residuos agrícolas. Proceso sostenible con huella de carbono negativa.',
        imagen: null,
        temaId: 'energia',
        temaNombre: 'Energía Sostenible',
        temaColor: '#00BCD4',
        totalInvertido: 480000.0,
        numeroInversores: 20,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
      ProjectModel(
        id: 'proj_energy_004',
        nombre: 'Hidrógeno Verde',
        descripcion: 'Planta de producción de hidrógeno verde mediante electrólisis con energía renovable. Abastece a industria del transporte y manufactura.',
        imagen: null,
        temaId: 'energia',
        temaNombre: 'Energía Sostenible',
        temaColor: '#00BCD4',
        totalInvertido: 890000.0,
        numeroInversores: 35,
        createdAt: DateTime.now(),
        activo: true,
        orden: 4,
      ),

      // PROYECTOS DE FINANZAS
      ProjectModel(
        id: 'proj_finance_001',
        nombre: 'Fintech Pagos Internacionales',
        descripcion: 'Plataforma de pagos transfronterizos con comisiones bajas y transferencias instantáneas utilizando blockchain. Enfocada en remesas y comercio B2B.',
        imagen: null,
        temaId: 'finanzas',
        temaNombre: 'Finanzas',
        temaColor: '#9C27B0',
        totalInvertido: 420000.0,
        numeroInversores: 18,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_finance_002',
        nombre: 'Inversión Social',
        descripcion: 'Plataforma de inversión que permite a usuarios invertir en proyectos con impacto social y ambiental. Reportes de ESG en tiempo real.',
        imagen: null,
        temaId: 'finanzas',
        temaNombre: 'Finanzas',
        temaColor: '#9C27B0',
        totalInvertido: 360000.0,
        numeroInversores: 15,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_finance_003',
        nombre: 'Crédito para PYMES',
        descripcion: 'Plataforma de crédito para pequeñas y medianas empresas utilizando análisis alternativo de datos y machine learning para evaluación de riesgo.',
        imagen: null,
        temaId: 'finanzas',
        temaNombre: 'Finanzas',
        temaColor: '#9C27B0',
        totalInvertido: 580000.0,
        numeroInversores: 24,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
      ProjectModel(
        id: 'proj_finance_004',
        nombre: 'Seguros Digitalizados',
        descripcion: 'Aseguradora digital que ofrece pólizas personalizadas con precios dinámicos basados en comportamiento. Proceso 100% digital y sin papeleo.',
        imagen: null,
        temaId: 'finanzas',
        temaNombre: 'Finanzas',
        temaColor: '#9C27B0',
        totalInvertido: 440000.0,
        numeroInversores: 19,
        createdAt: DateTime.now(),
        activo: true,
        orden: 4,
      ),

      // PROYECTOS DE RETAIL
      ProjectModel(
        id: 'proj_retail_001',
        nombre: 'Marketplace Local',
        descripcion: 'Plataforma de e-commerce que conecta productores locales con consumidores. Enfocado en productos artesanales, orgánicos y de comercio justo.',
        imagen: null,
        temaId: 'retail',
        temaNombre: 'Comercio y Retail',
        temaColor: '#E91E63',
        totalInvertido: 280000.0,
        numeroInversores: 12,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_retail_002',
        nombre: 'Tienda Inteligente',
        descripcion: 'Cadena de tiendas con tecnología de reconocimiento de imágenes, pagos automáticos y personalización de ofertas en tiempo real.',
        imagen: null,
        temaId: 'retail',
        temaNombre: 'Comercio y Retail',
        temaColor: '#E91E63',
        totalInvertido: 620000.0,
        numeroInversores: 28,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_retail_003',
        nombre: 'Moda Sostenible',
        descripcion: 'Marca de ropa sostenible con materiales reciclados y producción ética. Modelo de negocio circular con programa de reciclaje de prendas.',
        imagen: null,
        temaId: 'retail',
        temaNombre: 'Comercio y Retail',
        temaColor: '#E91E63',
        totalInvertido: 340000.0,
        numeroInversores: 16,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),

      // PROYECTOS INMOBILIARIOS
      ProjectModel(
        id: 'proj_real_estate_001',
        nombre: 'Vivienda Asequible',
        descripcion: 'Desarrollo de viviendas asequibles con construcción modular y eficiente en energía. Enfocado en clase media emergente.',
        imagen: null,
        temaId: 'inmobiliaria',
        temaNombre: 'Bienes Raíces',
        temaColor: '#795548',
        totalInvertido: 920000.0,
        numeroInversores: 38,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_real_estate_002',
        nombre: 'Coworking Híbrido',
        descripcion: 'Red de espacios de coworking con modelo híbrido físico-virtual. Incluye salas de reuniones VR y servicios para nómadas digitales.',
        imagen: null,
        temaId: 'inmobiliaria',
        temaNombre: 'Bienes Raíces',
        temaColor: '#795548',
        totalInvertido: 560000.0,
        numeroInversores: 22,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_real_estate_003',
        nombre: 'Logística Urbana',
        descripcion: 'Centros de distribución urbanos automatizados para e-commerce de último kilómetro. Reducen tiempos de entrega y tráfico urbano.',
        imagen: null,
        temaId: 'inmobiliaria',
        temaNombre: 'Bienes Raíces',
        temaColor: '#795548',
        totalInvertido: 780000.0,
        numeroInversores: 32,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),

      // PROYECTOS DE TRANSPORTE
      ProjectModel(
        id: 'proj_transport_001',
        nombre: 'Logística Verde',
        descripcion: 'Empresa de logística con flota de vehículos eléctricos y rutas optimizadas por IA. Reducción de 60% en emisiones de CO2.',
        imagen: null,
        temaId: 'transporte',
        temaNombre: 'Transporte y Logística',
        temaColor: '#607D8B',
        totalInvertido: 640000.0,
        numeroInversores: 26,
        createdAt: DateTime.now(),
        activo: true,
        orden: 1,
      ),
      ProjectModel(
        id: 'proj_transport_002',
        nombre: 'Movilidad Compartida',
        descripcion: 'Plataforma de movilidad compartida que integra transporte público, bicicletas eléctricas y scooters en una sola app.',
        imagen: null,
        temaId: 'transporte',
        temaNombre: 'Transporte y Logística',
        temaColor: '#607D8B',
        totalInvertido: 380000.0,
        numeroInversores: 17,
        createdAt: DateTime.now(),
        activo: true,
        orden: 2,
      ),
      ProjectModel(
        id: 'proj_transport_003',
        nombre: 'Drone Delivery',
        descripcion: 'Servicio de entrega por drones para medicamentos y productos urgentes. Enfocado en zonas rurales y de difícil acceso.',
        imagen: null,
        temaId: 'transporte',
        temaNombre: 'Transporte y Logística',
        temaColor: '#607D8B',
        totalInvertido: 460000.0,
        numeroInversores: 20,
        createdAt: DateTime.now(),
        activo: true,
        orden: 3,
      ),
    ];
  }

  /// Get default users data
  List<UserModel> _getDefaultUsers() {
    return [
      // ADMINISTRADOR
      UserModel(
        id: 'user_admin_001',
        nombre: 'Administrador Principal',
        correo: 'admin@amerike.edu',
        username: 'admin',
        password: 'admin123',
        perfil: 'Admin',
        saldo: 0,
        activo: true,
        fechaRegistro: DateTime.parse('2024-01-15T00:00:00.000Z'),
      ),

      // ALUMNOS ($1,000,000 MXN)
      UserModel(
        id: 'user_student_001',
        nombre: 'Juan Pérez García',
        correo: 'juan.perez@alumno.amerike.edu',
        username: 'juan',
        password: '123456',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-10T10:30:00.000Z'),
      ),
      UserModel(
        id: 'user_student_002',
        nombre: 'María López Sánchez',
        correo: 'maria.lopez@alumno.amerike.edu',
        username: 'maria',
        password: '123456',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-12T14:20:00.000Z'),
      ),
      UserModel(
        id: 'user_student_003',
        nombre: 'Carlos Rodríguez Martínez',
        correo: 'carlos.rm@alumno.amerike.edu',
        username: 'carlos',
        password: '123456',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-15T09:45:00.000Z'),
      ),
      // Usuarios adicionales para pruebas fáciles
      UserModel(
        id: 'user_student_004',
        nombre: 'Alumno de Prueba',
        correo: 'alumno1@test.com',
        username: 'alumno1',
        password: 'password',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-20T10:00:00.000Z'),
      ),
      UserModel(
        id: 'user_student_005',
        nombre: 'Alumno de Prueba 2',
        correo: 'alumno2@test.com',
        username: 'alumno2',
        password: 'password',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-21T10:00:00.000Z'),
      ),

      // DOCENTES ($3,000,000 MXN)
      UserModel(
        id: 'user_teacher_001',
        nombre: 'Dra. Ana Martínez Hernández',
        correo: 'ana.martinez@amerike.edu',
        username: 'ana',
        password: '123456',
        perfil: 'Docente',
        saldo: 3000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-01T08:00:00.000Z'),
      ),
      UserModel(
        id: 'user_teacher_002',
        nombre: 'Dr. Roberto González Torres',
        correo: 'roberto.gonzalez@amerike.edu',
        username: 'roberto',
        password: '123456',
        perfil: 'Docente',
        saldo: 3000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-05T10:15:00.000Z'),
      ),
      // Usuarios adicionales para pruebas fáciles
      UserModel(
        id: 'user_teacher_003',
        nombre: 'Docente de Prueba',
        correo: 'docente1@test.com',
        username: 'docente1',
        password: 'password',
        perfil: 'Docente',
        saldo: 4000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-10T10:00:00.000Z'),
      ),
      UserModel(
        id: 'user_teacher_004',
        nombre: 'Docente de Prueba 2',
        correo: 'docente2@test.com',
        username: 'docente2',
        password: 'password',
        perfil: 'Docente',
        saldo: 4000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-11T10:00:00.000Z'),
      ),

      // ADMINISTRATIVOS ($6,000,000 MXN)
      UserModel(
        id: 'user_employee_001',
        nombre: 'Tania Jiménez Narcia',
        correo: 'tjimenez@amerike.edu',
        username: 'tania',
        password: '123456',
        perfil: 'Administrativo',
        saldo: 6000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-01-20T09:00:00.000Z'),
      ),

      // INVERSIONISTAS ($10,000,000 MXN)
      UserModel(
        id: 'user_investor_001',
        nombre: 'Felipe Castillo Moreno',
        correo: 'felipe.castillo@inversor.com',
        username: 'felipe',
        password: '123456',
        perfil: 'Inversionista',
        saldo: 10000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-20T11:30:00.000Z'),
      ),

      // INVITADOS ($2,000,000 MXN)
      UserModel(
        id: 'user_guest_001',
        nombre: 'Sofía Ramírez Vega',
        correo: 'sofia.ramirez@correo.com',
        username: 'sofia',
        password: '123456',
        perfil: 'Invitado',
        saldo: 2000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-04-01T16:45:00.000Z'),
      ),
    ];
  }

  /// Clear all data and reseed
  Future<void> resetDatabase() async {
    _logger.info('Resetting database...');

    await _dbHelper.clearAllData();
    await seedAll();

    _logger.info('Database reset completed');
  }

  /// Asegura que los usuarios de prueba siempre existan
  Future<void> ensureTestUsers() async {
    _logger.info('Ensuring test users exist...');

    final testUsers = _getTestUsers();

    for (final user in testUsers) {
      try {
        final existingUser = await _userDao.getUserByUsername(user.username);
        if (existingUser == null) {
          await _userDao.insertUser(user);
          _logger.info('Added test user: ${user.username}');
        }
      } catch (e) {
        _logger.warning('Error ensuring test user ${user.username}: $e');
      }
    }

    _logger.info('Test users ensured');
  }

  /// Get test users data (usuarios con nombres fáciles de recordar)
  List<UserModel> _getTestUsers() {
    return [
      // Usuarios de prueba para fácil acceso
      UserModel(
        id: 'user_student_004',
        nombre: 'Alumno de Prueba',
        correo: 'alumno1@test.com',
        username: 'alumno1',
        password: 'password',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-20T10:00:00.000Z'),
      ),
      UserModel(
        id: 'user_student_005',
        nombre: 'Alumno de Prueba 2',
        correo: 'alumno2@test.com',
        username: 'alumno2',
        password: 'password',
        perfil: 'Alumno',
        saldo: 1000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-03-21T10:00:00.000Z'),
      ),
      UserModel(
        id: 'user_teacher_003',
        nombre: 'Docente de Prueba',
        correo: 'docente1@test.com',
        username: 'docente1',
        password: 'password',
        perfil: 'Docente',
        saldo: 4000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-10T10:00:00.000Z'),
      ),
      UserModel(
        id: 'user_teacher_004',
        nombre: 'Docente de Prueba 2',
        correo: 'docente2@test.com',
        username: 'docente2',
        password: 'password',
        perfil: 'Docente',
        saldo: 4000000,
        activo: true,
        fechaRegistro: DateTime.parse('2024-02-11T10:00:00.000Z'),
      ),
    ];
  }

  /// Diagnose database issues
  Future<Map<String, dynamic>> diagnose() async {
    _logger.info('Running database diagnosis...');

    try {
      final db = await _dbHelper.database;

      // Check if tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      // Count records in each table
      final counts = <String, int>{};
      for (final table in tableNames) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          counts[table] = Sqflite.firstIntValue(result) ?? 0;
        } catch (e) {
          counts[table] = -1; // Error counting
        }
      }

      // Test user authentication
      UserModel? testUser;
      try {
        testUser = await _userDao.authenticate('juan', '123456');
      } catch (e) {
        _logger.warning('Test authentication failed: $e');
      }

      return {
        'tables': tableNames,
        'recordCounts': counts,
        'testUserFound': testUser != null,
        'testUserActive': testUser?.activo,
        'seedingNeeded': await needsSeeding(),
      };
    } catch (e) {
      _logger.severe('Diagnosis failed: $e');
      rethrow;
    }
  }
}