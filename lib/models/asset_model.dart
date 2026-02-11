enum AssetStatus { inStock, assigned, repair, unknown }

class AssetModel {
  final String id;
  final String name;
  final String category;
  final String serialNumber;
  final String? assignedTo;
  final String? assignedToRole;
  final String? assignedToImage;
  final String imageUrl; // Primary image (first of imageUrls or legacy)
  final List<String> imageUrls;
  final String? custodyImageUrl;
  final String? idCardImageUrl;
  final String? bagType;
  final String? headsetType;
  final String? headsetSerial;
  final String? mouseType;
  final String? mouseSerial;
  final String? companyId;
  final AssetStatus status;

  // Phase 1: Deep Specs & Network
  final String? locationId;
  final String? locationName; // denormalized for display
  final String? cpu;
  final String? ram;
  final String? storageSpec;
  final String? hostname;
  final String? ipAddress;
  final String? macAddress;
  final String? notes; // Asset Wiki

  // Phase 2: Network Intelligence & Security
  final String? configFileUrl;
  final String? configFileName;
  final String? secureCredentials; // Encrypted JSON/String
  
  // Phase 3: Field Operations
  final double? lastSeenLat;
  final double? lastSeenLng;
  final DateTime? lastSeenAt;

  // Phase 5: Handover
  final DateTime? lastHandoverDate;
  final String? custodyDocumentUrl;

  // Phase 6: Depreciation & Maintenance
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final String? currency;
  final String? depreciationMethod;
  final int? usefulLifeYears;
  final double? salvageValue;
  final DateTime? warrantyExpiry;
  final DateTime? nextMaintenanceDate;

  const AssetModel({
    required this.id,
    required this.name,
    required this.category,
    required this.serialNumber,
    this.assignedTo,
    this.assignedToRole,
    this.assignedToImage,
    required this.imageUrl,
    this.imageUrls = const [],
    this.custodyImageUrl,
    this.idCardImageUrl,
    this.bagType,
    this.headsetType,
    this.headsetSerial,
    this.mouseType,
    this.mouseSerial,
    this.companyId,
    required this.status,
    // Phase 1
    this.locationId,
    this.locationName,
    this.cpu,
    this.ram,
    this.storageSpec,
    this.hostname,
    this.ipAddress,
    this.macAddress,
    this.notes,
    // Phase 2
    this.configFileUrl,
    this.configFileName,
    this.secureCredentials,
    // Phase 3
    this.lastSeenLat,
    this.lastSeenLng,
    this.lastSeenAt,
    // Phase 5
    this.lastHandoverDate,
    this.custodyDocumentUrl,
    // Phase 6
    this.purchasePrice,
    this.purchaseDate,
    this.currency,
    this.depreciationMethod,
    this.usefulLifeYears,
    this.salvageValue,
    this.warrantyExpiry,
    this.nextMaintenanceDate,
  });

  /// Computed current value using straight-line depreciation
  double? get currentValue {
    if (purchasePrice == null || usefulLifeYears == null || usefulLifeYears == 0) return purchasePrice;
    final start = purchaseDate ?? DateTime.now();
    final yearsElapsed = DateTime.now().difference(start).inDays / 365.25;
    final annualDep = (purchasePrice! - (salvageValue ?? 0)) / usefulLifeYears!;
    final depTotal = annualDep * yearsElapsed;
    final value = purchasePrice! - depTotal;
    return value < (salvageValue ?? 0) ? (salvageValue ?? 0) : value;
  }

  /// Whether the warranty has expired
  bool get isWarrantyExpired => warrantyExpiry != null && warrantyExpiry!.isBefore(DateTime.now());

  /// Days until warranty expires (negative = expired)
  int? get warrantyDaysRemaining => warrantyExpiry?.difference(DateTime.now()).inDays;

  // Convert status enum to database string
  static String statusToString(AssetStatus status) {
    switch (status) {
      case AssetStatus.inStock:
        return 'in_stock';
      case AssetStatus.assigned:
        return 'assigned';
      case AssetStatus.repair:
        return 'repair';
      default:
        return 'unknown';
    }
  }

