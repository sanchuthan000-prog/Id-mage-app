import 'dart:convert';

/// Represents financial transactions (payments, advances, refunds, adjustments)
/// for sellers and buyers.
class TransactionModel {
  final int? id;
  final String type; // 'seller_payment', 'buyer_payment', 'seller_advance', 'buyer_advance', 'refund', 'adjustment'
  final String personType; // 'seller', 'buyer'
  final int personId;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String? paymentProofPath;
  final String transactionDate;
  final String createdAt;

  // Joined metadata
  final String? personName;
  final String? personPhone;

  TransactionModel({
    this.id,
    required this.type,
    required this.personType,
    required this.personId,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.paymentProofPath,
    required this.transactionDate,
    String? createdAt,
    this.personName,
    this.personPhone,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isSellerTransaction => personType.toLowerCase() == 'seller';
  bool get isBuyerTransaction => personType.toLowerCase() == 'buyer';
  bool get isAdvance => type.toLowerCase().contains('advance');
  bool get isPayment => type.toLowerCase().contains('payment');
  bool get isRefund => type.toLowerCase().contains('refund');
  bool get isAdjustment => type.toLowerCase().contains('adjustment');

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'seller_payment':
        return 'Seller Payment';
      case 'buyer_payment':
        return 'Buyer Payment';
      case 'seller_advance':
        return 'Seller Advance';
      case 'buyer_advance':
        return 'Buyer Advance';
      case 'refund':
        return 'Refund';
      case 'adjustment':
        return 'Balance Adjustment';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    String? personType,
    int? personId,
    double? amount,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    String? paymentProofPath,
    String? transactionDate,
    String? createdAt,
    String? personName,
    String? personPhone,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      personType: personType ?? this.personType,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      paymentProofPath: paymentProofPath ?? this.paymentProofPath,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'person_type': personType,
      'person_id': personId,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'payment_proof_path': paymentProofPath,
      'transaction_date': transactionDate,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      personType: map['person_type'] as String,
      personId: map['person_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      paymentProofPath: map['payment_proof_path'] as String?,
      transactionDate: map['transaction_date'] as String,
      createdAt: map['created_at'] as String,
      personName: map['person_name'] as String?,
      personPhone: map['person_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['person_name'] = personName;
    map['person_phone'] = personPhone;
    return map;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromMap(json);

  String toJsonString() => json.encode(toJson());

  factory TransactionModel.fromJsonString(String source) =>
      TransactionModel.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, personType: $personType, personId: $personId, amount: $amount, method: $paymentMethod, date: $transactionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.type == type &&
        other.personType == personType &&
        other.personId == personId &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.referenceNumber == referenceNumber &&
        other.notes == notes &&
        other.paymentProofPath == paymentProofPath &&
        other.transactionDate == transactionDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        personType.hashCode ^
        personId.hashCode ^
        amount.hashCode ^
        paymentMethod.hashCode ^
        referenceNumber.hashCode ^
        notes.hashCode ^
        paymentProofPath.hashCode ^
        transactionDate.hashCode ^
        createdAt.hashCode;
  }
}

typedef Transaction = TransactionModel;

