import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AnalyticsStatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const AnalyticsStatTile({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPieChart extends StatelessWidget {
  final Map<String, int> statusData;

  const StatusPieChart({super.key, required this.statusData});

  @override
  Widget build(BuildContext context) {
    final total = statusData.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final colors = {
      'available': const Color(0xFF4CAF50),
      'in_use': const Color(0xFF2196F3),
      'maintenance': const Color(0xFFFF9800),
      'retired': const Color(0xFF9E9E9E),
    };

    final labels = {
      'available': 'Available',
      'in_use': 'In Use',
      'maintenance': 'Maintenance',
      'retired': 'Retired',
    };

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: statusData.entries
                  .where((e) => e.value > 0)
                  .map((entry) {
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${entry.value}',
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  color: colors[entry.key] ?? Colors.grey,
                  radius: 45,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: statusData.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${labels[entry.key] ?? entry.key} (${entry.value})',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CategoryBarChart extends StatelessWidget {
  final Map<String, int> categoryData;

  const CategoryBarChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final entries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue =
        entries.isEmpty ? 1.0 : entries.first.value.toDouble();

    return SizedBox(
      height: (entries.length * 48.0).clamp(100, 400),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${entries[group.x.toInt()].key}\n',
                  TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} assets',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox();
                  }
                  final label = entries[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 8
                          ? '${label.substring(0, 8)}...'
                          : label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble()) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.borderColor(context),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                  color: AppTheme.primaryColor,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class RequestStatsCard extends StatelessWidget {
  final Map<String, int> requestStats;

  const RequestStatsCard({super.key, required this.requestStats});

  @override
  Widget build(BuildContext context) {
    final pending = requestStats['pending'] ?? 0;
    final approved = requestStats['approved'] ?? 0;
    final rejected = requestStats['rejected'] ?? 0;
    final total = pending + approved + rejected;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnalyticsStatTile(
                label: 'Pending',
                count: pending,
                color: const Color(0xFFFF9800),
                icon: Icons.hourglass_empty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsStatTile(
                label: 'Approved',
                count: approved,
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsStatTile(
                label: 'Rejected',
                count: rejected,
                color: const Color(0xFFF44336),
                icon: Icons.cancel,
              ),
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (approved > 0)
                    Expanded(
                      flex: approved,
                      child: Container(color: const Color(0xFF4CAF50)),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(color: const Color(0xFFFF9800)),
                    ),
                  if (rejected > 0)
                    Expanded(
                      flex: rejected,
                      child: Container(color: const Color(0xFFF44336)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MaintenanceStatsCard extends StatelessWidget {
  final Map<String, dynamic> maintenanceStats;

  const MaintenanceStatsCard({super.key, required this.maintenanceStats});

  @override
  Widget build(BuildContext context) {
    final overdue = maintenanceStats['overdue'] ?? 0;
    final dueSoon = maintenanceStats['due_soon'] ?? 0;
    final onTrack = maintenanceStats['on_track'] ?? 0;
    final totalCost = (maintenanceStats['total_cost'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnalyticsStatTile(
                label: 'Overdue',
                count: overdue,
                color: const Color(0xFFEF4444),
                icon: Icons.warning_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsStatTile(
                label: 'Due Soon',
                count: dueSoon,
                color: const Color(0xFFF59E0B),
                icon: Icons.access_time_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsStatTile(
                label: 'On Track',
                count: onTrack,
                color: const Color(0xFF10B981),
                icon: Icons.task_alt_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.inputFill(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.inputBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.attach_money_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Maintenance Cost',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCost.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
