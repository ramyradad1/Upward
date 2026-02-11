enum RequestType { assetTransfer, newDevice, repair, returnAsset }

enum RequestStatus { pending, approved, rejected }

class RequestModel {
  final String id;
  final String requesterId;
  final String? requesterName;
  final String? approverId;
  final String? approverName;
  final RequestType type;
  final RequestStatus status;
  final String? assetId;
  final String? assetName;
  final String? fromLocationId;
  final String? toLocationId;
  final String? notes;
  final String? rejectReason;
  final String? companyId;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const RequestModel({
    required this.id,
    required this.requesterId,
    this.requesterName,
    this.approverId,
    this.approverName,
    required this.type,
    required this.status,
    this.assetId,
    this.assetName,
    this.fromLocationId,
    this.toLocationId,
    this.notes,
    this.rejectReason,
    this.companyId,
    this.createdAt,
    this.resolvedAt,
  });

  // --- Type conversion helpers ---

  static String typeToString(RequestType type) {
    switch (type) {
      case RequestType.assetTransfer:
        return 'asset_transfer';
      case RequestType.newDevice:
        return 'new_device';
      case RequestType.repair:
        return 'repair';
      case RequestType.returnAsset:
        return 'return_asset';
    }
  }

  static RequestType parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'asset_transfer':
        return RequestType.assetTransfer;
      case 'new_device':
        return RequestType.newDevice;
      case 'repair':
        return RequestType.repair;
      case 'return_asset':
        return RequestType.returnAsset;
      default:
        return RequestType.newDevice;
    }
  }

  static String statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.approved:
        return 'approved';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }

  static RequestStatus parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }

  static String typeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.assetTransfer:
        return 'Asset Transfer';
      case RequestType.newDevice:
        return 'New Device';
      case RequestType.repair:
        return 'Repair';
      case RequestType.returnAsset:
        return 'Return Asset';
    }
  }

  // --- JSON serialization ---

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] ?? '',
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'],
      approverId: json['approver_id'],
      approverName: json['approver_name'],
      type: parseType(json['type'] ?? 'new_device'),
      status: parseStatus(json['status'] ?? 'pending'),
      assetId: json['asset_id'],
      assetName: json['asset_name'],
      fromLocationId: json['from_location_id'],
      toLocationId: json['to_location_id'],
      notes: json['notes'],
      rejectReason: json['reject_reason'],
      companyId: json['company_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requester_id': requesterId,
      'requester_name': requesterName,
      'approver_id': approverId,
      'approver_name': approverName,
      'type': typeToString(type),
      'status': statusToString(status),
      'asset_id': assetId,
      'asset_name': assetName,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'notes': notes,
      'reject_reason': rejectReason,
      'company_id': companyId,
    };
  }

  RequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? approverId,
    String? approverName,
    RequestType? type,
    RequestStatus? status,
    String? assetId,
    String? assetName,
    String? fromLocationId,
    String? toLocationId,
    String? notes,
    String? rejectReason,
    String? companyId,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      type: type ?? this.type,
      status: status ?? this.status,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      notes: notes ?? this.notes,
      rejectReason: rejectReason ?? this.rejectReason,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