  // Parse database string to status enum
  static AssetStatus parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'in_stock':
      case 'in stock':
        return AssetStatus.inStock;
      case 'assigned':
        return AssetStatus.assigned;
      case 'repair':
      case 'in maintenance':
        return AssetStatus.repair;
      default:
        return AssetStatus.unknown;
    }
  }

  // Create from Supabase JSON
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      assignedTo: json['assigned_to'],
      assignedToRole: json['assigned_to_role'],
      assignedToImage: json['assigned_to_image'],
      imageUrl: json['image_url'] ?? '',
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls']) 
          : (json['image_url'] != null ? [json['image_url']] : []),
      custodyImageUrl: json['custody_image_url'],
      idCardImageUrl: json['id_card_image_url'],
      bagType: json['bag_type'],
      headsetType: json['headset_type'],
      headsetSerial: json['headset_serial'],
      mouseType: json['mouse_type'],
      mouseSerial: json['mouse_serial'],
      companyId: json['company_id'],
      status: parseStatus(json['status'] ?? 'unknown'),
      // Phase 1
      locationId: json['location_id'],
      locationName: json['location_name'],
      cpu: json['cpu'],
      ram: json['ram'],
      storageSpec: json['storage_spec'],
      hostname: json['hostname'],
      ipAddress: json['ip_address'],
      macAddress: json['mac_address'],
      notes: json['notes'],
      // Phase 2
      configFileUrl: json['config_file_url'],
      configFileName: json['config_file_name'],
      secureCredentials: json['secure_credentials'],
      // Phase 3
      lastSeenLat: (json['last_seen_lat'] as num?)?.toDouble(),
      lastSeenLng: (json['last_seen_lng'] as num?)?.toDouble(),
      lastSeenAt: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at']) : null,
      // Phase 5
      lastHandoverDate: json['last_handover_date'] != null ? DateTime.tryParse(json['last_handover_date']) : null,
      custodyDocumentUrl: json['custody_document_url'],
      // Phase 6
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      purchaseDate: json['purchase_date'] != null ? DateTime.tryParse(json['purchase_date']) : null,
      currency: json['currency'],
      depreciationMethod: json['depreciation_method'],
      usefulLifeYears: json['useful_life_years'],
      salvageValue: (json['salvage_value'] as num?)?.toDouble(),
      warrantyExpiry: json['warranty_expiry'] != null ? DateTime.tryParse(json['warranty_expiry']) : null,
      nextMaintenanceDate: json['next_maintenance_date'] != null ? DateTime.tryParse(json['next_maintenance_date']) : null,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'serial_number': serialNumber,
      'assigned_to': assignedTo,
      'assigned_to_role': assignedToRole,
      'assigned_to_image': assignedToImage,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'custody_image_url': custodyImageUrl,
      'id_card_image_url': idCardImageUrl,
      'bag_type': bagType,
      'headset_type': headsetType,
      'headset_serial': headsetSerial,
      'mouse_type': mouseType,
      'mouse_serial': mouseSerial,
      'company_id': companyId,
      'status': statusToString(status),
      // Phase 1
      'location_id': locationId,
      'location_name': locationName,
      'cpu': cpu,
      'ram': ram,
      'storage_spec': storageSpec,
      'hostname': hostname,
      'ip_address': ipAddress,
      'mac_address': macAddress,
      'notes': notes,
      // Phase 2
      'config_file_url': configFileUrl,
      'config_file_name': configFileName,
      'secure_credentials': secureCredentials,
      // Phase 3
      'last_seen_lat': lastSeenLat,
      'last_seen_lng': lastSeenLng,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      // Phase 5
      'last_handover_date': lastHandoverDate?.toIso8601String(),
      'custody_document_url': custodyDocumentUrl,
      // Phase 6
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate?.toIso8601String(),
      'currency': currency,
      'depreciation_method': depreciationMethod,
      'useful_life_years': usefulLifeYears,
      'salvage_value': salvageValue,
      'warranty_expiry': warrantyExpiry?.toIso8601String(),
      'next_maintenance_date': nextMaintenanceDate?.toIso8601String(),
    };
  }

  // Copy with method for updates
  AssetModel copyWith({
    String? id,
    String? name,
    String? category,
    String? serialNumber,
    String? assignedTo,
    String? assignedToRole,
    String? assignedToImage,
    String? imageUrl,
    List<String>? imageUrls,
    String? custodyImageUrl,
    String? idCardImageUrl,
    String? bagType,
    String? headsetType,
    String? headsetSerial,
    String? mouseType,
    String? mouseSerial,
    String? companyId,
    AssetStatus? status,
    // Phase 1
    String? locationId,
    String? locationName,
    String? cpu,
    String? ram,
    String? storageSpec,
    String? hostname,
    String? ipAddress,
    String? macAddress,
    String? notes,
    // Phase 2
    String? configFileUrl,
    String? configFileName,
    String? secureCredentials,
    // Phase 3
    double? lastSeenLat,
    double? lastSeenLng,
    DateTime? lastSeenAt,
    // Phase 5
    DateTime? lastHandoverDate,
    String? custodyDocumentUrl,
    // Phase 6
    double? purchasePrice,
    DateTime? purchaseDate,
    String? currency,
    String? depreciationMethod,
    int? usefulLifeYears,
    double? salvageValue,
    DateTime? warrantyExpiry,
    DateTime? nextMaintenanceDate,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToRole: assignedToRole ?? this.assignedToRole,
      assignedToImage: assignedToImage ?? this.assignedToImage,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      custodyImageUrl: custodyImageUrl ?? this.custodyImageUrl,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      bagType: bagType ?? this.bagType,
      headsetType: headsetType ?? this.headsetType,
      headsetSerial: headsetSerial ?? this.headsetSerial,
      mouseType: mouseType ?? this.mouseType,
      mouseSerial: mouseSerial ?? this.mouseSerial,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      // Phase 1
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      cpu: cpu ?? this.cpu,
      ram: ram ?? this.ram,
      storageSpec: storageSpec ?? this.storageSpec,
      hostname: hostname ?? this.hostname,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      notes: notes ?? this.notes,
      // Phase 2
      configFileUrl: configFileUrl ?? this.configFileUrl,
      configFileName: configFileName ?? this.configFileName,
      secureCredentials: secureCredentials ?? this.secureCredentials,
      lastSeenLat: lastSeenLat ?? this.lastSeenLat,
      lastSeenLng: lastSeenLng ?? this.lastSeenLng,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      // Phase 5
      lastHandoverDate: lastHandoverDate ?? this.lastHandoverDate,
      custodyDocumentUrl: custodyDocumentUrl ?? this.custodyDocumentUrl,
      // Phase 6
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      currency: currency ?? this.currency,
      depreciationMethod: depreciationMethod ?? this.depreciationMethod,
      usefulLifeYears: usefulLifeYears ?? this.usefulLifeYears,
      salvageValue: salvageValue ?? this.salvageValue,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
    );
  }
}
