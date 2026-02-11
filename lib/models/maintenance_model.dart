/// Phase 6: Maintenance Scheduling & Asset Depreciation
library;

enum MaintenanceFrequency { daily, weekly, monthly, quarterly, semiAnnual, annual, oneTime }
enum MaintenancePriority { low, medium, high, critical }
enum MaintenanceLogStatus { completed, partial, failed }

class MaintenanceSchedule {
  final String id;
  final String title;
  final String? description;
  final String? assetId;
  final String? assetName;
  final String? locationId;
  final String? locationName;
  final MaintenanceFrequency frequency;
  final MaintenancePriority priority;
  final String? assignedTo;
  final DateTime? lastPerformedAt;
  final DateTime nextDueDate;
  final int? estimatedDurationMinutes;
  final double? estimatedCost;
  final String currency;
  final bool isActive;
  final String? companyId;
  final String? createdBy;
  final DateTime? createdAt;

  const MaintenanceSchedule({
    required this.id,
    required this.title,
    this.description,
    this.assetId,
    this.assetName,
    this.locationId,
    this.locationName,
    required this.frequency,
    required this.priority,
    this.assignedTo,
    this.lastPerformedAt,
    required this.nextDueDate,
    this.estimatedDurationMinutes,
    this.estimatedCost,
    this.currency = 'SAR',
    this.isActive = true,
    this.companyId,
    this.createdBy,
    this.createdAt,
  });

  // ─── Status helpers ──────────────────────────────────────────
  bool get isOverdue => nextDueDate.isBefore(DateTime.now());

