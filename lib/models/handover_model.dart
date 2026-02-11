

/// Model for asset handover records
class HandoverModel {
  final String id;
  final String assetId;
  final String? assetName;
  final String? fromUserId;
  final String? fromUserName;
  final String toUserId;
  final String toUserName;
  final String? issuerSignatureUrl;
  final String? recipientSignatureUrl;
  final String? notes;
  final String? pdfUrl;
  final String? companyId;
  final DateTime createdAt;

  HandoverModel({
    required this.id,
    required this.assetId,
    this.assetName,
    this.fromUserId,
    this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    this.issuerSignatureUrl,
    this.recipientSignatureUrl,
    this.notes,
    this.pdfUrl,
    this.companyId,
    required this.createdAt,
  });

  factory HandoverModel.fromJson(Map<String, dynamic> json) {
    return HandoverModel(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      assetName: json['asset_name'] as String?,
      fromUserId: json['from_user_id'] as String?,
      fromUserName: json['from_user_name'] as String?,
      toUserId: json['to_user_id'] as String,
      toUserName: json['to_user_name'] as String,
      issuerSignatureUrl: json['issuer_signature_url'] as String?,
      recipientSignatureUrl: json['recipient_signature_url'] as String?,
      notes: json['notes'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      companyId: json['company_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'asset_name': assetName,
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'to_user_id': toUserId,
      'to_user_name': toUserName,
      'issuer_signature_url': issuerSignatureUrl,
      'recipient_signature_url': recipientSignatureUrl,
      'notes': notes,
      'pdf_url': pdfUrl,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HandoverModel copyWith({
    String? id,
    String? assetId,
    String? assetName,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? toUserName,
    String? issuerSignatureUrl,
    String? recipientSignatureUrl,
    String? notes,
    String? pdfUrl,
    String? companyId,
    DateTime? createdAt,
  }) {
    return HandoverModel(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      issuerSignatureUrl: issuerSignatureUrl ?? this.issuerSignatureUrl,
      recipientSignatureUrl:
          recipientSignatureUrl ?? this.recipientSignatureUrl,
      notes: notes ?? this.notes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HandoverModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
