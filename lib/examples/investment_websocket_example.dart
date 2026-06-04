/// Ejemplo de cómo usar la integración WebSocket-Inversiones
///
/// Este archivo muestra ejemplos prácticos de cómo crear, actualizar
/// y eliminar inversiones con broadcast automático a todos los dispositivos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/investment_provider.dart';
import '../../presentation/providers/websocket_provider.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/session.dart';

/// Ejemplo 1: Crear una inversión desde un formulario
///
/// Cuando el usuario envía el formulario, la inversión se crea
/// y automáticamente todos los dispositivos ven la actualización.
class CreateInvestmentExample extends ConsumerStatefulWidget {
  const CreateInvestmentExample({super.key});

  @override
  ConsumerState<CreateInvestmentExample> createState() =>
      _CreateInvestmentExampleState();
}

class _CreateInvestmentExampleState extends ConsumerState<CreateInvestmentExample> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _handleCreateInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Obtener el operations provider
      final ops = ref.read(investmentOperationsProvider);

      // Crear la inversión con broadcast automático
      final investment = await ops.createInvestment(
        usuarioId: 'user123', // Debería venir del user provider
        usuarioNombre: 'Juan Pérez',
        perfil: 'student',
        proyectoId: 'proj456', // Debería venir del project provider
        proyectoNombre: 'Proyecto Alpha',
        temaId: 'tema1',
        temaNombre: 'Tecnología',
        temaColor: '#00D4AA',
        monto: double.parse(_amountController.text),
        observaciones: 'Inversión inicial',
        sessionState: SessionState.active,
      );

      // ✅ En este punto:
      // 1. La inversión se guardó en la base de datos
      // 2. Se envió un broadcast por WebSocket
      // 3. Todos los dispositivos recibieron el evento
      // 4. Los rankings se actualizaron automáticamente
      // 5. Los montos de proyectos se recalculan

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Inversión de \$${investment.monto} creada y sincronizada!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear inversión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Inversión')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto a invertir',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingrese un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleCreateInvestment,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar Inversión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ejemplo 2: Actualizar una inversión existente
///
/// Cuando el usuario modifica el monto u otros campos,
/// todos los dispositivos ven la actualización.
class UpdateInvestmentExample extends ConsumerWidget {
  const UpdateInvestmentExample({super.key, required this.investment});

  final Investment investment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(investmentOperationsProvider);

    return ListTile(
      leading: const Icon(Icons.edit),
      title: Text('Inversión: \$${investment.monto}'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle),
        onPressed: () async {
          try {
            // Actualizar el monto de la inversión
            final updated = await ops.updateInvestment(
              id: investment.id,
              monto: investment.monto + 500, // Incrementar \$500
              observaciones: 'Monto incrementado',
            );

            // ✅ Todos los dispositivos verán el nuevo monto
            // y los rankings se actualizarán automáticamente

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Inversión actualizada: \$${updated.monto}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error actualizando: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

/// Ejemplo 3: Eliminar una inversión
///
/// Cuando el usuario cancela una inversión,
/// todos los dispositivos ven la eliminación.
class DeleteInvestmentExample extends ConsumerWidget {
  const DeleteInvestmentExample({super.key, required this.investment});

  final Investment investment;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Inversión'),
        content: Text(
          '¿Estás seguro de cancelar la inversión de \$${investment.monto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final ops = ref.read(investmentOperationsProvider);

      // Eliminar la inversión con broadcast automático
      await ops.deleteInvestment(investment.id);

      // ✅ Todos los dispositivos verán la inversión eliminada
      // y los rankings se recalcularán automáticamente

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inversión cancelada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelando inversión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text('Cancelar Inversión'),
      subtitle: Text('Inversión: \$${investment.monto}'),
      onTap: () => _handleDelete(context, ref),
    );
  }
}

/// Ejemplo 4: Ranking en tiempo real
///
/// Este widget muestra cómo los rankings se actualizan automáticamente
/// cuando se recibe un evento del WebSocket.
class RealTimeRankingExample extends ConsumerStatefulWidget {
  const RealTimeRankingExample({super.key});

  @override
  ConsumerState<RealTimeRankingExample> createState() =>
      _RealTimeRankingExampleState();
}

class _RealTimeRankingExampleState extends ConsumerState<RealTimeRankingExample> {
  @override
  Widget build(BuildContext context) {
    // Escuchar el provider de WebSocket de inversiones
    // Esto asegura que el widget se reconstruye cuando llega un evento
    final wsNotifier = ref.watch(investmentWebSocketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking en Tiempo Real'),
        actions: [
          // Indicador de conexión
          Icon(
            Icons.cloud_done,
            color: ref.watch(
              webSocketDataSourceProvider.select(
                (ds) => ds.isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Investment>>(
        future: ref.read(projectInvestmentsProvider('proj456')).build('proj456'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay inversiones'));
          }

          // Ordenar por monto descendente
          final sorted = List<Investment>.from(snapshot.data!)
            ..sort((a, b) => b.monto.compareTo(a.monto));

          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final investment = sorted[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('#${index + 1}'),
                ),
                title: Text(investment.usuarioNombre),
                trailing: Text(
                  '\$${investment.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Ejemplo 5: Dashboard con estadísticas en tiempo real
///
/// Muestra cómo las estadísticas se actualizan automáticamente
/// cuando se crean/actualizan/eliminan inversiones.
class DashboardExample extends ConsumerWidget {
  const DashboardExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider('user123'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: investmentsAsync.when(
        data: (investments) {
          final totalInvested = investments.fold<double>(
            0.0,
            (sum, inv) => sum + inv.monto,
          );

          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _StatCard(
                title: 'Total Invertido',
                value: '\$${totalInvested.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Inversiones',
                value: '${investments.length}',
                icon: Icons.format_list_numbered,
                color: Colors.green,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
