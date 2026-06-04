import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/timer_badge.dart';
import '../../widgets/menu/menu_widgets.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleInvest() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    final user = authState.value;

    if (user == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;

    // Validar estado de la sesión
    final session = ref.read(sessionProvider).value;
    if (session?.estado != SessionState.active) {
      String errorMessage;
      switch (session?.estado) {
        case SessionState.ended:
          errorMessage = 'La ronda de inversión ha finalizado. No se permiten nuevas inversiones.';
          break;
        case SessionState.paused:
          errorMessage = 'La ronda está pausada temporalmente. Intente más tarde.';
          break;
        case SessionState.waiting:
          errorMessage = 'La ronda aún no ha comenzado. Espere a que el administrador la inicie.';
          break;
        default:
          errorMessage = 'No se pueden realizar inversiones en este momento.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      final investUseCase = ref.read(investUseCaseProvider);
      await investUseCase(
        userId: user.id,
        projectId: widget.projectId,
        amount: amount,
        sessionState: session?.estado,
      );

      // Actualizar el saldo del usuario
      final newBalance = user.saldo - amount;
      ref.read(authProvider.notifier).updateBalance(newBalance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.investmentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        _amountController.clear();
        Navigator.of(context).pop();
        ref.invalidate(projectDetailProvider(widget.projectId));
        ref.invalidate(investmentsProvider(user.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectDetailProvider(widget.projectId));
    final authState = ref.watch(authProvider);
    final session = ref.watch(sessionProvider);
    final user = authState.value;

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Volver',
              ),
              const HamburgerMenuButton(),
            ],
          ),
          title: const Text(AppStrings.projectDetails),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: projectState.when(
          data: (project) {
            if (project == null) {
              return const Center(
                child: Text(AppStrings.noData),
              );
            }
            return _buildContent(project, user, session);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.error,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(projectDetailProvider(widget.projectId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Project project, User? user, AsyncValue<Session> session) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Project Image with Gradient Overlay
        SliverToBoxAdapter(
          child: _buildProjectImage(project),
        ),

        // Timer Badge - shows session timer if active
        if (session.value != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TimerBadge(session: session.value!),
              ),
            ),
          ),

        // Project Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Category
                _buildTitleSection(project),

                const SizedBox(height: 24),

                // Stats
                _buildStatsSection(project),

                const SizedBox(height: 24),

                // Participants
                _buildParticipantsSection(project),

                const SizedBox(height: 24),

                // Description
                _buildDescriptionSection(project),

                const SizedBox(height: 24),

                // Investment Form
                if (user != null && project.activo)
                  _buildInvestmentSection(project, user, session),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectImage(Project project) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: project.imagen != null && project.imagen!.isNotEmpty
              ? Image.network(
                  project.imagen!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(project),
                )
              : _buildPlaceholder(project),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.primaryBackground.withValues(alpha: 0.9),
                  AppColors.primaryBackground,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Project project) {
    final baseColor = _parseColor(project.temaColor ?? '#00D4AA');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.business,
          size: 80,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _parseColor(project.temaColor ?? '#00D4AA').withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _parseColor(project.temaColor ?? '#00D4AA').withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category,
                size: 14,
                color: _parseColor(project.temaColor ?? '#00D4AA'),
              ),
              const SizedBox(width: 6),
              Text(
                project.temaNombre,
                style: TextStyle(
                  color: _parseColor(project.temaColor ?? '#00D4AA'),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          project.nombre,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: project.activo
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            project.activo ? AppStrings.active : AppStrings.inactive,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: project.activo ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(Project project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.account_balance_wallet,
            label: AppStrings.totalInvested,
            value: Formatters.formatCompactNumber(project.totalInvertido),
            color: AppColors.primaryAccent,
          ),
          _buildStatItem(
            icon: Icons.people,
            label: 'Inversores',
            value: project.numeroInversores.toString(),
            color: AppColors.secondaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(Project project) {
    // Mock participants - in real app, this would come from project.participants
    final participants = [
      {'name': 'Juan Pérez', 'role': 'Líder del Equipo'},
      {'name': 'María García', 'role': 'Co-fundadora'},
      {'name': 'Carlos López', 'role': 'Desarrollador'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participantes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return Padding(
                padding: EdgeInsets.only(right: index < participants.length - 1 ? 16 : 0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _parseColor(project.temaColor ?? '#00D4AA').withValues(alpha: 0.2),
                      child: Text(
                        participant['name']!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: _parseColor(project.temaColor ?? '#00D4AA'),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        participant['name']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Project project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.projectDescription,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          project.descripcion,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Additional Information Sections
        _buildInfoCard(
          title: 'Pitch',
          icon: Icons.lightbulb_outline,
          content:
              'Proyecto innovador que busca transformar la industria a través de soluciones tecnológicas de vanguardia.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Problema',
          icon: Icons.error_outline,
          content:
              'La falta de herramientas eficientes en el mercado actual limita el crecimiento de las empresas.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Solución',
          icon: Icons.check_circle_outline,
          content:
              'Nuestra plataforma proporciona una solución integral que optimiza procesos y mejora la productividad.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Estrategia de Ingresos',
          icon: Icons.trending_up,
          content:
              'Modelo SaaS con suscripciones mensuales y anuales, además de servicios premium personalizados.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Proyección Financiera',
          icon: Icons.show_chart,
          content:
              'Crecimiento esperado del 150% en el primer año, con retorno de inversión proyectado en 18 meses.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentSection(Project project, User user, AsyncValue<Session> session) {
    // Determinar el estado de la sesión y el mensaje correspondiente
    final sessionData = session.value;
    final isBlocked = sessionData?.estado != SessionState.active;

    String? blockedMessage;
    Color? blockedColor;
    IconData? blockedIcon;

    if (isBlocked && sessionData != null) {
      switch (sessionData.estado) {
        case SessionState.ended:
          blockedMessage = 'La ronda de inversión ha finalizado. No se permiten nuevas inversiones.';
          blockedColor = AppColors.error;
          blockedIcon = Icons.timer_off;
          break;
        case SessionState.paused:
          blockedMessage = 'La ronda está pausada temporalmente. Intente más tarde.';
          blockedColor = AppColors.warning;
          blockedIcon = Icons.pause;
          break;
        case SessionState.waiting:
          blockedMessage = 'La ronda aún no ha comenzado. Espere a que el administrador la inicie.';
          blockedColor = AppColors.info;
          blockedIcon = Icons.schedule;
          break;
        case SessionState.active:
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.1),
            AppColors.secondaryAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blocked Message Section
            if (isBlocked && blockedMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blockedColor?.withValues(alpha: 0.1) ?? AppColors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: blockedColor ?? AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      blockedIcon ?? Icons.block,
                      color: blockedColor ?? AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        blockedMessage,
                        style: TextStyle(
                          color: blockedColor ?? AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Balance Info
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Saldo disponible: ${Formatters.formatCurrency(user.saldo)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppInput(
              label: AppStrings.investmentAmount,
              hint: 'Ingresa el monto a invertir',
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              enabled: !isBlocked,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.required;
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return AppStrings.invalidAmount;
                }
                if (amount > user.saldo) {
                  return AppStrings.insufficientFunds;
                }
                if (amount < ApiConstants.minimumInvestment) {
                  return '${AppStrings.minimumInvestment}: \$${ApiConstants.minimumInvestment}';
                }
                if (amount > ApiConstants.maximumInvestment) {
                  return '${AppStrings.maximumInvestment}: \$${ApiConstants.maximumInvestment}';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '${AppStrings.minimumInvestment}: \$${ApiConstants.minimumInvestment} | ${AppStrings.maximumInvestment}: \$${ApiConstants.maximumInvestment}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: AppStrings.invest,
              onPressed: isBlocked ? null : _handleInvest,
              isFullWidth: true,
              icon: Icons.add_circle_outline,
              variant: isBlocked
                  ? AppButtonVariant.outlined
                  : AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }
}
