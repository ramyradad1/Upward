import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_app_logo.dart';


class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  _buildTabBar(isDark),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _UpcomingTab(),
                        _AllSchedulesTab(),
                        _HistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/maintenance/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return FadeTransition(
      opacity: _animController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary(context)),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  Text(
                    'Schedules & History',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient(),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.build_circle_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'All Schedules'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Upcoming Tab
// ═══════════════════════════════════════════════════════════════════
class _UpcomingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaintenanceSchedule>>(
      stream: MaintenanceService.getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        // Filter: overdue + due within 14 days, active only
        final upcoming = all.where((s) => s.isActive && (s.isOverdue || s.isDueSoon ||
            s.nextDueDate.difference(DateTime.now()).inDays <= 14)).toList();

        if (upcoming.isEmpty) {
            return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'All Clear!',
            subtitle: 'No upcoming maintenance tasks',
            showLogo: true,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcoming.length,
          itemBuilder: (context, index) =>
              _ScheduleCard(schedule: upcoming[index]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// All Schedules Tab
// ═══════════════════════════════════════════════════════════════════
class _AllSchedulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaintenanceSchedule>>(
      stream: MaintenanceService.getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final schedules = snapshot.data ?? [];

        if (schedules.isEmpty) {
          return _buildEmptyState(
            icon: Icons.calendar_month_rounded,
            title: 'No Schedules Yet',
            subtitle: 'Tap + to create your first maintenance schedule',
            showLogo: true,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) =>
              _ScheduleCard(schedule: schedules[index]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// History Tab
// ═══════════════════════════════════════════════════════════════════
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MaintenanceLog>>(
      stream: MaintenanceService.getLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history_rounded,
            title: 'No History',
            subtitle: 'Maintenance logs will appear here',
            showLogo: true,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) => _LogCard(log: logs[index]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Schedule Card
// ═══════════════════════════════════════════════════════════════════
class _ScheduleCard extends StatelessWidget {
  final MaintenanceSchedule schedule;
  const _ScheduleCard({required this.schedule});

  Color _statusColor() {
    if (schedule.isOverdue) return const Color(0xFFEF4444);
    if (schedule.isDueSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  IconData _priorityIcon() {
    switch (schedule.priority) {
      case MaintenancePriority.critical: return Icons.error_rounded;
      case MaintenancePriority.high: return Icons.warning_amber_rounded;
      case MaintenancePriority.medium: return Icons.info_outline_rounded;
      case MaintenancePriority.low: return Icons.low_priority_rounded;
    }
  }

  Color _priorityColor() {
    switch (schedule.priority) {
      case MaintenancePriority.critical: return const Color(0xFFEF4444);
      case MaintenancePriority.high: return const Color(0xFFF59E0B);
      case MaintenancePriority.medium: return AppTheme.primaryColor;
      case MaintenancePriority.low: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusCol = _statusColor();
    final daysUntil = schedule.nextDueDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showScheduleDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              // Status bar

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: statusCol,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          schedule.statusLabel,
                          style: TextStyle(
                            color: statusCol,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(_priorityIcon(), size: 18, color: _priorityColor()),
                  const SizedBox(width: 4),
                  Text(
                    MaintenanceSchedule.priorityDisplayLabel(schedule.priority),
                    style: TextStyle(
                      color: _priorityColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmDelete(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                schedule.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (schedule.description != null && schedule.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  schedule.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Info chips row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (schedule.assetName != null)
                    _buildChip(Icons.devices_rounded, schedule.assetName!, context),
                  _buildChip(Icons.repeat_rounded,
                      MaintenanceSchedule.frequencyDisplayLabel(schedule.frequency), context),
                  _buildChip(
                    Icons.schedule_rounded,
                    schedule.isOverdue
                        ? '${-daysUntil}d overdue'
                        : daysUntil == 0
                            ? 'Due today'
                            : 'In $daysUntil days',
                    context,
                  ),
                  if (schedule.assignedTo != null)
                    _buildChip(Icons.person_outline_rounded, schedule.assignedTo!, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleDetailSheet(schedule: schedule),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete "${schedule.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await MaintenanceService.deleteSchedule(schedule.id);
              if (ctx.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Log Card
// ═══════════════════════════════════════════════════════════════════
class _LogCard extends StatelessWidget {
  final MaintenanceLog log;
  const _LogCard({required this.log});

  Color _logStatusColor() {
    switch (log.status) {
      case MaintenanceLogStatus.completed: return const Color(0xFF10B981);
      case MaintenanceLogStatus.partial: return const Color(0xFFF59E0B);
      case MaintenanceLogStatus.failed: return const Color(0xFFEF4444);
    }
  }

  IconData _logStatusIcon() {
    switch (log.status) {
      case MaintenanceLogStatus.completed: return Icons.check_circle_rounded;
      case MaintenanceLogStatus.partial: return Icons.timelapse_rounded;
      case MaintenanceLogStatus.failed: return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusCol = _logStatusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusCol.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_logStatusIcon(), color: statusCol, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${log.performedBy} • ${_formatDate(log.performedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  if (log.assetName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.assetName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (log.cost != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${log.cost!.toStringAsFixed(0)} ${log.currency}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Schedule Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════
class _ScheduleDetailSheet extends StatelessWidget {
  final MaintenanceSchedule schedule;
  const _ScheduleDetailSheet({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                schedule.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (schedule.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  schedule.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _detailRow(Icons.repeat_rounded, 'Frequency',
                  MaintenanceSchedule.frequencyDisplayLabel(schedule.frequency), context),
              _detailRow(Icons.flag_rounded, 'Priority',
                  MaintenanceSchedule.priorityDisplayLabel(schedule.priority), context),
              _detailRow(Icons.calendar_today_rounded, 'Next Due',
                  _formatDate(schedule.nextDueDate), context),
              if (schedule.lastPerformedAt != null)
                _detailRow(Icons.history_rounded, 'Last Performed',
                    _formatDate(schedule.lastPerformedAt!), context),
              if (schedule.assetName != null)
                _detailRow(Icons.devices_rounded, 'Asset', schedule.assetName!, context),
              if (schedule.locationName != null)
                _detailRow(Icons.location_on_rounded, 'Location', schedule.locationName!, context),
              if (schedule.assignedTo != null)
                _detailRow(Icons.person_rounded, 'Assigned To', schedule.assignedTo!, context),
              if (schedule.estimatedCost != null)
                _detailRow(Icons.attach_money_rounded, 'Est. Cost',
                    '${schedule.estimatedCost!.toStringAsFixed(0)} ${schedule.currency}', context),
              if (schedule.estimatedDurationMinutes != null)
                _detailRow(Icons.timer_rounded, 'Est. Duration',
                    '${schedule.estimatedDurationMinutes} min', context),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        _confirmDelete(context);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/maintenance/add', extra: schedule);
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Log Maintenance',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textHint(context))),
              Text(value, style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete "${schedule.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await MaintenanceService.deleteSchedule(schedule.id);
              if (ctx.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════
Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  bool showLogo = false,
}) {
  return Builder(
    builder: (context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLogo)
             const AnimatedAppLogo(size: 100)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.textHint(context)),
            ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(
            fontSize: 14, color: AppTheme.textSecondary(context),
          )),
        ],
      ),
    ),
  );
}
