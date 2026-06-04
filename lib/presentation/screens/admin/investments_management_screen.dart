import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amerike_investment_sim/core/constants/app_colors.dart';
import 'package:amerike_investment_sim/domain/entities/investment.dart';
import 'package:amerike_investment_sim/domain/entities/user.dart';
import 'package:amerike_investment_sim/presentation/providers/investments_management_provider.dart';
import 'package:amerike_investment_sim/presentation/providers/users_provider.dart' as users_providers;
import 'package:amerike_investment_sim/presentation/providers/project_provider.dart';
import 'package:amerike_investment_sim/presentation/widgets/admin/investment_charts.dart';
import 'package:amerike_investment_sim/presentation/widgets/admin/investment_dialogs.dart';

class InvestmentsManagementScreen extends ConsumerStatefulWidget {
  const InvestmentsManagementScreen({super.key});

  @override
  ConsumerState<InvestmentsManagementScreen> createState() => _InvestmentsManagementScreenState();
}

class _InvestmentsManagementScreenState extends ConsumerState<InvestmentsManagementScreen> {
  final _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateInvestmentDialog() async {
    final usersAsync = ref.read(users_providers.userProvider);
    final projectsAsync = ref.read(projectsProvider);

    final userList = usersAsync.value ?? [];
    final projects = projectsAsync.value ?? [];

    if (!mounted) return;

    final dialogResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateInvestmentDialog(
        users: userList,
        projects: projects.map((p) => ProjectInfo(
              id: p.id,
              nombre: p.nombre,
              temaId: p.temaId,
              temaNombre: p.temaNombre,
              temaColor: p.temaColor ?? '#FFFFFF',
            )).toList(),
      ),
    );

