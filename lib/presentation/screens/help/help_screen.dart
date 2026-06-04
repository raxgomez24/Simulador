import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedSections = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSection(String sectionId) {
    setState(() {
      if (_expandedSections.contains(sectionId)) {
        _expandedSections.remove(sectionId);
      } else {
        _expandedSections.add(sectionId);
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isNotEmpty) {
        // Expand all sections when searching
        _expandedSections.addAll(_getAllSectionIds());
      }
    });
  }

  List<String> _getAllSectionIds() {
    return [
      'welcome',
      'how_to_start',
      'how_to_invest',
      'understanding_balance',
      'viewing_ranking',
      'admin_panel',
      'navigation',
      'faq',
      'support',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Ayuda e Instrucciones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_getResponsivePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_shouldShowSection('bienvenida')) _buildWelcomeSection(context),
                  if (_shouldShowSection('empezar')) ...[
                    const SizedBox(height: 24),
                    _buildHowToStartSection(context),
                  ],
                  if (_shouldShowSection('invertir')) ...[
                    const SizedBox(height: 24),
                    _buildHowToInvestSection(context),
                  ],
                  if (_shouldShowSection('saldo')) ...[
                    const SizedBox(height: 24),
                    _buildUnderstandingBalanceSection(context),
                  ],
                  if (_shouldShowSection('ranking')) ...[
                    const SizedBox(height: 24),
                    _buildViewingRankingSection(context),
                  ],
                  if (_shouldShowSection('admin') && isAdmin) ...[
                    const SizedBox(height: 24),
                    _buildAdminPanelSection(context),
                  ],
                  if (_shouldShowSection('navegacion')) ...[
                    const SizedBox(height: 24),
                    _buildNavigationSection(context),
                  ],
                  if (_shouldShowSection('faq')) ...[
                    const SizedBox(height: 24),
                    _buildFAQSection(context),
                  ],
                  if (_shouldShowSection('soporte')) ...[
                    const SizedBox(height: 24),
                    _buildSupportSection(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar en ayuda...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardBackground,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.primaryAccent),
          ),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  bool _shouldShowSection(String keyword) {
    if (_searchQuery.isEmpty) return true;
    return _searchKeywords().any((k) => k.contains(_searchQuery));
  }

  List<String> _searchKeywords() {
    return [
      'bienvenida', 'empezar', 'invertir', 'saldo', 'ranking', 'admin',
      'navegacion', 'faq', 'soporte', 'sesión', 'proyecto', 'inversión',
      'temporizador', 'organizador', 'problema', 'contacto',
    ];
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 48.0;
    if (width > 800) return 32.0;
    return 16.0;
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'welcome',
      title: 'Bienvenida',
      icon: Icons.waving_hand,
      children: [
        Text(
          'Bienvenido a Amerike MBA 2026 - Sistema de Simulación de Inversiones',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Esta aplicación te permite simular inversiones en proyectos reales, '
          'tomar decisiones estratégicas y competir con otros participantes.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildHowToStartSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'how_to_start',
      title: 'Cómo Empezar',
      icon: Icons.play_circle_outline,
      children: [
        _buildStep(
          context,
          stepNumber: 1,
          title: 'Iniciar Sesión o Registrarse',
          description: 'Accede con tu cuenta o regístrate como invitado para comenzar. '
              'Los usuarios invitados reciben un saldo inicial de \$5,000,000.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 2,
          title: 'Consultar tu Saldo',
          description: 'Verifica tu saldo disponible en la pantalla de inicio. '
              'El saldo se muestra en la parte superior de la pantalla.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 3,
          title: 'Explorar Proyectos',
          description: 'Navega por las diferentes categorías y proyectos disponibles. '
              'Cada proyecto tiene información detallada sobre la inversión.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 4,
          title: 'Esperar la Ronda',
          description: 'Espera a que el administrador inicie la ronda de inversión. '
              'Verás un temporizador cuando la ronda esté activa.',
        ),
      ],
    );
  }

  Widget _buildHowToInvestSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'how_to_invest',
      title: 'Cómo Invertir',
      icon: Icons.trending_up,
      children: [
        _buildStep(
          context,
          stepNumber: 1,
          title: 'Seleccionar un Proyecto',
          description: 'Toca en cualquier tarjeta de proyecto para ver los detalles. '
              'Revisa el monto invertido, número de inversores y descripción.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 2,
          title: 'Ingresar Monto',
          description: 'En la pantalla del proyecto, ingresa el monto que deseas invertir. '
              'El sistema validará que tengas saldo suficiente.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 3,
          title: 'Confirmar Inversión',
          description: 'Toca el botón "Invertir" y confirma la operación. '
              'Recibirás una confirmación cuando la inversión se registre.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 4,
          title: 'Verificar Actualizaciones',
          description: 'Tu saldo se actualizará automáticamente. '
              'El ranking de proyectos se actualizará en tiempo real.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 5,
          title: 'Invertir en Múltiples Proyectos',
          description: 'Puedes distribuir tu saldo entre varios proyectos '
              'según tu estrategia de inversión.',
        ),
      ],
    );
  }

  Widget _buildUnderstandingBalanceSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'understanding_balance',
      title: 'Entendiendo tu Saldo',
      icon: Icons.account_balance_wallet,
      children: [
        _buildInfoItem(
          context,
          icon: Icons.card_giftcard,
          title: 'Monto Inicial por Perfil',
          description: 'Docente: \$4M | Administrativo: \$6M | Inversionista: \$10M | '
              'Invitado: \$2M | Alumno: \$1M',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.info_outline,
          title: '¿Qué es el Saldo?',
          description: 'Es el monto virtual disponible para invertir en proyectos. '
              'No representa dinero real.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.refresh,
          title: 'Actualización Automática',
          description: 'Tu saldo se reduce automáticamente cuando haces una inversión. '
              'La actualización es inmediata.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.block,
          title: 'Límite de Inversión',
          description: 'No puedes invertir más del saldo disponible. '
              'El sistema validará cada operación.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.error_outline,
          title: '¿Qué pasa si me quedo sin saldo?',
          description: 'No podrás realizar más inversiones. Contacta al administrador '
              'para solicitar un reinicio de saldo.',
        ),
      ],
    );
  }

  Widget _buildViewingRankingSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'viewing_ranking',
      title: 'Ver el Ranking',
      icon: Icons.emoji_events,
      children: [
        _buildStep(
          context,
          stepNumber: 1,
          title: 'Acceder al Ranking',
          description: 'Toca el icono de "Ranking" en la barra de navegación inferior '
              'para ver proyectos ordenados por monto invertido.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 2,
          title: 'Interpretar el Ranking',
          description: 'Los proyectos están ordenados de mayor a menor inversión. '
              'Las primeras 3 posiciones tienen medallas de oro, plata y bronce.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 3,
          title: 'Filtrar por Categoría',
          description: 'Usa los filtros para ver proyectos por tema específico. '
              'Toca en cualquier categoría para filtrar la lista.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 4,
          title: 'Actualización en Tiempo Real',
          description: 'El ranking se actualiza automáticamente cuando alguien '
              'hace una inversión. No necesitas recargar la página.',
        ),
      ],
    );
  }

  Widget _buildAdminPanelSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'admin_panel',
      title: 'Panel de Administración',
      icon: Icons.admin_panel_settings,
      children: [
        _buildStep(
          context,
          stepNumber: 1,
          title: 'Acceder al Panel Admin',
          description: 'Como administrador, tienes acceso a funciones especiales '
              'desde el menú lateral.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 2,
          title: 'Controlar el Temporizador',
          description: 'Puedes iniciar, pausar, terminar o reiniciar la ronda. '
              'Ajusta la duración en minutos según sea necesario.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 3,
          title: 'Gestionar Usuarios',
          description: 'Crea, edita o desactiva usuarios. Verifica el indicador '
              'de límite de 100 usuarios.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 4,
          title: 'Exportar Reportes',
          description: 'Exporta datos de inversiones, proyectos, usuarios y ranking '
              'en formato CSV para análisis.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          context,
          stepNumber: 5,
          title: 'Ver Estadísticas',
          description: 'Consulta métricas globales, gráficas de distribución y '
              'tendencias de inversión.',
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'navigation',
      title: 'Navegación',
      icon: Icons.explore,
      children: [
        _buildInfoItem(
          context,
          icon: Icons.home,
          title: 'Inicio',
          description: 'Pantalla principal con tu saldo, estadísticas y acceso rápido.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.business_center,
          title: 'Proyectos',
          description: 'Lista de todos los proyectos disponibles para invertir.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.receipt_long,
          title: 'Mis Inversiones',
          description: 'Historial completo de tus inversiones realizadas.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.emoji_events,
          title: 'Ranking',
          description: 'Proyectos ordenados por monto invertido en tiempo real.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.person,
          title: 'Perfil',
          description: 'Tu información personal y configuración de cuenta.',
        ),
      ],
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'faq',
      title: 'Preguntas Frecuentes',
      icon: Icons.question_answer,
      children: [
        _buildFAQItem(
          context,
          question: '¿Qué pasa si me quedo sin saldo?',
          answer: 'No podrás realizar más inversiones. El sistema mostrará un mensaje '
              'indicando que no tienes saldo suficiente. Contacta al administrador.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Puedo invertir en varios proyectos?',
          answer: 'Sí, puedes distribuir tu saldo entre múltiples proyectos según tu '
              'estrategia. Solo debes asegurarte de tener saldo suficiente.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Puedo cancelar una inversión?',
          answer: 'Depende de las reglas de la ronda actual. Generalmente, '
              'las inversiones son irrevocables una vez confirmadas.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Qué muestra el temporizador?',
          answer: 'El temporizador muestra el tiempo restante en la ronda de inversión '
              'actual. Cuando llega a 0, la ronda termina y no se permiten más inversiones.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Cómo se actualiza el ranking?',
          answer: 'El ranking se actualiza automáticamente en tiempo real cuando '
              'cualquier usuario hace una inversión. No necesitas recargar.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Qué significan las medallas en el ranking?',
          answer: '🥇 Oro: 1er lugar | 🥈 Plata: 2do lugar | 🥉 Bronce: 3er lugar. '
              'Indican los proyectos con mayor inversión.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Puedo ver mis inversiones anteriores?',
          answer: 'Sí, ve a la sección "Mis Inversiones" para ver el historial completo '
              'de todas tus inversiones realizadas.',
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          context,
          question: '¿Hay límite de usuarios en el sistema?',
          answer: 'Sí, el sistema tiene un límite de 100 usuarios. Si se alcanza '
              'este límite, no se permitirán nuevos registros.',
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildExpandableSectionCard(
      context,
      sectionId: 'support',
      title: 'Soporte y Contacto',
      icon: Icons.support_agent,
      children: [
        _buildInfoItem(
          context,
          icon: Icons.contact_phone,
          title: 'Contactar al Organizador',
          description: 'Comunícate con el organizador del evento para cualquier consulta '
              'sobre la simulación.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.report_problem,
          title: 'Reportar Problemas',
          description: 'Si experimentas dificultades técnicas, errores o comportamiento '
              'inesperado, reporta el problema inmediatamente.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          icon: Icons.info_outline,
          title: 'Más Información',
          description: 'Para obtener detalles adicionales sobre las reglas, '
              'mecánicas o objetivos de la simulación, consulta con el organizador.',
        ),
      ],
    );
  }

  Widget _buildExpandableSectionCard(
    BuildContext context, {
    required String sectionId,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isExpanded = _expandedSections.contains(sectionId) || _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => _toggleSection(sectionId),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primaryAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: AppColors.primaryBackground,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.secondaryAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline,
                color: AppColors.primaryAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
