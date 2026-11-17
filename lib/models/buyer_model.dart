import 'dart:convert';

/// Represents a customer / buyer who purchases Free Fire IDs.
class Buyer {
  final int? id;
  final String name;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? profileImagePath;
  final String? notes;
  final double totalPaid;
  final String createdAt;

  // Joined/Computed stats
  final int totalIdsPurchased;
  final double totalPurchaseValue;
  final double remainingDue;

  Buyer({
    this.id,
    required this.name,
    this.phone,
    this.whatsapp,
    this.address,
    this.profileImagePath,
    this.notes,
    this.totalPaid = 0.0,
    String? createdAt,
    this.totalIdsPurchased = 0,
    this.totalPurchaseValue = 0.0,
    this.remainingDue = 0.0,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get hasDue => remainingDue > 0.01;

  Buyer copyWith({
    int? id,
    String? name,
    String? phone,
    String? whatsapp,
    String? address,
    String? profileImagePath,
    String? notes,
    double? totalPaid,
    String? createdAt,
    int? totalIdsPurchased,
    double? totalPurchaseValue,
    double? remainingDue,
  }) {
    return Buyer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      notes: notes ?? this.notes,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt ?? this.createdAt,
      totalIdsPurchased: totalIdsPurchased ?? this.totalIdsPurchased,
      totalPurchaseValue: totalPurchaseValue ?? this.totalPurchaseValue,
      remainingDue: remainingDue ?? this.remainingDue,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'profile_image_path': profileImagePath,
      'notes': notes,
      'total_paid': totalPaid,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory Buyer.fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      address: map['address'] as String?,
      profileImagePath: map['profile_image_path'] as String?,
      notes: map['notes'] as String?,
      totalPaid: map['total_paid'] != null
          ? (map['total_paid'] as num).toDouble()
          : 0.0,
      createdAt: map['created_at'] as String,
      totalIdsPurchased: map['total_ids_purchased'] != null
          ? (map['total_ids_purchased'] as num).toInt()
          : 0,
      totalPurchaseValue: map['total_purchase_value'] != null
          ? (map['total_purchase_value'] as num).toDouble()
          : 0.0,
      remainingDue: map['remaining_due'] != null
          ? (map['remaining_due'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['total_ids_purchased'] = totalIdsPurchased;
    map['total_purchase_value'] = totalPurchaseValue;
    map['remaining_due'] = remainingDue;
    return map;
  }

  factory Buyer.fromJson(Map<String, dynamic> json) => Buyer.fromMap(json);

  String toJsonString() => json.encode(toJson());

  factory Buyer.fromJsonString(String source) =>
      Buyer.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Buyer(id: $id, name: $name, phone: $phone, totalPaid: $totalPaid, remainingDue: $remainingDue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Buyer &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.whatsapp == whatsapp &&
        other.address == address &&
        other.profileImagePath == profileImagePath &&
        other.notes == notes &&
        other.totalPaid == totalPaid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        whatsapp.hashCode ^
        address.hashCode ^
        profileImagePath.hashCode ^
        notes.hashCode ^
        totalPaid.hashCode ^
        createdAt.hashCode;
  }
}

typedef BuyerModel = Buyer;

