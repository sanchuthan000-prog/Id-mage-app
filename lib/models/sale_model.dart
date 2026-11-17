import 'dart:convert';

/// Represents a sale record of a Free Fire ID to a buyer.
class Sale {
  final int? id;
  final int ffIdId;
  final int buyerId;
  final double sellingPrice;
  final double profit;
  final String paymentMethod;
  final double amountReceived;
  final double remainingBalance;
  final String saleDate;
  final String? notes;
  final String createdAt;

  // Joined metadata
  final String? ffUid;
  final String? buyerName;
  final String? buyerPhone;
  final double? purchaseCost;

  Sale({
    this.id,
    required this.ffIdId,
    required this.buyerId,
    required this.sellingPrice,
    required this.profit,
    required this.paymentMethod,
    required this.amountReceived,
    required this.remainingBalance,
    required this.saleDate,
    this.notes,
    String? createdAt,
    this.ffUid,
    this.buyerName,
    this.buyerPhone,
    this.purchaseCost,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isFullyPaid => remainingBalance <= 0.01;

  Sale copyWith({
    int? id,
    int? ffIdId,
    int? buyerId,
    double? sellingPrice,
    double? profit,
    String? paymentMethod,
    double? amountReceived,
    double? remainingBalance,
    String? saleDate,
    String? notes,
    String? createdAt,
    String? ffUid,
    String? buyerName,
    String? buyerPhone,
    double? purchaseCost,
  }) {
    return Sale(
      id: id ?? this.id,
      ffIdId: ffIdId ?? this.ffIdId,
      buyerId: buyerId ?? this.buyerId,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      profit: profit ?? this.profit,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      ffUid: ffUid ?? this.ffUid,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      purchaseCost: purchaseCost ?? this.purchaseCost,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ff_id_id': ffIdId,
      'buyer_id': buyerId,
      'selling_price': sellingPrice,
      'profit': profit,
      'payment_method': paymentMethod,
      'amount_received': amountReceived,
      'remaining_balance': remainingBalance,
      'sale_date': saleDate,
      'notes': notes,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      ffIdId: map['ff_id_id'] as int,
      buyerId: map['buyer_id'] as int,
      sellingPrice: (map['selling_price'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      amountReceived: (map['amount_received'] as num).toDouble(),
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      saleDate: map['sale_date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      ffUid: map['ff_uid'] as String?,
      buyerName: map['buyer_name'] as String?,
      buyerPhone: map['buyer_phone'] as String?,
      purchaseCost: map['purchase_cost'] != null
          ? (map['purchase_cost'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['ff_uid'] = ffUid;
    map['buyer_name'] = buyerName;
    map['buyer_phone'] = buyerPhone;
    map['purchase_cost'] = purchaseCost;
    return map;
  }

  factory Sale.fromJson(Map<String, dynamic> json) => Sale.fromMap(json);

  String toJsonString() => json.encode(toJson());

  factory Sale.fromJsonString(String source) =>
      Sale.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Sale(id: $id, ffIdId: $ffIdId, buyerId: $buyerId, sellingPrice: $sellingPrice, profit: $profit, amountReceived: $amountReceived, remainingBalance: $remainingBalance, saleDate: $saleDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale &&
        other.id == id &&
        other.ffIdId == ffIdId &&
        other.buyerId == buyerId &&
        other.sellingPrice == sellingPrice &&
        other.profit == profit &&
        other.paymentMethod == paymentMethod &&
        other.amountReceived == amountReceived &&
        other.remainingBalance == remainingBalance &&
        other.saleDate == saleDate &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ffIdId.hashCode ^
        buyerId.hashCode ^
        sellingPrice.hashCode ^
        profit.hashCode ^
        paymentMethod.hashCode ^
        amountReceived.hashCode ^
        remainingBalance.hashCode ^
        saleDate.hashCode ^
        notes.hashCode ^
        createdAt.hashCode;
  }
}

typedef SaleModel = Sale;

