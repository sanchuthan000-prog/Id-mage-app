import 'dart:convert';

/// Represents monthly data points for sales and profit charts.
class MonthlyStat {
  final String month; // e.g. "2026-11" or "Nov"
  final double sales;
  final double profit;
  final int count;

  MonthlyStat({
    required this.month,
    required this.sales,
    required this.profit,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'sales': sales,
      'profit': profit,
      'count': count,
    };
  }

  factory MonthlyStat.fromMap(Map<String, dynamic> map) {
    return MonthlyStat(
      month: map['month'] as String? ?? '',
      sales: (map['sales'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Aggregated statistical data for the app's dashboard and reports.
class DashboardStats {
  final int totalIds;
  final int availableIds;
  final int soldIds;
  final double totalInvestment;
  final double totalSales;
  final double totalProfit;
  final double totalSellerPayments;
  final double totalBuyerPayments;
  final double totalOutstandingBalance; // Receivables: unpaid balance from sales
  final double totalPayableToSellers; // Payables: cost of IDs supplied - paid to sellers
  final double deoTotal;
  final double deoPaid;
  final double deoRemaining;
  final List<MonthlyStat> monthlyStats;

  const DashboardStats({
    this.totalIds = 0,
    this.availableIds = 0,
    this.soldIds = 0,
    this.totalInvestment = 0.0,
    this.totalSales = 0.0,
    this.totalProfit = 0.0,
    this.totalSellerPayments = 0.0,
    this.totalBuyerPayments = 0.0,
    this.totalOutstandingBalance = 0.0,
    this.totalPayableToSellers = 0.0,
    this.deoTotal = 0.0,
    this.deoPaid = 0.0,
    this.deoRemaining = 0.0,
    this.monthlyStats = const [],
  });

  /// Overall profit margin percentage
  double get profitMargin =>
      totalSales > 0 ? ((totalProfit / totalSales) * 100) : 0.0;

  /// Net cash flow: buyer payments received minus seller payments made
  double get netCashFlow => totalBuyerPayments - totalSellerPayments;

  factory DashboardStats.empty() => const DashboardStats();

  DashboardStats copyWith({
    int? totalIds,
    int? availableIds,
    int? soldIds,
    double? totalInvestment,
    double? totalSales,
    double? totalProfit,
    double? totalSellerPayments,
    double? totalBuyerPayments,
    double? totalOutstandingBalance,
    double? totalPayableToSellers,
    double? deoTotal,
    double? deoPaid,
    double? deoRemaining,
    List<MonthlyStat>? monthlyStats,
  }) {
    return DashboardStats(
      totalIds: totalIds ?? this.totalIds,
      availableIds: availableIds ?? this.availableIds,
      soldIds: soldIds ?? this.soldIds,
      totalInvestment: totalInvestment ?? this.totalInvestment,
      totalSales: totalSales ?? this.totalSales,
      totalProfit: totalProfit ?? this.totalProfit,
      totalSellerPayments: totalSellerPayments ?? this.totalSellerPayments,
      totalBuyerPayments: totalBuyerPayments ?? this.totalBuyerPayments,
      totalOutstandingBalance:
          totalOutstandingBalance ?? this.totalOutstandingBalance,
      totalPayableToSellers:
          totalPayableToSellers ?? this.totalPayableToSellers,
      deoTotal: deoTotal ?? this.deoTotal,
      deoPaid: deoPaid ?? this.deoPaid,
      deoRemaining: deoRemaining ?? this.deoRemaining,
      monthlyStats: monthlyStats ?? this.monthlyStats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_ids': totalIds,
      'available_ids': availableIds,
      'sold_ids': soldIds,
      'total_investment': totalInvestment,
      'total_sales': totalSales,
      'total_profit': totalProfit,
      'total_seller_payments': totalSellerPayments,
      'total_buyer_payments': totalBuyerPayments,
      'total_outstanding_balance': totalOutstandingBalance,
      'total_payable_to_sellers': totalPayableToSellers,
      'deo_total': deoTotal,
      'deo_paid': deoPaid,
      'deo_remaining': deoRemaining,
      'monthly_stats': monthlyStats.map((e) => e.toMap()).toList(),
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalIds: (map['total_ids'] as num?)?.toInt() ?? 0,
      availableIds: (map['available_ids'] as num?)?.toInt() ?? 0,
      soldIds: (map['sold_ids'] as num?)?.toInt() ?? 0,
      totalInvestment: (map['total_investment'] as num?)?.toDouble() ?? 0.0,
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['total_profit'] as num?)?.toDouble() ?? 0.0,
      totalSellerPayments:
          (map['total_seller_payments'] as num?)?.toDouble() ?? 0.0,
      totalBuyerPayments:
          (map['total_buyer_payments'] as num?)?.toDouble() ?? 0.0,
      totalOutstandingBalance:
          (map['total_outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      totalPayableToSellers:
          (map['total_payable_to_sellers'] as num?)?.toDouble() ?? 0.0,
      deoTotal: (map['deo_total'] as num?)?.toDouble() ?? 0.0,
      deoPaid: (map['deo_paid'] as num?)?.toDouble() ?? 0.0,
      deoRemaining: (map['deo_remaining'] as num?)?.toDouble() ?? 0.0,
      monthlyStats: (map['monthly_stats'] as List?)
              ?.map((item) => MonthlyStat.fromMap(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardStats.fromJson(String source) =>
      DashboardStats.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DashboardStats(totalIds: $totalIds, availableIds: $availableIds, soldIds: $soldIds, investment: $totalInvestment, sales: $totalSales, profit: $totalProfit, buyerBalance: $totalOutstandingBalance, payableSellers: $totalPayableToSellers, deoRemaining: $deoRemaining)';
  }
}

typedef DashboardStatsModel = DashboardStats;

