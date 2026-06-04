import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/project.dart';

class InvestmentBarChart extends StatefulWidget {
  final List<Project> projects;
  final int maxBars;
  final String? title;

  const InvestmentBarChart({
    super.key,
    required this.projects,
    this.maxBars = 10,
    this.title,
  });

  @override
  State<InvestmentBarChart> createState() => _InvestmentBarChartState();
}

class _InvestmentBarChartState extends State<InvestmentBarChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort projects by invested amount (descending) and take top N
    final sortedProjects = List<Project>.from(widget.projects);
    sortedProjects.sort((a, b) => b.totalInvertido.compareTo(a.totalInvertido));
    final displayProjects = sortedProjects.take(widget.maxBars).toList();

    final maxInvested = displayProjects.isNotEmpty
        ? displayProjects.first.totalInvertido
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title ?? 'Ranking de Proyectos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (displayProjects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top ${displayProjects.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxInvested * 1.1, // Add 10% headroom
                minY: 0,
                groupsSpace: 12,
                barGroups: _buildBarGroups(displayProjects, maxInvested),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (event.isInterestedForInteractions &&
                          barTouchResponse != null &&
                          barTouchResponse.spot != null) {
                        touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      } else {
                        touchedIndex = -1;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayProjects.length) {
                          return _buildBottomTitle(
                            displayProjects[index],
                            index,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          Formatters.formatCompactNumber(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxInvested / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.borderLight.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend with theme colors
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: displayProjects.take(5).map((project) {
              final color = _parseColor(project.temaColor ?? '#00D4AA');
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      project.temaNombre,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<Project> projects,
    double maxInvested,
  ) {
    return projects.asMap().entries.map((entry) {
      final index = entry.key;
      final project = entry.value;
      final color = _parseColor(project.temaColor ?? '#00D4AA');
      final isTouched = touchedIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: project.totalInvertido,
            color: isTouched
                ? color.withOpacity(0.8)
                : color,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBottomTitle(Project project, int index) {
    final color = _parseColor(project.temaColor ?? '#00D4AA');
    final isTouched = touchedIndex == index;

    return Transform.rotate(
      angle: -0.26, // Rotate text slightly for better fit
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank badge
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getRankColor(index + 1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Theme icon
            Text(
              _getThemeIcon(project.temaNombre),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            // Project name (truncated)
            Text(
              project.nombre.length > 8
                  ? '${project.nombre.substring(0, 8)}...'
                  : project.nombre,
              style: TextStyle(
                fontSize: isTouched ? 10 : 9,
                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                color: isTouched ? color : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }

  String _getThemeIcon(String themeName) {
    final themeLower = themeName.toLowerCase();
    if (themeLower.contains('tecnolog') || themeLower.contains('tech')) {
      return '💻';
    } else if (themeLower.contains('salud') || themeLower.contains('health')) {
      return '🏥';
    } else if (themeLower.contains('educaci') || themeLower.contains('edu')) {
      return '📚';
    } else if (themeLower.contains('energ') || themeLower.contains('energy')) {
      return '⚡';
    } else if (themeLower.contains('finanza') || themeLower.contains('finance')) {
      return '💰';
    } else if (themeLower.contains('retail') || themeLower.contains('comerc')) {
      return '🛒';
    } else if (themeLower.contains('inmob') || themeLower.contains('real')) {
      return '🏠';
    } else if (themeLower.contains('transport') || themeLower.contains('log')) {
      return '🚚';
    }
    return '📊';
  }
}
