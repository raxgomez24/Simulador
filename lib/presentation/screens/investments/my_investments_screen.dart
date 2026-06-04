import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/investment_repository_local.dart';
import '../../../domain/entities/investment.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/menu/menu_widgets.dart';
import '../../../app/config.dart';

String _getRoleName(UserRole perfil) {
  switch (perfil) {
    case UserRole.admin:
      return 'Administrador';
    case UserRole.student:
      return 'Estudiante';
    case UserRole.guest:
      return 'Invitado';
    case UserRole.teacher:
      return 'Docente';
    case UserRole.employee:
      return 'Administrativo';
    case UserRole.investor:
      return 'Inversionista';
  }
}

class MyInvestmentsScreen extends ConsumerStatefulWidget {
  const MyInvestmentsScreen({super.key});

  @override
  ConsumerState<MyInvestmentsScreen> createState() => _MyInvestmentsScreenState();
}

class _MyInvestmentsScreenState extends ConsumerState<MyInvestmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvestments();
    });
  }

  void _loadInvestments() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      ref.invalidate(investmentsProvider(user.id));
    }
  }

  Future<void> _editInvestment(Investment investment) async {
    final amountController = TextEditingController(text: investment.monto.toStringAsFixed(2));

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text(AppStrings.editInvestmentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.projectInvested}: ${investment.proyectoNombre}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '${AppStrings.currentAmount}: ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(investment.monto),
                  style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: AppStrings.newAmount,
                hintText: '0.00',
                prefixText: '\$ ',
                filled: true,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo disponible: ${Formatters.formatCurrency(ref.read(authProvider).value?.saldo ?? 0)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount > 0) {
                Navigator.of(context).pop(newAmount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.invalidAmount),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
            child: const Text(AppStrings.updateInvestment),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final newAmount = result;
        final user = ref.read(authProvider).value;

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario no encontrado'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Calcular la diferencia
        final difference = newAmount - investment.monto;
        final newBalance = user.saldo - difference;

        // Validar que el usuario tenga suficiente saldo
        if (difference > 0 && newBalance < 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.insufficientFunds),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Actualizar el saldo del usuario
        ref.read(authProvider.notifier).updateBalance(newBalance);

        // Actualizar la inversión en el repositorio local
        if (AppConfig.useLocalData) {
          final repository = ref.read(investmentRepositoryProvider) as InvestmentRepositoryLocal;
          // Eliminar la inversión anterior
          await repository.cancelInvestment(investment.id);
          // Crear la nueva inversión con el mismo ID usando copyWith
          final newInvestment = investment.copyWith(
            monto: newAmount,
          );

          // Agregar la inversión actualizada usando el método estático
          InvestmentRepositoryLocal.addInvestment(newInvestment);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.investmentUpdated),
                backgroundColor: AppColors.success,
              ),
            );
            _loadInvestments();
          }
        } else {
          // En modo WebSocket, enviaríamos un mensaje al servidor
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edición vía WebSocket no implementada aún'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.investmentUpdateError}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelInvestment(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text(AppStrings.cancelInvestment),
        content: const Text(AppStrings.cancelInvestmentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.confirm,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Cancelar la inversión en el repositorio
        final repository = ref.read(investmentRepositoryProvider);
        if (repository is InvestmentRepositoryLocal) {
          await repository.cancelInvestment(investment.id);

          // Actualizar el saldo del usuario
          final user = ref.read(authProvider).value;
          if (user != null) {
            final newBalance = user.saldo + investment.monto;
            ref.read(authProvider.notifier).updateBalance(newBalance);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.investmentCancelled),
                backgroundColor: AppColors.success,
              ),
            );
            _loadInvestments();
          }
        } else {
          // En modo WebSocket, enviaríamos un mensaje al servidor
          // Por ahora, mostramos un mensaje de que no está implementado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cancelación vía WebSocket no implementada aún'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.investmentCancelledError}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userValue = user.value;
    final AsyncValue<List<Investment>> investmentsAsync = userValue != null
        ? ref.watch(investmentsProvider(userValue.id))
        : const AsyncValue.data(<Investment>[]);

    return HamburgerMenuDrawer(
      child: Scaffold(
        appBar: AppBar(
          leading: const HamburgerMenuButton(),
          title: const Text(AppStrings.myInvestments),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      body: investmentsAsync.when(
        data: (List<Investment> investments) {
          final totalInvested = investments.fold<double>(
            0.0,
            (sum, inv) => sum + inv.monto,
          );

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(totalInvested, investments.length, userValue),

              // Investments List
              Expanded(
                child: investments.isEmpty
                    ? _buildEmptyState()
                    : _buildInvestmentsList(investments),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }

  Widget _buildSummaryCard(double totalInvested, int count, User? user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent,
            AppColors.secondaryAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  user?.initials ?? '??',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombre ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user != null ? _getRoleName(user.perfil) : 'Invitado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: AppStrings.totalInvestedByMe,
                  value: Formatters.formatCurrency(totalInvested),
                  icon: Icons.account_balance_wallet,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  label: AppStrings.numberOfInvestments,
                  value: count.toString(),
                  icon: Icons.bar_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInvestmentsList(List<Investment> investments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: investments.length,
      itemBuilder: (context, index) {
        final investment = investments[index];
        return _buildInvestmentCard(investment);
      },
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormatter.format(investment.fechaHora);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedAlignment: Alignment.centerLeft,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAccent.withValues(alpha: 0.2),
                AppColors.secondaryAccent.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.trending_up,
            color: AppColors.primaryAccent,
          ),
        ),
        title: Text(
          investment.proyectoNombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrency(investment.monto),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAccent,
                fontSize: 16,
              ),
            ),
          ],
        ),
        children: [
          const Divider(color: AppColors.borderLight),
          _buildInvestmentDetail(
            label: AppStrings.investmentDate,
            value: formattedDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          _buildInvestmentDetail(
            label: AppStrings.projectInvested,
            value: investment.proyectoNombre,
            icon: Icons.business,
          ),
          const SizedBox(height: 8),
          _buildInvestmentDetail(
            label: AppStrings.amount,
            value: Formatters.formatCurrency(investment.monto),
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editInvestment(investment),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(AppStrings.editInvestment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent,
                    side: const BorderSide(color: AppColors.primaryAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelInvestment(investment),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text(AppStrings.cancelInvestment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentDetail({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.tertiaryBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.noInvestments,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.startInvesting,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: AppStrings.viewAll,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icons.explore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: AppStrings.tryAgain,
              onPressed: _loadInvestments,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
