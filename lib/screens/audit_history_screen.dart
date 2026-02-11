import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/audit_session_model.dart';
import '../services/audit_service.dart';
import '../theme/app_theme.dart';


class AuditHistoryScreen extends StatelessWidget {
  const AuditHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/audit/new').then((_) {
            // Refresh logic potentially handled by StreamBuilder automatically
          });
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('New Audit'),
      ),
      body: StreamBuilder<List<AuditSessionModel>>(
        stream: AuditService.getAuditSessionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No audits performed yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildAuditCard(context, session);
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, AuditSessionModel session) {
    final isCompleted = session.status == AuditStatus.completed;
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.surfaceColor(context),
      child: InkWell(
        onTap: () => _showAuditDetails(context, session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                     child: Text(
                      session.locationName ?? 'Unknown Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                                       ),
                   ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCompleted ? Colors.green : Colors.orange),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    session.performedBy ?? 'Unknown User',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(session.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Total', '${session.totalScanned}'),
                  _miniStat('Matched', '${session.matchedCount}', Colors.green),
                  _miniStat('Missing', '${session.missingCount}', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showAuditDetails(BuildContext context, AuditSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Text(
                'Audit Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.locationName ?? 'Unknown Location',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text('Missing Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (session.missingItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No missing items! 🎉', style: TextStyle(color: Colors.green)),
                )
              else
                ...session.missingItems.map((serial) => ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  title: Text('Serial: $serial', style: const TextStyle(fontWeight: FontWeight.bold)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              
              const Divider(height: 24),
              const Text('Scanned Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...session.scannedItems.map((item) => ListTile(
                leading: Text(item.resultEmoji, style: const TextStyle(fontSize: 20)),
                title: Text(item.assetName ?? 'Unknown Asset'),
                subtitle: Text('S/N: ${item.serialNumber}'),
                trailing: Text(DateFormat('h:mm a').format(item.scannedAt)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
