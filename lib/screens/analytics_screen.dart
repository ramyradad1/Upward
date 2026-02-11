import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/maintenance_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, int> _statusData = {};
  Map<String, int> _categoryData = {};
  Map<String, int> _requestStats = {};
  Map<String, dynamic> _maintenanceStats = {};
  int _totalAssets = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      AnalyticsService.getAssetsByStatus(),
      AnalyticsService.getAssetsByCategory(),
      AnalyticsService.getRequestStats(),
      AnalyticsService.getTotalAssets(),
      MaintenanceService.getMaintenanceStats(),
    ]);

    if (mounted) {
      setState(() {
        _statusData = results[0] as Map<String, int>;
        _categoryData = results[1] as Map<String, int>;
        _requestStats = results[2] as Map<String, int>;
        _totalAssets = results[3] as int;
        _maintenanceStats = results[4] as Map<String, dynamic>;
        _isLoading = false;
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Summary Cards
                    _buildSummaryRow(),
                    const SizedBox(height: 24),

                    // Asset Status Pie Chart
                    _buildChartCard(
                      'Asset Status Distribution',
                      _buildStatusPieChart(),
                    ),
                    const SizedBox(height: 20),

                    // Category Bar Chart
                    _buildChartCard(
                      'Assets by Category',
                      _buildCategoryBarChart(),
                    ),
                    const SizedBox(height: 20),

                    // Request Stats
                    _buildChartCard(
                      'Request Statistics',
                      _buildRequestStats(),
                    ),
                    const SizedBox(height: 20),

                    // Maintenance Stats
                    _buildChartCard(
                      'Maintenance Overview',
                      _buildMaintenanceStats(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final inUse = _statusData['in_use'] ?? 0;
    final available = _statusData['available'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Assets',
            _totalAssets.toString(),
            Icons.inventory_2_rounded,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'In Use',
            inUse.toString(),
            Icons.check_circle_outline,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Available',
            available.toString(),
            Icons.devices,
            const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  Widget _buildStatusPieChart() {
    final total = _statusData.values.fold(0, (a, b) => a + b);
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
              sections: _statusData.entries
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
          children: _statusData.entries.map((entry) {
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

  Widget _buildCategoryBarChart() {
    if (_categoryData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final entries = _categoryData.entries.toList()
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

  Widget _buildRequestStats() {
    final pending = _requestStats['pending'] ?? 0;
    final approved = _requestStats['approved'] ?? 0;
    final rejected = _requestStats['rejected'] ?? 0;
    final total = pending + approved + rejected;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Pending',
                pending,
                const Color(0xFFFF9800),
                Icons.hourglass_empty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Approved',
                approved,
                const Color(0xFF4CAF50),
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Rejected',
                rejected,
                const Color(0xFFF44336),
                Icons.cancel,
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

  Widget _buildMaintenanceStats() {
    final overdue = _maintenanceStats['overdue'] ?? 0;
    final dueSoon = _maintenanceStats['due_soon'] ?? 0;
    final onTrack = _maintenanceStats['on_track'] ?? 0;
    final totalCost = (_maintenanceStats['total_cost'] as num?)?.toDouble() ?? 0.0;
    
    // We can also show total schedules if we want, but let's focus on status
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Overdue',
                overdue,
                const Color(0xFFEF4444),
                Icons.warning_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Due Soon',
                dueSoon,
                const Color(0xFFF59E0B),
                Icons.access_time_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'On Track',
                onTrack,
                const Color(0xFF10B981),
                Icons.task_alt_rounded,
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
                    totalCost.toStringAsFixed(2), // Assuming base currency
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

  Widget _buildStatTile(String label, int count, Color color, IconData icon) {
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
