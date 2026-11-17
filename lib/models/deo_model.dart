import 'dart:convert';

/// Represents a DEO (Debt/Credit installment or ledger) account.
class DeoAccount {
  final int? id;
  final String name;
  final int? buyerId;
  final int? relatedFfIdId;
  final double totalAmount;
  final double paidAmount;
  final String? notes;
  final String createdAt;

  // Joined metadata
  final String? buyerName;
  final String? buyerPhone;
  final String? ffUid;
  final List<DeoPayment> payments;

  DeoAccount({
    this.id,
    required this.name,
    this.buyerId,
    this.relatedFfIdId,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.notes,
    String? createdAt,
    this.buyerName,
    this.buyerPhone,
    this.ffUid,
    List<DeoPayment>? payments,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        payments = payments ?? const [];

  double get remainingAmount =>
      (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0.0;

  bool get isFullyPaid => paidAmount >= totalAmount;

  double get progressPercentage =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  DeoAccount copyWith({
    int? id,
    String? name,
    int? buyerId,
    int? relatedFfIdId,
    double? totalAmount,
    double? paidAmount,
    String? notes,
    String? createdAt,
    String? buyerName,
    String? buyerPhone,
    String? ffUid,
    List<DeoPayment>? payments,
  }) {
    return DeoAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      buyerId: buyerId ?? this.buyerId,
      relatedFfIdId: relatedFfIdId ?? this.relatedFfIdId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      ffUid: ffUid ?? this.ffUid,
      payments: payments ?? this.payments,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'buyer_id': buyerId,
      'related_ff_id_id': relatedFfIdId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'notes': notes,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory DeoAccount.fromMap(
    Map<String, dynamic> map, {
    List<DeoPayment>? payments,
  }) {
    return DeoAccount(
      id: map['id'] as int?,
      name: map['name'] as String,
      buyerId: map['buyer_id'] as int?,
      relatedFfIdId: map['related_ff_id_id'] as int?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: map['paid_amount'] != null
          ? (map['paid_amount'] as num).toDouble()
          : 0.0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      buyerName: map['buyer_name'] as String?,
      buyerPhone: map['buyer_phone'] as String?,
      ffUid: map['ff_uid'] as String?,
      payments: payments ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['buyer_name'] = buyerName;
    map['buyer_phone'] = buyerPhone;
    map['ff_uid'] = ffUid;
    map['remaining_amount'] = remainingAmount;
    map['is_fully_paid'] = isFullyPaid;
    map['payments'] = payments.map((p) => p.toMap()).toList();
    return map;
  }

  factory DeoAccount.fromJson(Map<String, dynamic> json) {
    List<DeoPayment>? paymentsList;
    if (json['payments'] != null) {
      paymentsList = (json['payments'] as List)
          .map((p) => DeoPayment.fromMap(p as Map<String, dynamic>))
          .toList();
    }
    return DeoAccount.fromMap(json, payments: paymentsList);
  }

  String toJsonString() => json.encode(toJson());

  factory DeoAccount.fromJsonString(String source) =>
      DeoAccount.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DeoAccount(id: $id, name: $name, totalAmount: $totalAmount, paidAmount: $paidAmount, remaining: $remainingAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeoAccount &&
        other.id == id &&
        other.name == name &&
        other.buyerId == buyerId &&
        other.relatedFfIdId == relatedFfIdId &&
        other.totalAmount == totalAmount &&
        other.paidAmount == paidAmount &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        buyerId.hashCode ^
        relatedFfIdId.hashCode ^
        totalAmount.hashCode ^
        paidAmount.hashCode ^
        notes.hashCode ^
        createdAt.hashCode;
  }
}

/// Represents an installment or payment entry against a DEO account.
class DeoPayment {
  final int? id;
  final int deoAccountId;
  final double amount;
  final String? paymentProofPath;
  final String paymentDate;
  final String? notes;
  final String createdAt;

  // Joined metadata
  final String? accountName;

  DeoPayment({
    this.id,
    required this.deoAccountId,
    required this.amount,
    this.paymentProofPath,
    required this.paymentDate,
    this.notes,
    String? createdAt,
    this.accountName,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  DeoPayment copyWith({
    int? id,
    int? deoAccountId,
    double? amount,
    String? paymentProofPath,
    String? paymentDate,
    String? notes,
    String? createdAt,
    String? accountName,
  }) {
    return DeoPayment(
      id: id ?? this.id,
      deoAccountId: deoAccountId ?? this.deoAccountId,
      amount: amount ?? this.amount,
      paymentProofPath: paymentProofPath ?? this.paymentProofPath,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      accountName: accountName ?? this.accountName,
    );
  }

  /// Converts this instance to a map representation for SQLite database persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'deo_account_id': deoAccountId,
      'amount': amount,
      'payment_proof_path': paymentProofPath,
      'payment_date': paymentDate,
      'notes': notes,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a model instance from an SQLite map.
  factory DeoPayment.fromMap(Map<String, dynamic> map) {
    return DeoPayment(
      id: map['id'] as int?,
      deoAccountId: map['deo_account_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentProofPath: map['payment_proof_path'] as String?,
      paymentDate: map['payment_date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      accountName: map['account_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['account_name'] = accountName;
    return map;
  }

  factory DeoPayment.fromJson(Map<String, dynamic> json) =>
      DeoPayment.fromMap(json);

  String toJsonString() => json.encode(toJson());

  factory DeoPayment.fromJsonString(String source) =>
      DeoPayment.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DeoPayment(id: $id, accountId: $deoAccountId, amount: $amount, date: $paymentDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeoPayment &&
        other.id == id &&
        other.deoAccountId == deoAccountId &&
        other.amount == amount &&
        other.paymentProofPath == paymentProofPath &&
        other.paymentDate == paymentDate &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deoAccountId.hashCode ^
        amount.hashCode ^
        paymentProofPath.hashCode ^
        paymentDate.hashCode ^
        notes.hashCode ^
        createdAt.hashCode;
  }
}

typedef DeoAccountModel = DeoAccount;
typedef DeoPaymentModel = DeoPayment;

