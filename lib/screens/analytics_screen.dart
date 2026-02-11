import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/maintenance_service.dart';
import '../widgets/analytics_widgets.dart';

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
                      StatusPieChart(statusData: _statusData),
                    ),
                    const SizedBox(height: 20),

                    // Category Bar Chart
                    _buildChartCard(
                      'Assets by Category',
                      CategoryBarChart(categoryData: _categoryData),
                    ),
                    const SizedBox(height: 20),

                    // Request Stats
                    _buildChartCard(
                      'Request Statistics',
                      RequestStatsCard(requestStats: _requestStats),
                    ),
                    const SizedBox(height: 20),

                    // Maintenance Stats
                    _buildChartCard(
                      'Maintenance Overview',
                      MaintenanceStatsCard(maintenanceStats: _maintenanceStats),
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

}