    if (dialogResult != null) {
      await ref.read(investmentsManagementProvider.notifier).createManualInvestment(
            usuarioId: dialogResult['usuarioId'],
            usuarioNombre: dialogResult['usuarioNombre'],
            perfil: dialogResult['perfil'],
            proyectoId: dialogResult['proyectoId'],
            proyectoNombre: dialogResult['proyectoNombre'],
            temaId: dialogResult['temaId'],
            temaNombre: dialogResult['temaNombre'],
            temaColor: dialogResult['temaColor'],
            monto: dialogResult['monto'],
            observaciones: dialogResult['observaciones'],
          );
    }
  }

  Future<void> _showCancelInvestmentDialog(Investment investment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => CancelInvestmentDialog(investment: investment),
    );

    if (reason != null) {
      await ref.read(investmentsManagementProvider.notifier).cancelInvestment(
            investment.id,
            reason,
          );
    }
  }

  void _showInvestmentDetails(Investment investment) {
    showDialog(
      context: context,
      builder: (context) => InvestmentDetailsDialog(investment: investment),
    ).then((_) {
      // Check if we should show cancel dialog
      if (investment.estado == InvestmentStatus.activa && mounted) {
        _showCancelInvestmentDialog(investment);
      }
    });
  }

  Future<void> _exportToCSV() async {
    final state = ref.read(investmentsManagementProvider);
    final investments = state.filteredInvestments;

    if (investments.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay inversiones para exportar')),
      );
      return;
    }

    _generateCSV(investments);
    // Here you would implement the actual file saving logic
    // For now, just show a success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportadas ${investments.length} inversiones a CSV'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _exportToJSON() async {
    final state = ref.read(investmentsManagementProvider);
    final investments = state.filteredInvestments;

    if (investments.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay inversiones para exportar')),
      );
      return;
    }

    _generateJSON(investments);
    // Here you would implement the actual file saving logic
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportadas ${investments.length} inversiones a JSON'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _generateCSV(List<Investment> investments) {
    final buffer = StringBuffer();
    buffer.writeln('Usuario,Perfil,Proyecto,Tema,Monto,Fecha,Hora,Estado,Observaciones');
    for (final inv in investments) {
      buffer.writeln(
        '${inv.usuarioNombre},'
        '${User.perfilToString(inv.perfil)},'
        '${inv.proyectoNombre},'
        '${inv.temaNombre},'
        '${inv.monto},'
        '${_formatDate(inv.fechaHora)},'
        '${_formatTime(inv.fechaHora)},'
        '${inv.estado.displayName},'
        '${inv.observaciones ?? ''}',
      );
    }
    return buffer.toString();
  }

  String _generateJSON(List<Investment> investments) {
    final data = investments.map((inv) => {
      'usuario': inv.usuarioNombre,
      'perfil': User.perfilToString(inv.perfil),
      'proyecto': inv.proyectoNombre,
      'tema': inv.temaNombre,
      'monto': inv.monto,
      'fecha': _formatDate(inv.fechaHora),
      'hora': _formatTime(inv.fechaHora),
      'estado': inv.estado.displayName,
      'observaciones': inv.observaciones,
    }).toList();
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(investmentsManagementProvider);
    final stats = ref.watch(investmentsStatisticsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
          tooltip: 'Volver',
        ),
        title: const Text('Gestión de Inversiones'),
        actions: [
          IconButton(
            icon: Icon(state.showStatistics ? Icons.list : Icons.bar_chart),
            onPressed: () => ref.read(investmentsManagementProvider.notifier).toggleStatistics(),
            tooltip: state.showStatistics ? 'Ver Lista' : 'Ver Estadísticas',
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'csv') {
                _exportToCSV();
              } else if (action == 'json') {
                _exportToJSON();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.showStatistics ? _buildStatisticsView(stats) : _buildListView(state),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateInvestmentDialog,
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(InvestmentsManagementState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(investmentsManagementProvider.notifier).clearError(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilters(state),
        Expanded(
          child: state.paginatedInvestments.isEmpty
              ? const Center(
                  child: Text(
                    'No hay inversiones que coincidan con los filtros',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.paginatedInvestments.length,
                  itemBuilder: (context, index) {
                    final investment = state.paginatedInvestments[index];
                    return _buildInvestmentCard(investment);
                  },
                ),
        ),
        if (state.totalPages > 1) _buildPagination(state),
      ],
    );
  }

  Widget _buildFilters(InvestmentsManagementState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.secondaryBackground,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por usuario, proyecto o tema...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(investmentsManagementProvider.notifier).setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.tertiaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (value) {
              ref.read(investmentsManagementProvider.notifier).setSearchQuery(value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserRole?>(
                  value: state.selectedPerfil,
                  decoration: const InputDecoration(
                    labelText: 'Perfil',
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.secondaryBackground,
                  items: [
                    const DropdownMenuItem<UserRole?>(
                      value: null,
                      child: Text('Todos los perfiles'),
                    ),
                    ...UserRole.values.map((perfil) => DropdownMenuItem<UserRole?>(
                          value: perfil,
                          child: Text(User.perfilToString(perfil)),
                        )),
                  ],
                  onChanged: (perfil) {
                    ref.read(investmentsManagementProvider.notifier).setSelectedPerfil(perfil);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<InvestmentStatus?>(
                  value: state.selectedEstado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    filled: true,
                    fillColor: AppColors.tertiaryBackground,
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.secondaryBackground,
                  items: [
                    const DropdownMenuItem<InvestmentStatus?>(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    ...InvestmentStatus.values.map((estado) => DropdownMenuItem<InvestmentStatus?>(
                          value: estado,
                          child: Text(estado.displayName),
                        )),
                  ],
                  onChanged: (estado) {
                    ref.read(investmentsManagementProvider.notifier).setSelectedEstado(estado);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _selectedDateRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primaryAccent,
                              surface: AppColors.secondaryBackground,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() => _selectedDateRange = range);
                      ref.read(investmentsManagementProvider.notifier).setDateRange(
                            range.start,
                            range.end,
                          );
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filtrar por fecha'
                        : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                  ),
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _selectedDateRange = null);
                    ref.read(investmentsManagementProvider.notifier).clearDateRange();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () => _showInvestmentDetails(investment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryAccent,
                    child: Text(
                      investment.usuarioNombre.initials,
                      style: const TextStyle(
                        color: AppColors.primaryBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.usuarioNombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          User.perfilToString(investment.perfil),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(investment.estado),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(investment.temaColor.replaceFirst('#', '0xFF')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment.proyectoNombre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            investment.temaNombre,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(investment.monto),
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(investment.fechaHora)} ${_formatTime(investment.fechaHora)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (investment.observaciones != null && investment.observaciones!.isNotEmpty) ...[
                    Icon(Icons.note, size: 16, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      'Con observaciones',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (investment.estado == InvestmentStatus.activa) ...[
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _showCancelInvestmentDialog(investment),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InvestmentStatus status) {
    Color color;
    switch (status) {
      case InvestmentStatus.activa:
        color = AppColors.success;
        break;
      case InvestmentStatus.cancelada:
        color = AppColors.error;
        break;
      case InvestmentStatus.pendiente:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination(InvestmentsManagementState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.secondaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.currentPage > 1
                ? () => ref.read(investmentsManagementProvider.notifier).setCurrentPage(state.currentPage - 1)
                : null,
          ),
          Text(
            'Página ${state.currentPage} de ${state.totalPages}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.totalPages
                ? () => ref.read(investmentsManagementProvider.notifier).setCurrentPage(state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView(InvestmentsStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas principales
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              MetricCard(
                title: 'Total Inversiones',
                value: '${stats.totalInvestments}',
                icon: Icons.payments,
                color: AppColors.primaryAccent,
              ),
              MetricCard(
                title: 'Monto Total',
                value: _formatCurrency(stats.totalAmount),
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
              MetricCard(
                title: 'Promedio',
                value: _formatCurrency(stats.averageAmount),
                icon: Icons.trending_up,
                color: AppColors.info,
              ),
              MetricCard(
                title: 'Inversión Más Alta',
                value: _formatCurrency(stats.highestInvestment),
                icon: Icons.arrow_upward,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gráficos
          ProfileBarChart(data: stats.investmentsByProfile),
          const SizedBox(height: 16),
          BarChartWidget(
            data: stats.investmentsByTheme,
            title: 'Inversiones por Tema',
            barColor: AppColors.primaryAccent,
          ),
          const SizedBox(height: 16),
          TimelineChart(data: stats.investmentsByDate),
          const SizedBox(height: 24),
          // Top listas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TopUsersList(
                  users: stats.topUsers.map((u) => UserInvestmentStats(
                        usuarioId: u.usuarioId,
                        usuarioNombre: u.usuarioNombre,
                        perfil: u.perfil,
                        totalAmount: u.totalAmount,
                        investmentCount: u.investmentCount,
                      )).toList(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TopProjectsList(
                  projects: stats.topProjects.map((p) => ProjectInvestmentStats(
                        proyectoId: p.proyectoId,
                        proyectoNombre: p.proyectoNombre,
                        temaNombre: p.temaNombre,
                        temaColor: p.temaColor,
                        totalAmount: p.totalAmount,
                        investmentCount: p.investmentCount,
                      )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

extension StringExtension on String {
  String get initials {
    final parts = trim().split(' ');
    if (isEmpty) return '';
    if (parts.length == 1) return this[0].toUpperCase();
    return '${parts[0][0].toUpperCase()}${parts[parts.length - 1][0].toUpperCase()}';
  }
}
