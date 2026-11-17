import 'dart:convert';

/// Represents an image associated with a Free Fire ID listing.
class IdImage {
  final int? id;
  final int ffIdId;
  final String imagePath;
  final String createdAt;

  IdImage({
    this.id,
    required this.ffIdId,
    required this.imagePath,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  IdImage copyWith({
    int? id,
    int? ffIdId,
    String? imagePath,
    String? createdAt,
  }) {
    return IdImage(
      id: id ?? this.id,
      ffIdId: ffIdId ?? this.ffIdId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ff_id_id': ffIdId,
      'image_path': imagePath,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory IdImage.fromMap(Map<String, dynamic> map) {
    return IdImage(
      id: map['id'] as int?,
      ffIdId: map['ff_id_id'] as int,
      imagePath: map['image_path'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory IdImage.fromJson(String source) =>
      IdImage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'IdImage(id: $id, ffIdId: $ffIdId, imagePath: $imagePath, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdImage &&
        other.id == id &&
        other.ffIdId == ffIdId &&
        other.imagePath == imagePath &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ffIdId.hashCode ^
        imagePath.hashCode ^
        createdAt.hashCode;
  }
}

/// Represents a Free Fire account listing / inventory item.
class FfId {
  final int? id;
  final String uid;
  final String? loginEmail;
  final String? loginPasswordEncrypted;
  final double purchaseCost;
  final double? sellingPrice;
  final int? sellerId;
  final String status; // 'available' or 'sold'
  final String purchaseDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // Joined/populated metadata
  final String? sellerName;
  final List<String> images;

  FfId({
    this.id,
    required this.uid,
    this.loginEmail,
    this.loginPasswordEncrypted,
    required this.purchaseCost,
    this.sellingPrice,
    this.sellerId,
    this.status = 'available',
    required this.purchaseDate,
    this.notes,
    String? createdAt,
    String? updatedAt,
    this.sellerName,
    List<String>? images,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        images = images ?? const [];

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isSold => status.toLowerCase() == 'sold';

  double get profit =>
      (sellingPrice != null) ? (sellingPrice! - purchaseCost) : 0.0;

  double get profitMargin =>
      (sellingPrice != null && sellingPrice! > 0)
          ? ((sellingPrice! - purchaseCost) / sellingPrice!) * 100
          : 0.0;

  FfId copyWith({
    int? id,
    String? uid,
    String? loginEmail,
    String? loginPasswordEncrypted,
    double? purchaseCost,
    double? sellingPrice,
    int? sellerId,
    String? status,
    String? purchaseDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? sellerName,
    List<String>? images,
  }) {
    return FfId(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      loginEmail: loginEmail ?? this.loginEmail,
      loginPasswordEncrypted:
          loginPasswordEncrypted ?? this.loginPasswordEncrypted,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerName: sellerName ?? this.sellerName,
      images: images ?? this.images,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'login_email': loginEmail,
      'login_password_encrypted': loginPasswordEncrypted,
      'purchase_cost': purchaseCost,
      'selling_price': sellingPrice,
      'seller_id': sellerId,
      'status': status,
      'purchase_date': purchaseDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory FfId.fromMap(
    Map<String, dynamic> map, {
    List<String>? images,
    String? sellerName,
  }) {
    return FfId(
      id: map['id'] as int?,
      uid: map['uid'] as String,
      loginEmail: map['login_email'] as String?,
      loginPasswordEncrypted: map['login_password_encrypted'] as String?,
      purchaseCost: (map['purchase_cost'] as num).toDouble(),
      sellingPrice: map['selling_price'] != null
          ? (map['selling_price'] as num).toDouble()
          : null,
      sellerId: map['seller_id'] as int?,
      status: (map['status'] as String?) ?? 'available',
      purchaseDate: map['purchase_date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sellerName: sellerName ?? map['seller_name'] as String?,
      images: images ??
          (map['images'] is List
              ? (map['images'] as List).cast<String>()
              : (map['image_paths'] is String && (map['image_paths'] as String).isNotEmpty
                  ? (map['image_paths'] as String).split('||')
                  : null)),
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['seller_name'] = sellerName;
    map['images'] = images;
    return map;
  }

  factory FfId.fromJson(Map<String, dynamic> json) {
    return FfId.fromMap(
      json,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      sellerName: json['seller_name'] as String?,
    );
  }

  @override
  String toString() {
    return 'FfId(id: $id, uid: $uid, status: $status, purchaseCost: $purchaseCost, sellingPrice: $sellingPrice, sellerId: $sellerId, sellerName: $sellerName, imagesCount: ${images.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FfId &&
        other.id == id &&
        other.uid == uid &&
        other.loginEmail == loginEmail &&
        other.loginPasswordEncrypted == loginPasswordEncrypted &&
        other.purchaseCost == purchaseCost &&
        other.sellingPrice == sellingPrice &&
        other.sellerId == sellerId &&
        other.status == status &&
        other.purchaseDate == purchaseDate &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        loginEmail.hashCode ^
        loginPasswordEncrypted.hashCode ^
        purchaseCost.hashCode ^
        sellingPrice.hashCode ^
        sellerId.hashCode ^
        status.hashCode ^
        purchaseDate.hashCode ^
        notes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

typedef FfIdModel = FfId;

