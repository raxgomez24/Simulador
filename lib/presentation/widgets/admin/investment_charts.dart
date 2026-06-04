import 'package:flutter/material.dart';
import 'package:amerike_investment_sim/core/constants/app_colors.dart';
import 'package:amerike_investment_sim/domain/entities/user.dart';
import 'package:amerike_investment_sim/presentation/providers/investments_management_provider.dart';

// Widget de tarjeta de métrica
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de gráfico de barras
class BarChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  final Color barColor;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.title,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final entries = data.entries.toList();

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final percentage = (entry.value / maxValue) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.tertiaryBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget de gráfico de barras para perfiles
class ProfileBarChart extends StatelessWidget {
  final Map<UserRole, int> data;

  const ProfileBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart();
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final entries = data.entries.toList();

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inversiones por Perfil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final percentage = (entry.value / maxValue) * 100;
              final color = _getProfileColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          User.perfilToString(entry.key),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.tertiaryBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getProfileColor(UserRole perfil) {
    switch (perfil) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.student:
        return AppColors.primaryAccent;
      case UserRole.teacher:
        return AppColors.warning;
      case UserRole.employee:
        return AppColors.info;
      case UserRole.investor:
        return AppColors.success;
      case UserRole.guest:
        return AppColors.textSecondary;
    }
  }
}

// Widget de gráfico de líneas temporal
class TimelineChart extends StatelessWidget {
  final Map<DateTime, int> data;

  const TimelineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart();
    }

    final sortedDates = data.keys.toList()..sort();
    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.values.reduce((a, b) => a < b ? a : b).toDouble();

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución de Inversiones',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _TimelinePainter(
                  data: data,
                  sortedDates: sortedDates,
                  maxValue: maxValue,
                  minValue: minValue,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sortedDates.isNotEmpty)
                  Text(
                    _formatDate(sortedDates.first),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                if (sortedDates.length > 1)
                  Text(
                    _formatDate(sortedDates.last),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}

class _TimelinePainter extends CustomPainter {
  final Map<DateTime, int> data;
  final List<DateTime> sortedDates;
  final double maxValue;
  final double minValue;

  _TimelinePainter({
    required this.data,
    required this.sortedDates,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sortedDates.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primaryAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = AppColors.primaryAccent
      ..style = PaintingStyle.fill;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final range = maxValue - minValue;
    final yRatio = range > 0 ? chartHeight / range : 0;
    final xStep = chartWidth / (sortedDates.length - 1);

    final points = <Offset>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final value = data[date]!.toDouble();
      final x = padding + (i * xStep);
      final y = size.height - padding - ((value - minValue) * yRatio);
      points.add(Offset(x, y));
    }

    // Draw filled area
    final path = Path()
      ..moveTo(points.first.dx, size.height - padding)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.lineTo(points.last.dx, size.height - padding);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 4, Paint()
        ..color = AppColors.cardBackground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para lista de top usuarios
class TopUsersList extends StatelessWidget {
  final List<UserInvestmentStats> users;

  const TopUsersList({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyChart();
    }

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Usuarios con Más Inversiones',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...users.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
                            user.usuarioNombre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${user.investmentCount} inversiones',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(user.totalAmount),
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return AppColors.primaryAccent;
    }
  }
}

// Widget para lista de top proyectos
class TopProjectsList extends StatelessWidget {
  final List<ProjectInvestmentStats> projects;

  const TopProjectsList({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const _EmptyChart();
    }

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Proyectos con Más Inversión',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...projects.asMap().entries.map((entry) {
              final index = entry.key;
              final project = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
                            project.proyectoNombre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(
                                      project.temaColor.replaceFirst('#', '0xFF'),
                                    ),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                project.temaNombre,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(project.totalAmount),
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return AppColors.primaryAccent;
    }
  }
}

String _formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}
