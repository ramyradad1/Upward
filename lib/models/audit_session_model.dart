import 'dart:convert';

enum AuditStatus { inProgress, completed }

enum ScanResult { matched, misplaced, unknown }

class ScannedItem {
  final String serialNumber;
  final String? assetName;
  final ScanResult result;
  final DateTime scannedAt;
  final double? latitude;
  final double? longitude;

  const ScannedItem({
    required this.serialNumber,
    this.assetName,
    required this.result,
    required this.scannedAt,
    this.latitude,
    this.longitude,
  });

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      serialNumber: json['serial_number'] ?? '',
      assetName: json['asset_name'],
      result: _parseResult(json['result'] ?? 'unknown'),
      scannedAt: DateTime.tryParse(json['scanned_at'] ?? '') ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'serial_number': serialNumber,
    'asset_name': assetName,
    'result': result.name,
    'scanned_at': scannedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  static ScanResult _parseResult(String s) {
    switch (s) {
      case 'matched': return ScanResult.matched;
      case 'misplaced': return ScanResult.misplaced;
      default: return ScanResult.unknown;
    }
  }

  String get resultEmoji {
    switch (result) {
      case ScanResult.matched: return '✅';
      case ScanResult.misplaced: return '⚠️';
      case ScanResult.unknown: return '❌';
    }
  }

  String get resultLabel {
    switch (result) {
      case ScanResult.matched: return 'Matched';
      case ScanResult.misplaced: return 'Misplaced';
      case ScanResult.unknown: return 'Unknown';
    }
  }
}

class AuditSessionModel {
  final String id;
  final String? locationId;
  final String? locationName;
  final String? performedBy;
  final List<ScannedItem> scannedItems;
  final List<String> missingItems; // Serial numbers of assets at location not scanned
  final String? reportPdfUrl;
  final AuditStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const AuditSessionModel({
    required this.id,
    this.locationId,
    this.locationName,
    this.performedBy,
    this.scannedItems = const [],
    this.missingItems = const [],
    this.reportPdfUrl,
    this.status = AuditStatus.inProgress,
    required this.createdAt,
    this.completedAt,
  });

  // Computed properties
  int get totalScanned => scannedItems.length;
  int get matchedCount => scannedItems.where((i) => i.result == ScanResult.matched).length;
  int get misplacedCount => scannedItems.where((i) => i.result == ScanResult.misplaced).length;
  int get unknownCount => scannedItems.where((i) => i.result == ScanResult.unknown).length;
  int get missingCount => missingItems.length;

  bool get isCompleted => status == AuditStatus.completed;

  double get matchRate => totalScanned > 0 ? (matchedCount / totalScanned) * 100 : 0;

  factory AuditSessionModel.fromJson(Map<String, dynamic> json) {
    List<ScannedItem> scanned = [];
    if (json['scanned_items'] != null) {
      final items = json['scanned_items'] is String
          ? jsonDecode(json['scanned_items']) as List
          : json['scanned_items'] as List;
      scanned = items.map((e) => ScannedItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<String> missing = [];
    if (json['missing_items'] != null) {
      final items = json['missing_items'] is String
          ? jsonDecode(json['missing_items']) as List
          : json['missing_items'] as List;
      missing = items.cast<String>();
    }

    return AuditSessionModel(
      id: json['id'] ?? '',
      locationId: json['location_id'],
      locationName: json['location_name'],
      performedBy: json['performed_by'],
      scannedItems: scanned,
      missingItems: missing,
      reportPdfUrl: json['report_pdf'],
      status: (json['status'] ?? '') == 'completed' ? AuditStatus.completed : AuditStatus.inProgress,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'location_id': locationId,
    'location_name': locationName,
    'performed_by': performedBy,
    'scanned_items': scannedItems.map((e) => e.toJson()).toList(),
    'missing_items': missingItems,
    'report_pdf': reportPdfUrl,
    'status': status == AuditStatus.completed ? 'completed' : 'in_progress',
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  AuditSessionModel copyWith({
    String? id,
    String? locationId,
    String? locationName,
    String? performedBy,
    List<ScannedItem>? scannedItems,
    List<String>? missingItems,
    String? reportPdfUrl,
    AuditStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AuditSessionModel(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      performedBy: performedBy ?? this.performedBy,
      scannedItems: scannedItems ?? this.scannedItems,
      missingItems: missingItems ?? this.missingItems,
      reportPdfUrl: reportPdfUrl ?? this.reportPdfUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