  bool get isDueSoon {
    final diff = nextDueDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  String get statusLabel {
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    return 'On Track';
  }

  // ─── Frequency labels ────────────────────────────────────────
  static String frequencyToString(MaintenanceFrequency f) {
    switch (f) {
      case MaintenanceFrequency.daily: return 'daily';
      case MaintenanceFrequency.weekly: return 'weekly';
      case MaintenanceFrequency.monthly: return 'monthly';
      case MaintenanceFrequency.quarterly: return 'quarterly';
      case MaintenanceFrequency.semiAnnual: return 'semi_annual';
      case MaintenanceFrequency.annual: return 'annual';
      case MaintenanceFrequency.oneTime: return 'one_time';
    }
  }

  static MaintenanceFrequency parseFrequency(String s) {
    switch (s) {
      case 'daily': return MaintenanceFrequency.daily;
      case 'weekly': return MaintenanceFrequency.weekly;
      case 'monthly': return MaintenanceFrequency.monthly;
      case 'quarterly': return MaintenanceFrequency.quarterly;
      case 'semi_annual': return MaintenanceFrequency.semiAnnual;
      case 'annual': return MaintenanceFrequency.annual;
      case 'one_time': return MaintenanceFrequency.oneTime;
      default: return MaintenanceFrequency.monthly;
    }
  }

  static String frequencyDisplayLabel(MaintenanceFrequency f) {
    switch (f) {
      case MaintenanceFrequency.daily: return 'Daily';
      case MaintenanceFrequency.weekly: return 'Weekly';
      case MaintenanceFrequency.monthly: return 'Monthly';
      case MaintenanceFrequency.quarterly: return 'Quarterly';
      case MaintenanceFrequency.semiAnnual: return 'Semi-Annual';
      case MaintenanceFrequency.annual: return 'Annual';
      case MaintenanceFrequency.oneTime: return 'One Time';
    }
  }

  // ─── Priority labels ─────────────────────────────────────────
  static String priorityToString(MaintenancePriority p) {
    switch (p) {
      case MaintenancePriority.low: return 'low';
      case MaintenancePriority.medium: return 'medium';
      case MaintenancePriority.high: return 'high';
      case MaintenancePriority.critical: return 'critical';
    }
  }

  static MaintenancePriority parsePriority(String s) {
    switch (s) {
      case 'low': return MaintenancePriority.low;
      case 'high': return MaintenancePriority.high;
      case 'critical': return MaintenancePriority.critical;
      default: return MaintenancePriority.medium;
    }
  }

  static String priorityDisplayLabel(MaintenancePriority p) {
    switch (p) {
      case MaintenancePriority.low: return 'Low';
      case MaintenancePriority.medium: return 'Medium';
      case MaintenancePriority.high: return 'High';
      case MaintenancePriority.critical: return 'Critical';
    }
  }

  // ─── JSON serialization ──────────────────────────────────────
  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) {
    return MaintenanceSchedule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assetId: json['asset_id'],
      assetName: json['asset_name'],
      locationId: json['location_id'],
      locationName: json['location_name'],
      frequency: parseFrequency(json['frequency'] ?? 'monthly'),
      priority: parsePriority(json['priority'] ?? 'medium'),
      assignedTo: json['assigned_to'],
      lastPerformedAt: json['last_performed_at'] != null
          ? DateTime.tryParse(json['last_performed_at'])
          : null,
      nextDueDate: DateTime.tryParse(json['next_due_date'] ?? '') ?? DateTime.now(),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'SAR',
      isActive: json['is_active'] ?? true,
      companyId: json['company_id'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'asset_id': assetId,
      'asset_name': assetName,
      'location_id': locationId,
      'location_name': locationName,
      'frequency': frequencyToString(frequency),
      'priority': priorityToString(priority),
      'assigned_to': assignedTo,
      'last_performed_at': lastPerformedAt?.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'estimated_duration_minutes': estimatedDurationMinutes,
      'estimated_cost': estimatedCost,
      'currency': currency,
      'is_active': isActive,
      'company_id': companyId,
      'created_by': createdBy,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
// Maintenance Log
// ═══════════════════════════════════════════════════════════════════

class MaintenanceLog {
  final String id;
  final String? scheduleId;
  final String? assetId;
  final String? assetName;
  final String title;
  final String? description;
  final String performedBy;
  final DateTime performedAt;
  final int? durationMinutes;
  final double? cost;
  final String currency;
  final MaintenanceLogStatus status;
  final String? partsReplaced;
  final String? notes;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? companyId;
  final DateTime? createdAt;

  const MaintenanceLog({
    required this.id,
    this.scheduleId,
    this.assetId,
    this.assetName,
    required this.title,
    this.description,
    required this.performedBy,
    required this.performedAt,
    this.durationMinutes,
    this.cost,
    this.currency = 'SAR',
    required this.status,
    this.partsReplaced,
    this.notes,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.companyId,
    this.createdAt,
  });

  static String statusToString(MaintenanceLogStatus s) {
    switch (s) {
      case MaintenanceLogStatus.completed: return 'completed';
      case MaintenanceLogStatus.partial: return 'partial';
      case MaintenanceLogStatus.failed: return 'failed';
    }
  }

  static MaintenanceLogStatus parseStatus(String s) {
    switch (s) {
      case 'partial': return MaintenanceLogStatus.partial;
      case 'failed': return MaintenanceLogStatus.failed;
      default: return MaintenanceLogStatus.completed;
    }
  }

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'] ?? '',
      scheduleId: json['schedule_id'],
      assetId: json['asset_id'],
      assetName: json['asset_name'],
      title: json['title'] ?? '',
      description: json['description'],
      performedBy: json['performed_by'] ?? '',
      performedAt: DateTime.tryParse(json['performed_at'] ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'],
      cost: (json['cost'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'SAR',
      status: parseStatus(json['status'] ?? 'completed'),
      partsReplaced: json['parts_replaced'],
      notes: json['notes'],
      beforePhotoUrl: json['before_photo_url'],
      afterPhotoUrl: json['after_photo_url'],
      companyId: json['company_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'asset_id': assetId,
      'asset_name': assetName,
      'title': title,
      'description': description,
      'performed_by': performedBy,
      'performed_at': performedAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'cost': cost,
      'currency': currency,
      'status': statusToString(status),
      'parts_replaced': partsReplaced,
      'notes': notes,
      'before_photo_url': beforePhotoUrl,
      'after_photo_url': afterPhotoUrl,
      'company_id': companyId,
    };
  }
}
