enum LocationType { branch, room, warehouse, rack }

class LocationModel {
  final String id;
  final String companyId;
  final String name;
  final LocationType type;
  final String? parentId;
  final String? address;
  final DateTime? createdAt;

  const LocationModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    this.parentId,
    this.address,
    this.createdAt,
  });

  static String typeToString(LocationType type) {
    switch (type) {
      case LocationType.branch:
        return 'Branch';
      case LocationType.room:
        return 'Room';
      case LocationType.warehouse:
        return 'Warehouse';
      case LocationType.rack:
        return 'Rack';
    }
  }

  static LocationType parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'branch':
        return LocationType.branch;
      case 'room':
        return LocationType.room;
      case 'warehouse':
        return LocationType.warehouse;
      case 'rack':
        return LocationType.rack;
      default:
        return LocationType.branch;
    }
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      type: parseType(json['type'] ?? 'Branch'),
      parentId: json['parent_id'],
      address: json['address'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'type': typeToString(type),
      'parent_id': parentId,
      'address': address,
    };
  }

  LocationModel copyWith({
    String? id,
    String? companyId,
    String? name,
    LocationType? type,
    String? parentId,
    String? address,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Display icon based on location type
  static String typeIcon(LocationType type) {
    switch (type) {
      case LocationType.branch:
        return '🏢';
      case LocationType.room:
        return '🚪';
      case LocationType.warehouse:
        return '🏭';
      case LocationType.rack:
        return '🗄️';
    }
  }
}
