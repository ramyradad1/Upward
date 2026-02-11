
enum LicenseType { saas, cloud, software, other }
enum BillingCycle { monthly, annual, oneTime }

class LicenseModel {
  final String id;
  final String? companyId;
  final String name;
  final LicenseType type;
  final String? vendor;
  final int totalSeats;
  final int usedSeats;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final double? costPerSeat;
  final String? currency;
  final BillingCycle? billingCycle;
  final String? licenseKey; // Encrypted
  final String? notes;
  final DateTime createdAt;

  LicenseModel({
    required this.id,
    this.companyId,
    required this.name,
    required this.type,
    this.vendor,
    required this.totalSeats,
    required this.usedSeats,
    this.purchaseDate,
    this.expiryDate,
    this.costPerSeat,
    this.currency,
    this.billingCycle,
    this.licenseKey,
    this.notes,
    required this.createdAt,
  });

  // Computed properties
  int get availableSeats => totalSeats - usedSeats;
  double get seatUtilization => totalSeats > 0 ? (usedSeats / totalSeats) * 100 : 0;
  
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  double? get totalCost {
    if (costPerSeat == null) return null;
    return costPerSeat! * totalSeats;
  }

  // Factory constructor from JSON
  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      name: json['name'] as String,
      type: _typeFromString(json['type'] as String),
      vendor: json['vendor'] as String?,
      totalSeats: json['total_seats'] as int,
      usedSeats: json['used_seats'] as int,
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.parse(json['purchase_date'] as String) 
          : null,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date'] as String) 
          : null,
      costPerSeat: json['cost_per_seat'] != null 
          ? (json['cost_per_seat'] as num).toDouble() 
          : null,
      currency: json['currency'] as String?,
      billingCycle: json['billing_cycle'] != null 
          ? _billingCycleFromString(json['billing_cycle'] as String) 
          : null,
      licenseKey: json['license_key'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'type': typeToString(type),
      'vendor': vendor,
      'total_seats': totalSeats,
      'used_seats': usedSeats,
      'purchase_date': purchaseDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'cost_per_seat': costPerSeat,
      'currency': currency,
      'billing_cycle': billingCycle != null ? billingCycleToString(billingCycle!) : null,
      'license_key': licenseKey,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method
  LicenseModel copyWith({
    String? id,
    String? companyId,
    String? name,
    LicenseType? type,
    String? vendor,
    int? totalSeats,
    int? usedSeats,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    double? costPerSeat,
    String? currency,
    BillingCycle? billingCycle,
    String? licenseKey,
    String? notes,
    DateTime? createdAt,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      type: type ?? this.type,
      vendor: vendor ?? this.vendor,
      totalSeats: totalSeats ?? this.totalSeats,
      usedSeats: usedSeats ?? this.usedSeats,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      costPerSeat: costPerSeat ?? this.costPerSeat,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      licenseKey: licenseKey ?? this.licenseKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods for enum conversion
  static LicenseType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'saas':
        return LicenseType.saas;
      case 'cloud':
        return LicenseType.cloud;
      case 'software':
        return LicenseType.software;
      default:
        return LicenseType.other;
    }
  }

  static String typeToString(LicenseType type) {
    switch (type) {
      case LicenseType.saas:
        return 'saas';
      case LicenseType.cloud:
        return 'cloud';
      case LicenseType.software:
        return 'software';
      case LicenseType.other:
        return 'other';
    }
  }

  static BillingCycle _billingCycleFromString(String cycle) {
    switch (cycle.toLowerCase()) {
      case 'monthly':
        return BillingCycle.monthly;
      case 'annual':
        return BillingCycle.annual;
      case 'one_time':
        return BillingCycle.oneTime;
      default:
        return BillingCycle.oneTime;
    }
  }

  static String billingCycleToString(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 'monthly';
      case BillingCycle.annual:
        return 'annual';
      case BillingCycle.oneTime:
        return 'one_time';
    }
  }

  static String typeDisplayName(LicenseType type) {
    switch (type) {
      case LicenseType.saas:
        return 'SaaS';
      case LicenseType.cloud:
        return 'Cloud';
      case LicenseType.software:
        return 'Software';
      case LicenseType.other:
        return 'Other';
    }
  }

  static String billingCycleDisplayName(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.annual:
        return 'Annual';
      case BillingCycle.oneTime:
        return 'One-time';
    }
  }
}
